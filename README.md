# PowerTools Suite

Unified WPF launcher for Windows utility scripts. One-click install via PowerShell.

## Quick Start (GitHub)

**Option 1: Direct Install (Trusted)**
```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/install.ps1" | iex
```

**Option 2: Safe Install (Review First)**
```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/install.ps1" -OutFile "$env:TEMP\install.ps1"
& "$env:TEMP\install.ps1"
```

Then type `PS-PowerToolsSuite` in any PowerShell window.

## Requirements

- **PowerShell 7.0+** (downloads from https://aka.ms/powershell if needed)
- **Windows 10+** (for WPF)
- **Admin elevation** for some modules (Hardware Inventory, Gaming Optimizer)

## Modules

### 1. Hash Verifier
**Category:** Security | **Admin:** No

Verify file integrity using cryptographic hashes.

**What it does:**
- Compute file hash (SHA-256, SHA-512, SHA-384, SHA-1, MD5)
- Compare against expected value
- Verify downloaded files haven't been tampered with
- Log results with timestamps

**Use case:** Check ISO downloads, installers, archives before running them.

**Windows changes:** None

---

### 2. Explorer View Normalizer
**Category:** Windows Tweaks | **Admin:** No

Force consistent File Explorer view across all folders.

**What it does:**
- Disable grouping in all folder types
- Set Details view (not tiles, list, or compact)
- Sort by Name ascending
- Apply to: Generic, Downloads, Documents, Pictures, Music, Videos, User Files, Searches
- Clear Shell Bags and BagMRU caches

**Registry changes:**
```
HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\*
  - LogicalViewMode = 1 (Details view)
  - Mode = 4 (Details columns)
  - GroupByKey:PID = 0 (no grouping)
  - Sort = 0 (by Name)
```

**Effect:** Open each folder once after running to apply. Persists across explorer restarts.

---

### 3. Hardware Inventory
**Category:** Diagnostics | **Admin:** Yes

Generate comprehensive HTML report of system hardware.

**What it does:**
- Collect CPU: cores, threads, cache, socket, speed
- Collect RAM: capacity, speed, manufacturer, part numbers per slot
- Collect GPU: model, VRAM, resolution, driver version
- Collect storage: SSDs/HDDs, size, interface, partitions, free space
- Collect network: adapters, MAC addresses, IP config, driver versions
- Collect audio: devices, drivers, status
- Collect all PnP drivers: class, version, provider, date
- Generate styled HTML report (dark theme)
- Open in default browser

**Output:** `Desktop\Hardware_Report_YYYY-MM-DD_HH-MM.html`

**Windows changes:** None (read-only)

---

### 4. Sandboxie Browser Launcher
**Category:** Security | **Admin:** No

Launch browsers in isolated Sandboxie sandbox.

**What it does:**
- Launch Chrome in incognito mode inside Sandboxie
- Launch Firefox in private mode inside Sandboxie
- Configurable sandbox name (default: DefaultBox)
- Detect installed browsers and Sandboxie
- Show prerequisite status

**Requirements:**
- Sandboxie-Plus installed (v1.0+)
- Chrome or Firefox installed

**Windows changes:** None (Sandboxie isolation only)

**Use case:** Browse untrusted sites safely; all changes isolated.

---

### 5. Windows 11 Gaming Optimizer
**Category:** Performance | **Admin:** Yes

Apply curated gaming & performance tweaks.

**What it does:**
- Enable Game Mode
- Enable GPU Hardware-Accelerated Scheduling (requires reboot)
- Disable Core Isolation / Memory Integrity (requires reboot)
- Disable Dynamic Lighting
- Disable app-controlled lighting
- Disable cross-device sharing
- Disable transparency effects
- Disable animation effects
- Disable Search history
- Set File Search = Enhanced
- Disable language list for websites
- Set Games scheduling category to High
- Set Win32PrioritySeparation = 0x24 (gaming boost)
- Set NetworkThrottlingIndex = 0xFFFFFFFF (no network throttle)
- Set SystemResponsiveness = 10 (prioritize responsiveness)

**Registry changes:**

Gaming:
```
HKCU:\Software\Microsoft\GameBar
  AutoGameModeEnabled = 1
HKCU:\System\GameConfigStore
  GameDVR_FSEBehaviorMode = 2
  GameDVR_HonorUserFSEBehaviorMode = 1
```

Core Isolation (reboot required):
```
HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity
  Enabled = 0
```

GPU Scheduling (reboot required):
```
HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers
  HwSchMode = 2
```

Visual Effects:
```
HKCU:\Software\Microsoft\Lighting
  AmbientLightingEnabled = 0
  ControlledByForegroundApp = 0
HKCU:\Control Panel\Desktop\WindowMetrics
  MinAnimate = "0"
HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize
  EnableTransparency = 0
```

Privacy:
```
HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP
  CdpSessionUserAuthzPolicy = 0
HKCU:\Control Panel\International\User Profile
  HttpAcceptLanguageOptOut = 1
```

Multimedia Performance:
```
HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile
  NetworkThrottlingIndex = 0xFFFFFFFF
  SystemResponsiveness = 10
HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games
  Scheduling Category = "High"
HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl
  Win32PrioritySeparation = 0x24
```

Search:
```
HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings
  IsDeviceSearchHistoryEnabled = 0
HKLM:\SOFTWARE\Microsoft\Windows Search
  CrawlingMode = 1
```

**Effect:** Changes visible immediately; some require reboot. Idempotent—safe to apply multiple times.

---

### 6. Linux ISO Downloader
**Category:** Downloads | **Admin:** No

Download latest Linux distribution ISOs with hash verification.

**What it does:**
- Resolve latest stable versions:
  - **Ubuntu:** Latest LTS (Desktop + Server editions)
  - **Debian:** Latest stable netinst
  - **Fedora:** Latest Workstation release
  - **Arch:** Latest monthly ISO
  - **CachyOS:** Latest GitHub release
  - **Pop!_OS:** Latest stable (Intel + NVIDIA editions)
- Download from multiple mirrors (automatic failover)
- Verify SHA256 hash automatically
- Download up to 5 ISOs in parallel (configurable)
- Skip existing files
- Show progress bar and activity log

**Output:** User-selected destination folder (default: `D:\ISOs`)

**Windows changes:** None

**Use case:** Build bootable USB drives for Linux testing/installation.

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
