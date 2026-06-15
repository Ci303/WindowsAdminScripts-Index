param(
    [string]$Workspace = "C:\Users\noswi\Desktop\Scripts",
    [string]$IndexRepo = "WindowsAdminScripts-Index",
    [string]$HubFileName = "README_PROJECTS.md",
    [switch]$PullIndex,
    [switch]$Commit,
    [switch]$Push
)

$ErrorActionPreference = "Stop"

function Assert-Path {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Label not found: $Path"
    }
}

function Assert-RequiredTool {
    param(
        [string]$Name
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required tool '$Name' was not found in PATH. Install it and retry."
    }
}

function Show-Remediation {
    param(
        [string]$RepoName,
        [string]$RepoPath
    )

    return "Recreate `$RepoName` under `$RepoPath` (`git clone https://github.com/Ci303/$RepoName`)."
}

function Escape-MarkdownTableCell {
    param([string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return ($Value -replace '\|', '\\|')
}

function Get-RepoMetadata {
    param(
        [string]$RepoPath,
        [string]$RepoName
    )

    $gitPath = Join-Path $RepoPath ".git"
    if (-not (Test-Path -LiteralPath $gitPath)) {
        throw "Not a git repository: $RepoPath"
    }

    $url = (git -C $RepoPath config --get remote.origin.url) 2>$null
    if ([string]::IsNullOrWhiteSpace($url)) {
        $url = "https://github.com/Ci303/$RepoName"
    }

    $commit = (git -C $RepoPath rev-parse --short HEAD)
    $date = (git -C $RepoPath log -1 --date=short --pretty=format:"%cd")
    $message = (git -C $RepoPath log -1 --pretty=format:"%s")

    [PSCustomObject]@{
        Name    = $RepoName
        Url     = $url
        Commit  = $commit
        Date    = $date
        Message = $message
    }
}

function Validate-RequiredRepositories {
    param(
        [string]$Workspace,
        [string[]]$Names
    )

    $errors = @()
    $details = @()

    foreach ($name in $Names) {
        $repoPath = Join-Path $Workspace $name
        if (-not (Test-Path -LiteralPath $repoPath -PathType Container)) {
            $errors += "Repository folder missing: $repoPath"
            $details += Show-Remediation -RepoName $name -RepoPath $Workspace
            continue
        }

        if (-not (Test-Path -LiteralPath (Join-Path $repoPath '.git') -PathType Container)) {
            $errors += "Not a git repo (missing .git): $repoPath"
            $details += "Re-run setup for '$name' as a git clone, or initialise git in: $repoPath"
        }
    }

    if ($errors.Count -eq 0) {
        return
    }

    $message = @()
    $message += "Preflight failed for repository input list:"
    foreach ($item in $errors) {
        $message += " - $item"
    }
    $message += ""
    $message += "Remediation:"
    foreach ($item in $details) {
        $message += " - $item"
    }

    throw ($message -join "`n")
}

function Update-And-Guard-IndexRepo {
    param(
        [string]$RepoPath,
        [string]$RepoName
    )

    Set-Location $RepoPath

    $status = git status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        throw "$RepoName has uncommitted changes. Commit, stash or discard local changes before refreshing the index."
    }

    git fetch origin

    $upstream = (git rev-parse --abbrev-ref --symbolic-full-name "@{u}") 2>$null
    if ([string]::IsNullOrWhiteSpace($upstream)) {
        Write-Warning "$RepoName has no configured upstream. Skipping stale-check."
        return
    }

    $local = (git rev-parse HEAD)
    $remote = (git rev-parse "$upstream")

    if ($local -ne $remote) {
        if ($PullIndex.IsPresent) {
            Write-Host "Index repository is behind upstream. Pulling updates for $RepoName..."
            git pull --ff-only
        }
        else {
            throw "$RepoName is behind upstream. Rerun with -PullIndex (or run git pull) before refreshing."
        }
    }
}

try {
    Assert-RequiredTool -Name git
    Assert-Path -Path $Workspace -Label "Workspace"
    Validate-RequiredRepositories -Workspace $Workspace -Names @(
        "Find-UnresolvedTrayIcons",
        "Invoke-TrayIconCleanup",
        "Invoke-WindowsCleanup",
        $IndexRepo
    )

    $repoList = @(
        "Find-UnresolvedTrayIcons",
        "Invoke-TrayIconCleanup",
        "Invoke-WindowsCleanup"
    )

    $entries = foreach ($repo in $repoList) {
        $repoPath = Join-Path $Workspace $repo
        Assert-Path -Path $repoPath -Label "Repository folder"
        Get-RepoMetadata -RepoPath $repoPath -RepoName $repo
    }

    $indexRepoPath = Join-Path $Workspace $IndexRepo
    Assert-Path -Path $indexRepoPath -Label "Index repository folder"
    Update-And-Guard-IndexRepo -RepoPath $indexRepoPath -RepoName $IndexRepo

    $indexPath = Join-Path $indexRepoPath $HubFileName

    $lines = @(
        "# Windows Admin Scripts Index",
        "",
        "Central index for related utility repositories.",
        "",
        "| Repository | URL | Commit | Date | Commit message |",
        "|---|---|---:|---|---|"
    )

    foreach ($entry in $entries) {
        $escapedMessage = Escape-MarkdownTableCell -Value $entry.Message
        $lines += "| [$($entry.Name)]($($entry.Url)) | $($entry.Url) | ``$($entry.Commit)`` | $($entry.Date) | $escapedMessage |"
    }

    $lines += ""
    $lines += "## Maintenance"
    $lines += ""
    $lines += "```powershell"
    foreach ($entry in $entries) {
        $lines += "git -C `"$Workspace\$($entry.Name)`" log -1 --oneline"
    }
    $lines += "```"
    $lines += ""
    $lines += "Last updated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss K'))"

    Set-Content -Path $indexPath -Value ($lines -join "`r`n") -Encoding UTF8
    Write-Host "Updated: $indexPath"

    if ($Commit.IsPresent) {
        Set-Location $indexRepoPath
        git add $HubFileName

        $status = git status --porcelain
        if ([string]::IsNullOrWhiteSpace($status)) {
            Write-Host "No changes to commit."
        }
        else {
            $message = "Refresh repository index"
            git commit -m $message
            Write-Host "Committed index update."

            if ($Push.IsPresent) {
                git push
                Write-Host "Pushed index update."
            }
        }
    }
}
catch {
    Write-Error $_
    exit 1
}
