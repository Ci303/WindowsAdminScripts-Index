param(
    [string]$Workspace = 'C:\Users\noswi\Desktop\Scripts',
    [string]$IndexRepo = 'WindowsAdminScripts-Index',
    [string]$HubFileName = 'README_PROJECTS.md',
    [switch]$PullIndex,
    [switch]$Commit,
    [switch]$Push
)

$ErrorActionPreference = 'Stop'

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
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required tool '$Name' was not found in PATH."
    }
}

function Show-Remediation {
    param(
        [string]$RepoName,
        [string]$Workspace
    )
    return "Recreate '$RepoName' under '$Workspace' or update -Workspace to the correct location."
}

function Get-RepoMetadata {
    param(
        [string]$RepoPath,
        [string]$RepoName
    )

    if (-not (Test-Path -LiteralPath (Join-Path $RepoPath '.git') -PathType Container)) {
        throw "Not a git repository: $RepoPath"
    }

    $url = git -C $RepoPath config --get remote.origin.url 2>$null
    if ([string]::IsNullOrWhiteSpace($url)) {
        $url = "https://github.com/Ci303/$RepoName"
    }

    [PSCustomObject]@{
        Name    = $RepoName
        Url     = $url
        Commit  = (git -C $RepoPath rev-parse --short HEAD)
        Date    = (git -C $RepoPath log -1 --date=short --pretty=format:'%cd')
        Message = (git -C $RepoPath log -1 --pretty=format:'%s')
    }
}

function Validate-RequiredRepositories {
    param(
        [string]$Workspace,
        [string[]]$Names
    )

    $errors = @()
    $remedy = @()

    foreach ($name in $Names) {
        $repoPath = Join-Path $Workspace $name
        if (-not (Test-Path -LiteralPath $repoPath -PathType Container)) {
            $errors += "Missing repository folder: $repoPath"
            $remedy += Show-Remediation -RepoName $name -Workspace $Workspace
            continue
        }
        if (-not (Test-Path -LiteralPath (Join-Path $repoPath '.git') -PathType Container)) {
            $errors += "Missing .git in: $repoPath"
            $remedy += "Re-run setup or clone '$name' as a git repository into '$repoPath'."
        }
    }

    if ($errors.Count -gt 0) {
        $msg = @()
        $msg += 'Preflight failed for repository list:'
        foreach ($e in $errors) { $msg += (' - ' + $e) }
        $msg += ''
        $msg += 'Remediation:'
        foreach ($r in $remedy) { $msg += (' - ' + $r) }
        throw ($msg -join [Environment]::NewLine)
    }
}

function Update-And-Guard-IndexRepo {
    param(
        [string]$RepoPath,
        [string]$RepoName
    )

    Set-Location $RepoPath

    if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
        throw "$RepoName has uncommitted changes. Commit, stash, or discard them before refreshing."
    }

    git fetch origin
    $upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null

    if ([string]::IsNullOrWhiteSpace($upstream)) {
        Write-Warning "$RepoName has no upstream configured. Skipping stale check."
        return
    }

    $local = git rev-parse HEAD
    $remote = git rev-parse $upstream

    if ($local -ne $remote) {
        if ($PullIndex.IsPresent) {
            Write-Host "$RepoName is behind upstream. Pulling updates..."
            git pull --ff-only
        }
        else {
            throw "$RepoName is behind upstream. Rerun with -PullIndex or run git pull first."
        }
    }
}

function Escape-MarkdownCell {
    param([string]$Value)
    return ($Value -replace '\|', '\\|')
}

try {
    Assert-RequiredTool -Name git
    Assert-Path -Path $Workspace -Label 'Workspace'

    Validate-RequiredRepositories -Workspace $Workspace -Names @(
        'Find-UnresolvedTrayIcons',
        'Invoke-TrayIconCleanup',
        'Invoke-WindowsCleanup',
        $IndexRepo
    )

    $repoList = @(
        'Find-UnresolvedTrayIcons',
        'Invoke-TrayIconCleanup',
        'Invoke-WindowsCleanup'
    )

    $entries = foreach ($repo in $repoList) {
        Get-RepoMetadata -RepoPath (Join-Path $Workspace $repo) -RepoName $repo
    }

    $indexRepoPath = Join-Path $Workspace $IndexRepo
    Assert-Path -Path $indexRepoPath -Label 'Index repository folder'
    Update-And-Guard-IndexRepo -RepoPath $indexRepoPath -RepoName $IndexRepo

    $indexPath = Join-Path $indexRepoPath $HubFileName

    $lines = @()
    $lines += '# Windows Admin Scripts Index'
    $lines += ''
    $lines += 'Central index for related utility repositories.'
    $lines += ''
    $lines += '| Repository | URL | Commit | Date | Commit message |'
    $lines += '|---|---|---:|---|---|'

    foreach ($entry in $entries) {
        $msg = Escape-MarkdownCell -Value $entry.Message
        $lines += ('| [{0}]({1}) | {1} | ``{2}`` | {3} | {4} |' -f $entry.Name, $entry.Url, $entry.Commit, $entry.Date, $msg)
    }

    $lines += ''
    $lines += '## Maintenance'
    $lines += ''
    $lines += '```powershell'
    foreach ($entry in $entries) {
        $lines += ('git -C "{0}\{1}" log -1 --oneline' -f $Workspace, $entry.Name)
    }
    $lines += '```'

    $lines += ''
    $lines += ('Last updated: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))

    Set-Content -Path $indexPath -Value $lines -Encoding UTF8
    Write-Host "Updated: $indexPath"

    if ($Commit.IsPresent) {
        Set-Location $indexRepoPath
        git add $HubFileName

        if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
            git commit -m 'Refresh repository index'
            Write-Host 'Committed index update.'
            if ($Push.IsPresent) { git push; Write-Host 'Pushed index update.' }
        }
        else {
            Write-Host 'No changes to commit.'
        }
    }
}
catch {
    Write-Error $_
    exit 1
}
