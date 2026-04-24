Antwort Nr. 3

```markdown
# PowerTools Suite

Unified WPF launcher for Windows utility scripts. One-click install via PowerShell.

## Quick Start (GitHub)

**Option 1: Direct Install (Trusted)**
```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/install.ps1" | iex
```
OR use
```
irm "https://realnomo.tech" | iex
```

**Option 2: Safe Install (Review First)**
```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/install.ps1" -OutFile "$env:TEMP\install.ps1"
& "$env:TEMP\install.ps1"
```

Then type `PS-PowerToolsSuite` in any PowerShell window.

## Requirements

- **PowerShell 7.0+** (downloads from https://aka.ms/powershell if needed)
- **Windows 10/11** (WPF required)
- **Admin elevation** for Gaming Optimizer, Hardware Inventory, Explorer Normalizer

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
**Category:** Windows Tweaks | **Admin:** Yes

Force consistent File Explorer view across all folders.

**What it does:**
- Disable grouping in all folder types
- Set Details view (not tiles, list, or compact)
- Sort by Name ascending
- Apply to: Generic, Downloads, Documents, Pictures, Music, Videos, User Files, Searches
- Clear Shell Bags and BagMRU caches
- Restart Explorer automatically

**Registry changes:**
```
HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\*
  - LogicalViewMode = 1 (Details view)
  - Mode = 4 (Details columns)
  - GroupByKey:PID = 0 (no grouping)
  - Sort = 0 (by Name)
  - GroupByDirection = 1
```

**Effect:** Open each folder once after running to apply permanently. Persists across explorer restarts.

---

### 3. Hardware Inventory
**Category:** Diagnostics | **Admin:** Yes

Generate comprehensive HTML report of system hardware.

**What it does:**
- Collect CPU: name, cores, threads, cache, socket, speed, driver version
- Collect RAM: capacity, speed, manufacturer, part numbers per slot
- Collect GPU: model, VRAM, resolution, driver version, driver date
- Collect storage: SSDs/HDDs, size, interface, partitions, free space, serial numbers
- Collect network: adapters, MAC addresses, IP config, driver versions, driver dates
- Collect audio: devices, manufacturers, drivers, status
- Collect all PnP drivers: class, version, provider, date
- Generate styled HTML report (dark theme, sortable tables)
- Open in default browser automatically

**Output:** `Desktop\Hardware_Report_YYYY-MM-DD_HH-MM.html`

**Features:**
- Button to re-open last generated report
- Activity log with timestamps
- Clear log functionality
- Status indicators

**Windows changes:** None (read-only diagnostic)

---

### 4. Sandboxie Browser Launcher
**Category:** Security | **Admin:** No

Launch browsers in isolated Sandboxie sandbox.

**What it does:**
- Launch Chrome in incognito mode inside Sandboxie
- Launch Firefox in private mode inside Sandboxie
- Configurable sandbox name (default: DefaultBox)
- Detect installed browsers and Sandboxie-Plus
- Show prerequisite status at startup
- Activity log with launch confirmations

**Requirements:**
- Sandboxie-Plus installed (`C:\Program Files\Sandboxie-Plus\Start.exe`)
- Chrome or Firefox installed

**Windows changes:** None (Sandboxie isolation only)

**Use case:** Browse untrusted sites safely; all downloads/changes isolated; test malware samples.

---

### 5. Windows 11 Gaming Optimizer
**Category:** Performance | **Admin:** Yes

Apply 16 curated gaming & performance tweaks idempotently. Auto-detects which are already applied.

#### Tweaks Included

**Security Functions (Highest FPS gain block)**

| Tweak | Registry Path | Default → Set | Effect | Reboot | Risk |
|---|---|---|---|---|---|
| Game Mode Enable | `HKCU:\Software\Microsoft\GameBar` `AutoGameModeEnabled` | 0 → 1 | Prioritize game threads, pause background tasks | No | None |
| Windowed Game Optimizations | `HKCU:\System\GameConfigStore` `GameDVR_FSEBehaviorMode` | — → 2 | Flip model for windowed games, low latency | No | None |
| Core Isolation / HVCI Disable | `HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity` `Enabled` | 1 → 0 | **3–25% FPS gain**, eliminates hypervisor validation overhead | **Yes** | **HIGH** |
| Dynamic Lighting Disable | `HKCU:\Software\Microsoft\Lighting` `AmbientLightingEnabled` | 1 → 0 | Disable RGB/ambient effects, reduce GPU calls | No | None |
| Apps Control Lighting Disable | `HKCU:\Software\Microsoft\Lighting` `ControlledByForegroundApp` | 1 → 0 | Prevent apps from controlling lights | No | None |

**CPU & Performance Management**

| Tweak | Registry Path | Default → Set | Effect | Reboot | Risk |
|---|---|---|---|---|---|
| GPU Hardware Scheduling (HAGS) | `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers` `HwSchMode` | 1 → 2 | GPU manages own memory/tasks, ~2ms latency reduction | **Yes** | Low |
| Win32PrioritySeparation Gaming | `HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl` `Win32PrioritySeparation` | 26 → 36 (or 24) | Long quantum scheduling for gaming threads, minimize micro-stutters | No | Low |
| System Responsiveness | `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile` `SystemResponsiveness` | 20 → 10 | More CPU time to foreground (games), less to background | No | Low |
| Network Throttling Disable | `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile` `NetworkThrottlingIndex` | 0 → 0xFFFFFFFF | Full network bandwidth available | No | None |

**Visual Effects (Reduce Overhead)**

| Tweak | Registry Path | Default → Set | Effect | Reboot | Risk |
|---|---|---|---|---|---|
| Transparency Effects Disable | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize` `EnableTransparency` | 1 → 0 | No glass/blur effects, instant window rendering | No | None |
| Animation Effects Disable | `HKCU:\Control Panel\Desktop\WindowMetrics` `MinAnimate` | 1 → "0" | No window open/close animations | No | None |

**Gaming Services & Features**

| Tweak | Registry Path | Default → Set | Effect | Reboot | Risk |
|---|---|---|---|---|---|
| Games Scheduling Category | `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games` `Scheduling Category` | Normal → "High" | OS reserves CPU time for games | No | None |

**Privacy & Search**

| Tweak | Registry Path | Default → Set | Effect | Reboot | Risk |
|---|---|---|---|---|---|
| Search History Disable | `HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings` `IsDeviceSearchHistoryEnabled` | 1 → 0 | Don't track search history | No | None |
| File Search = Enhanced | `HKLM:\SOFTWARE\Microsoft\Windows Search` `CrawlingMode` | 0 → 1 | Index all files for faster search | No | None |
| Website Language List Disable | `HKCU:\Control Panel\International\User Profile` `HttpAcceptLanguageOptOut` | 0 → 1 | Don't send language preferences to websites | No | None |
| Share Across Devices Disable | `HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP` `CdpSessionUserAuthzPolicy` | 1 → 0 | Disable cross-device sharing | No | None |

#### UI Features

- **Checkbox-driven selection:** Enable/disable tweaks individually
- **Status detection:** Shows "APPLIED" (green) or "MISSING" (orange) per tweak
- **Batch operations:** Select All / Select Missing / Select None buttons
- **Recheck:** Re-scan current status without applying
- **Reboot notification:** Auto-detects tweaks requiring restart, prompts user
- **Activity log:** Timestamp-tagged success/failure messages
- **Idempotent:** Safe to run multiple times; skips already-applied tweaks

#### Performance Gains (Estimated)

| Hardware Generation | FPS Gain | Latency Gain | Load Times |
|---|---|---|---|
| Intel 12th Gen+ / AMD Ryzen 5000+ / X3D | +8–20% | -15–25ms | +20–50% (with NVMe tweaks) |
| Intel pre-10th Gen / AMD Ryzen 2000/3000 | +15–35% | — | — |

**Highest impact single tweaks:**
1. HVCI disable (up to 25% FPS on older systems)
2. GPU Hardware Scheduling activation (2ms latency cut)
3. Win32PrioritySeparation tuning (+3–5% FPS consistency)

#### Special Notes

- **AMD X3D CPUs:** Game Mode MUST remain enabled. Communicates with chipset driver for cache allocation; disabling costs up to -15% FPS.
- **Intel 6th–11th Gen (Downfall/GDS):** Set `FeatureSettingsOverride = 0x2000000` for additional +30% in AVX-heavy workloads (not in this tool; manual registry required).
- **Requires reboot:** HVCI disable, GPU Hardware Scheduling enable
- **Competive vs. AAA:** Win32PrioritySeparation = 0x24 (36) for shooters; 0x18 (24) for open-world games with many background threads

---

### 6. Linux ISO Downloader
**Category:** Downloads | **Admin:** No

Download latest Linux distribution ISOs with hash verification and parallel downloads.

**What it does:**
- Resolve latest stable versions for 6 distributions
- Download from multiple mirrors (automatic failover)
- Verify SHA256 hash automatically
- Download up to 5 ISOs in parallel (user-configurable: 1–5)
- Skip existing files (no re-download)
- Show progress bar (0–100%)
- Activity log with per-file status

**Supported Distributions**

| Distro | Edition | Hash Verification | Source |
|---|---|---|---|
| **Ubuntu** | Desktop + Server (latest LTS) | SHA256 | releases.ubuntu.com |
| **Debian** | Netinst (current stable) | SHA256 | cdimage.debian.org |
| **Fedora** | Workstation (latest) | None (official) | dl.fedoraproject.org |
| **Arch Linux** | Monthly build (latest) | None (from source) | mirror.rackspace.com |
| **CachyOS** | Desktop edition | None (GitHub release) | github.com (CachyOS-ISO) |
| **Pop!_OS** | Intel + NVIDIA (latest stable) | SHA256 | iso.pop-os.org |

**Features:**
- Destination folder selector (browse button)
- Per-distro checkboxes (select which to download)
- Parallel download limit spinner (1–5, default 3)
- Progress bar showing overall completion
- Activity log: timestamps, mirror used, hash status, errors
- Clear log button
- Status messages: "Already exists: X", "Done", hash mismatches, network errors

**Output:** User-selected destination folder (default: `D:\ISOs`)

**Mirror Fallback Strategy:**
- Primary mirror selected via test (fastest response)
- If primary fails, all alternate mirrors tried
- If all fail, returns error message
- Automatic retry on transient network errors

**Windows changes:** None

**Use case:** Build bootable USB drives; VM ISO collection; multi-distro testing; automated distribution downloads.

---

## Manual Installation

If `irm | iex` doesn't work:

1. Download `install.ps1` from this repo
2. Run in PowerShell: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Run: `.\install.ps1`
4. Follow on-screen prompts

Default install location: `%LOCALAPPDATA%\PowerTools-Suite`

## Uninstall

```powershell
Remove-Item -Path "$env:LOCALAPPDATA\PowerTools-Suite" -Recurse -Force
```

Remove `PS-PowerToolsSuite` function from PowerShell profile (usually `$PROFILE`).

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

**Module naming:** `NN-ModuleName.ps1` where NN = 2-digit number (auto-sorted).

**Best practices:**
- XAML inline (no external files)
- Script-scoped variables for UI control references
- Global functions for event handler logic
- Brush access: `Get-PowerToolsBrush "ColorName"` (Primary, TextDark, Success, Danger, etc.)
- Window reference: `Get-PowerToolsWindow`
- Activity logs with timestamps
- Try-catch error handling

## Troubleshooting

**"PowerShell 7 Required"**
→ Install from https://aka.ms/powershell

**"The term 'PS-PowerToolsSuite' is not recognized"**
→ Open NEW PowerShell window after install

**"ExecutionPolicy" error**
→ Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Modules not loading**
→ Verify all files in `modules/` folder are present
→ Check file naming: `01-HashVerifier.ps1`, `02-ExplorerViewNormalizer.ps1`, etc.
→ Ensure no syntax errors: `Test-Path ./modules/*.ps1`

**Gaming Optimizer shows "Missing" for all tweaks**
→ Run as Administrator (elevation required)
→ Verify Windows 11 22H2 or later
→ Some tweaks require build ≥ 26100 (24H2) for NVMe Stack

**Explorer Normalizer not applying**
→ Restart File Explorer: `taskkill /f /im explorer.exe && start explorer`
→ Run again to apply changes

**ISO downloader timeout**
→ Check internet connection
→ Reduce parallel download limit (1–2 instead of 3–5)
→ Select fewer distributions
→ Manual mirror selection if automatic fails

## Compatibility

| Component | Requirement | Notes |
|---|---|---|
| PowerShell | 7.0+ | 7.2+ recommended for stability |
| Windows | 10/11 | 11 22H2+ for Gaming Optimizer features |
| Admin | Required | Elevation automatic on launch |
| Display | 1024×600 minimum | Responsive to 4K displays |
| .NET Framework | 4.5+ | Built-in Windows 10/11 |
| WPF | Yes | Required for UI; included in Windows |

## License

MIT

## Author

ReAlNoMo | Version 1.1 | April 2026
```
