# PowerTools Suite

Unified WPF launcher for Windows utility scripts. One-click install via PowerShell.

## Quick Start (GitHub)

```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/install.ps1" | iex
```

Then type `PS-PowerToolsSuite` in any PowerShell window.

## Requirements

- **PowerShell 7.0+** (downloads from https://aka.ms/powershell if needed)
- **Windows 10+** (for WPF)
- **Admin elevation** for some modules (Hardware Inventory, Gaming Optimizer)

## What's Included

| Module | Category | Admin |
|--------|----------|-------|
| Hash Verifier | Security | No |
| Explorer View Normalizer | Windows Tweaks | No |
| Hardware Inventory | Diagnostics | Yes |
| Sandboxie Browser Launcher | Security | No |
| Windows 11 Gaming Optimizer | Performance | Yes |
| Linux ISO Downloader | Downloads | No |

## Manual Installation

If `irm | iex` doesn't work:

1. Download `install.ps1` from this repo
2. Run in PowerShell: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Run: `.\install.ps1`
4. Follow prompts

Default install location: `%LOCALAPPDATA%\PowerTools-Suite`

## Uninstall

Delete folder at `%LOCALAPPDATA%\PowerTools-Suite` and remove `PS-PowerToolsSuite` function from PowerShell profile.

## Adding Custom Modules

Create `modules/NN-CustomName.ps1`:

```powershell
Register-PowerToolsModule `
    -Id "custom-id" `
    -Name "Custom Module" `
    -Description "What it does." `
    -Category "Category" `
    -RequiresAdmin $false `
    -Show {
        # Return WPF control (Grid, StackPanel, etc.)
        # Access theming via: Get-PowerToolsWindow, Get-PowerToolsBrush
    }
```

## Troubleshooting

**"PowerShell 7 Required"**
→ Install from https://aka.ms/powershell

**"The term 'PS-PowerToolsSuite' is not recognized"**
→ Open NEW PowerShell window after install

**"ExecutionPolicy" error**
→ Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Modules not loading**
→ Check repo structure; all files in `modules/` must be present

## License

MIT

## Author

ReAlNoMo
