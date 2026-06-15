# Windows Admin Scripts Index

Central index for related utility repositories.

| Repository | URL | Commit | Date | Commit message |
|---|---|---:|---|---|
| [Find-UnresolvedTrayIcons](https://github.com/Ci303/Find-UnresolvedTrayIcons) | https://github.com/Ci303/Find-UnresolvedTrayIcons | ``ab7ec1b`` | 2026-06-15 | Add repository policy for PR-based contribution flow |
| [Invoke-TrayIconCleanup](https://github.com/Ci303/Invoke-TrayIconCleanup) | https://github.com/Ci303/Invoke-TrayIconCleanup | ``349e57d`` | 2026-06-15 | Add repository policy for PR-based contribution flow |
| [Invoke-WindowsCleanup](https://github.com/Ci303/Invoke-WindowsCleanup) | https://github.com/Ci303/Invoke-WindowsCleanup | ``8e19748`` | 2026-06-15 | Add repository policy for PR-based contribution flow |

## Maintenance helper

```powershell
git -C "C:\Users\noswi\Desktop\Scripts\Find-UnresolvedTrayIcons" log -1 --oneline
git -C "C:\Users\noswi\Desktop\Scripts\Invoke-TrayIconCleanup" log -1 --oneline
git -C "C:\Users\noswi\Desktop\Scripts\Invoke-WindowsCleanup" log -1 --oneline
```

### Regenerate index

```powershell
Set-Location "C:\Users\noswi\Desktop\Scripts\WindowsAdminScripts-Index"
.\refresh-index.ps1
.\refresh-index.ps1 -Commit
.\refresh-index.ps1 -Commit -Push
```

## Quick start

```powershell
Set-Location "C:\Users\noswi\Desktop\Scripts\Find-UnresolvedTrayIcons"
.\Find-UnresolvedTrayIcons.ps1

Set-Location "C:\Users\noswi\Desktop\Scripts\Invoke-TrayIconCleanup"
.\Invoke-TrayIconCleanup.ps1

Set-Location "C:\Users\noswi\Desktop\Scripts\Invoke-WindowsCleanup"
.\Invoke-WindowsCleanup.ps1 -SkipCleanMgr
```

Last updated: 2026-06-16 00:07:17 +01:00
