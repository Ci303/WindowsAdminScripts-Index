# Windows Admin Scripts Index

Central index for related utility repositories.

| Repository | URL | Commit | Date | Commit message |
|---|---|---:|---|---|
| [Find-UnresolvedTrayIcons](https://github.com/Ci303/Find-UnresolvedTrayIcons) | https://github.com/Ci303/Find-UnresolvedTrayIcons | `ab7ec1b` | 2026-06-15 | Add repository policy for PR-based contribution flow |
| [Invoke-TrayIconCleanup](https://github.com/Ci303/Invoke-TrayIconCleanup) | https://github.com/Ci303/Invoke-TrayIconCleanup | `349e57d` | 2026-06-15 | Add repository policy for PR-based contribution flow |
| [Invoke-WindowsCleanup](https://github.com/Ci303/Invoke-WindowsCleanup) | https://github.com/Ci303/Invoke-WindowsCleanup | `8e19748` | 2026-06-15 | Add repository policy for PR-based contribution flow |

## Maintenance

```powershell
git -C "C:/Users/noswi/Desktop/Scripts/Find-UnresolvedTrayIcons" log -1 --oneline
git -C "C:/Users/noswi/Desktop/Scripts/Invoke-TrayIconCleanup" log -1 --oneline
git -C "C:/Users/noswi/Desktop/Scripts/Invoke-WindowsCleanup" log -1 --oneline
```

## Automated refresh (recommended)

Run this from a scheduled task or CI runner after updating the three repos:

```powershell
param([string]$Workspace = "C:\Users\noswi\Desktop\Scripts")
$ErrorActionPreference = "Stop"
gh auth setup-git
Set-Location $Workspace\WindowsAdminScripts-Index
git pull

# Rebuild README_PROJECTS.md content here and refresh commit metadata
Set-Location $Workspace\WindowsAdminScripts-Index
git add README_PROJECTS.md
git commit -m "Refresh repository index"
git push
```

### CI token guidance

In CI, pass a least-privilege token in `GITHUB_TOKEN` (or an equivalent repository-scoped PAT if needed) and do not print token values to logs.

Last updated: 2026-06-16 00:01:28 +01:00
