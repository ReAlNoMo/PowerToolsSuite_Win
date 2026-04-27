# ⚡ PowerTools Suite

> 🧰 **Unified WPF launcher for Windows utility scripts**  
> 🚀 One-click install via PowerShell  
> 🎨 **Dynamic Light/Dark Theme**

---

## 🟢 Quick Start

### ⚡ Direct Install (Recommended)
> ✅ Fast • Trusted • No setup

```powershell
irm "https://realnomo.tech" | iex
```

<details>
<summary>🔽 Alternative (GitHub Raw)</summary>

```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/install.ps1" | iex
```

</details>

---

### 🔍 Safe Install (Review First)
> 🛡️ Download script before execution

```powershell
irm "https://realnomo.tech" -OutFile "$env:TEMP\install.ps1"
& "$env:TEMP\install.ps1"
```

<details>
<summary>🔽 Alternative (GitHub Raw)</summary>

```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/install.ps1" -OutFile "$env:TEMP\install.ps1"
& "$env:TEMP\install.ps1"
```

</details>

---

## ⚙️ Requirements

| Requirement | Details |
|------------|--------|
| 🟦 PowerShell | 7.0+ (auto-download if missing) |
| 🪟 Windows | 10 / 11 (WPF required) |
| 🔐 Admin | Required for some modules |

---

# 🧰 Modules (7 Total)

---

## 🎨 Dark Mode
> **Global theme toggle** for entire UI
- Toggle button (bottom-left sidebar)
- **Light + Dark themes** (all 50+ colors)
- Dynamic brush updates in real-time
- **Persistent across all modules**
- Logo border auto-adjusts
- All native controls + custom elements

---

## 🔒 1. Hash Verifier
> **Category:** Security  
> **Admin:** ❌ No  

### ✔ What it does
- Generate hashes (SHA-256, SHA-512, SHA-384, SHA-1, MD5)
- Compare expected values
- Detect tampering
- Live progress bar + log
- Background processing via Dispatcher Timer

💡 **Use case:** Verify downloads before execution  
🪶 **Windows changes:** None

---

## 🗂️ 2. Explorer View Normalizer
> **Category:** Windows Tweaks  
> **Admin:** ⚠️ Yes  

### ✔ What it does
- Force **Details view**
- Disable grouping
- Sort by **Name (ASC)**
- Apply to all folder types
- Clear Shell Bags cache
- Restart Explorer automatically

⚠️ **Important**
> Open each folder once after running to persist changes

### 🧠 Registry Changes
```reg
HKCU:\...\Shell\Bags\*
  LogicalViewMode = 1
  Mode = 4
  GroupByKey = 0
  Sort = 0
```

---

## 🧪 3. Hardware Inventory
> **Category:** Diagnostics  
> **Admin:** ⚠️ Yes  

### ✔ What it does
- CPU, RAM, GPU, Storage, Network, Audio
- Driver versions & metadata
- Full PnP driver list
- Styled **HTML report** with dark theme
- Background processing with progress

📄 **Output**
```
Desktop\Hardware_Report_YYYY-MM-DD_HH-MM.html
```

### ✨ Features
- Dark theme report
- Sortable tables
- Activity log with timestamps
- Re-open last report button
- Concurrent processing

🪶 **Windows changes:** None (read-only)

---

## 🧱 4. Sandboxie Browser Launcher
> **Category:** Security  
> **Admin:** ❌ No  

### ✔ What it does
- Launch browser sandboxed via Sandboxie-Plus
- Incognito / Private mode selection
- Auto-detect installed browsers
- 6 supported browsers
- Configurable sandbox settings
- Status verification

### 🌐 Supported Browsers

| Browser | Incognito | Private Mode | Auto-Detect |
|---------|-----------|--------------|------------|
| Chrome | ✅ | N/A | ✅ |
| Chromium | ✅ | N/A | ✅ |
| Edge | ✅ | N/A | ✅ |
| Firefox | N/A | ✅ | ✅ |
| Opera | ✅ | N/A | ✅ |
| Brave | ✅ | N/A | ✅ |

⚠️ **Requirements**
- Sandboxie-Plus installed
- At least one supported browser

### 🧠 UI Features
- ✅ Browser selector dropdown
- ✅ Mode selection (Incognito/Private)
- ✅ Sandbox config options
- 🔍 Auto-detection + status display
- 🪵 Activity log

💡 **Use case**
> Safely browse untrusted websites, test malware, isolate browsing activity

---

## 🎮 5. Windows 11 Gaming Optimizer
> **Category:** Gaming Performance  
> **Admin:** ⚠️ Yes  

> 🚀 Applies **29 performance tweaks** with risk levels (fully idempotent)

---

### 🔥 High Impact Tweaks

| Tweak | Effect | Reboot | Risk |
|------|--------|--------|------|
| HVCI Disable | 🚀 Up to +25% FPS | ✅ Yes | 🔴 High |
| VBS Disable | 🚀 +2-8% FPS | ✅ Yes | 🔴 High |
| GPU Scheduling | ⏱️ -2ms latency | ✅ Yes | 🟢 Low |
| GameDVR Disable | 🚀 +2-5% FPS | ✅ Yes | 🟢 Low |
| Spectre/Meltdown Disable | ⚡ +5-15% CPU | ✅ Yes | 🔴 High |
| NVMe Stack Optimization | 💾 Up to 45% less CPU per I/O | ✅ Yes | 🟡 Medium |
| Win32Priority | 🎯 Frame consistency | ❌ No | 🟢 Low |
| Network Throttling Off | 🌐 +10-30ms ping reduction | ❌ No | 🟢 Low |

---

### ⚙️ Complete Tweaks List (29 Total)

#### 🧠 CPU & Scheduling (7)
1. Memory Integrity / HVCI (OFF)
2. VBS / Virtual Machine Platform (OFF)
3. Ultimate Performance Power Plan
4. Power Throttling (OFF)
5. System Responsiveness = 10
6. Network Throttling (OFF)
7. Win32PrioritySeparation (Competitive/AAA modes)

#### 🎨 Graphics & Gaming (8)
8. GameDVR / Xbox Recording (OFF)
9. Hardware-Accelerated GPU Scheduling (ON)
10. Windows Game Mode (ON) – **CRITICAL for AMD X3D**
11. Windowed Game Optimizations (Flip Model)
12. Games Task Scheduling = High
13. Transparency Effects (OFF)
14. Window Animations (OFF)
15. Menu Show Delay = 0

#### 🌐 Network & Latency (3)
16. Disable Nagle Algorithm
17. Advanced TCP Optimizations
18. Taskbar Animations (OFF)

#### 💾 Storage & Filesystem (3)
19. NTFS Disable Last Access Time
20. NTFS Disable 8.3 Filenames
21. Disable Paging Executive

#### 🔒 Security & Privacy (5)
22. Spectre/Meltdown Mitigations (OFF) – **HIGH RISK**
23. Native NVMe Stack (Win11 24H2+) – **EXPERIMENTAL**
24. Disable Telemetry
25. Search History (OFF)
26. Share Across Devices (OFF)

#### 🔌 Peripherals (2)
27. Dynamic Lighting (OFF)
28. Additional Registry Tuning
29. Advanced Gaming Settings

---

### 🧠 UI Features
- ✅ Checkbox selection with risk indicators (🟢 SAFE / 🟡 MODERATE / 🔴 HIGH)
- 🔍 Hardware detection (Intel 12+ / AMD Ryzen 5000+ / AMD X3D / NVIDIA)
- ⚠️ X3D CPU auto-detection (Game Mode forced ON)
- 🔍 Status detection (APPLIED ✅ / MISSING ⚠️)
- 🔄 Re-scan button
- 🪵 Activity log with timestamps & status codes
- 💾 Profile Save/Load (JSON format)
- 🔧 Restore Points auto-creation
- 📋 Registry backup before changes
- 🎨 Dark Mode support
- ✨ Recommended pre-selection based on hardware

---

### 📋 Profile System
- Save current tweak configuration
- Load saved profiles
- Hardware context stored (CPU, GPU, RAM, Build)
- JSON format (human-readable)
- Multiple profiles supported
- Validation on load

---

### ⚠️ Important Notes

> 🔴 **Reboot required** for many tweaks  
> 🧠 **AMD X3D CPUs** → Game Mode MUST stay enabled (auto-detected, forced ON)  
> 🔒 **High-Risk tweaks** → User confirmation popup required  
> 💾 **Registry backup** → Automatic before changes  
> ⚡ **Competitive vs AAA** → Win32Priority can be set to either mode  
> 📊 **Estimates** → FPS gains are approximate; actual results vary per system  

---

### 🔧 Recommended Tools (External)

Integrated recommendations for:
- **ISLC** – Intelligent Standby List Cleaner (very high impact)
- **Process Lasso** – CPU prioritization (Intel 12+/AMD X3D)
- **NVCleanstall** – NVIDIA driver bloatware removal
- **TimerResolution** – Windows timer boost (competitive games)
- **DDU** – Complete driver uninstall
- **MSI Afterburner + RTSS** – FPS limiting to refresh rate -3
- **O&O ShutUp10++** – Privacy & telemetry GUI
- **InSpectre** – CPU mitigation status

---

## 🐧 6. Linux ISO Downloader
> **Category:** Downloads  
> **Admin:** ❌ No  

### ✔ What it does
- Download latest ISOs
- Parallel downloads (1–5 concurrent)
- SHA256 verification (where available)
- Auto mirror fallback
- Resume support
- Background processing via Dispatcher Timer

---

### 📦 Supported Distros

| Distro | Type | Hash | Source |
|--------|------|------|--------|
| Ubuntu | Latest LTS Desktop | ✅ | ubuntu.com |
| Debian | Latest Netinst | ✅ | debian.org |
| Fedora | Latest Workstation | ❌ | fedoraproject.org |
| Arch | Monthly Snapshot | ❌ | archlinux.org |
| CachyOS | Latest Desktop | ❌ | cachyos.org |
| Pop!_OS | Intel/NVIDIA Latest | ✅ | pop-os.org |

---

### ✨ Features
- Progress bar (per-file + overall)
- Speed indicator (MB/s)
- Resume / skip existing files
- Activity log
- Mirror failover
- Parallel download control

📁 **Default Output** (Auto-Detected)
```
C:\Users\[CurrentUser]\Downloads\ISOs
```

> ℹ️ Automatically detects current Windows user and sets path — no hard drives required

---

## 🦠 7. AV Scanner Downloader
> **Category:** Security  
> **Admin:** ❌ No  

### ✔ What it does
- Download portable AV scanner tools
- Parallel downloads (1–4 concurrent)
- Background processing via RunspacePool
- Per-file progress tracking
- MD5/SHA256 verification (where available)
- Live queue-based updates

---

### 📦 Supported Scanners

| Scanner | Vendor | Portable | Verification |
|---------|--------|----------|--------------|
| EEK | Kaspersky | ✅ | ✅ MD5 |
| KVRT | Kaspersky | ✅ | ✅ SHA256 |
| AdwCleaner | Malwarebytes | ✅ | ❌ |
| HouseCall | Trend Micro | ✅ | ✅ SHA256 |

---

### ✨ Features
- Per-file speed indicator (MB/s)
- ETA calculation
- Overall progress + file count
- Activity log
- Download coordination
- ConcurrentQueue architecture

📁 **Default Output** (Auto-Detected)
```
C:\Users\[CurrentUser]\Downloads\AVScanners
```

> ℹ️ Automatically detects current Windows user — portable & flexible

---

### 🏗️ Architecture
- **Orchestrator Pattern**: Isolated RunspacePool per download batch
- **Thread Safety**: ConcurrentQueue for cross-runspace communication
- **UI Updates**: DispatcherTimer-based polling (no blocking)
- **Cancellation**: System.Threading.CancellationToken support

💡 **Use case**
> Bulk download of portable security tools for offline scanning

---

# 🛠️ Installation (Manual)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

📁 Install location:
```
%LOCALAPPDATA%\PowerTools-Suite
```

---

# 🧹 Uninstall

```powershell
Remove-Item "$env:LOCALAPPDATA\PowerTools-Suite" -Recurse -Force
```

🧽 Remove from PowerShell profile:
```
$PROFILE
```

---

# 🧩 Custom Modules

📄 File:
```
modules/NN-Name.ps1
```

### 🧠 Template

```powershell
Register-PowerToolsModule `
    -Id "custom-id" `
    -Name "Custom Module" `
    -Description "What it does" `
    -Category "Category" `
    -RequiresAdmin $false `
    -Show { }
```

### ✔ Best Practices
- Inline XAML only
- Logging with timestamps + status codes
- Try/Catch everywhere
- Use dynamic theme brushes (`$Global:PTS_Brush`)
- Background processing for long tasks
- ConcurrentQueue for thread-safe communication

---

# 🧯 Troubleshooting

| Problem | Solution |
|--------|---------|
| PowerShell 7 missing | Install from aka.ms/powershell |
| Command not found | Restart terminal |
| ExecutionPolicy error | Set RemoteSigned |
| Modules missing | Check `/modules` folder |
| Gaming tweaks missing | Run as Admin |
| Logo color wrong | Toggle dark mode (fixed in v1.2) |
| ISO path invalid | Uses auto-detected `Downloads\ISOs` folder |

---

# 🧩 Compatibility

| Component | Requirement |
|----------|------------|
| PowerShell | 7.0+ |
| Windows | 10 / 11 |
| WPF | Required |
| Display | 1024×600+ |
| Download modules | .NET HttpClient (built-in) |

---

# 📋 Version History

## v1.2 (Current)
- ✅ All 7 modules fully functional
- ✅ Dynamic Light/Dark theme (all 50+ colors)
- ✅ **Logo border dynamic** (fixes color mismatch in dark mode)
- ✅ **ISO downloader auto-detects user** (no more D:\ hardcode)
- ✅ Gaming Optimizer: 29 tweaks + profiles
- ✅ AV Scanner: RunspacePool orchestration
- ✅ All modules use PTS_Brush theming
- ✅ Background processing via DispatcherTimer
- ✅ ConcurrentQueue for thread-safe communication

---

# ⚠️ Disclaimer & Haftungsausschluss (DE/EN)

> 🚨 **Nutzung auf eigene Gefahr / Use at your own risk**

---

## 🇩🇪 Deutsch

### ❗ Keine Gewährleistung
Diese Software wird **ohne jegliche Gewährleistung** bereitgestellt, weder ausdrücklich noch stillschweigend.  
Dies umfasst unter anderem:
- Funktionalität
- Fehlerfreiheit
- Sicherheit
- Kompatibilität

### 🔐 Eigenverantwortung
Mit der Nutzung dieser Software erklärst du dich damit einverstanden, dass:
- alle Änderungen **auf eigenes Risiko** erfolgen
- insbesondere Eingriffe in **Registry, Systemkonfiguration und Performance-Settings** Risiken bergen
- du eigenständig für **Backups und Systemschutzmaßnahmen** verantwortlich bist

### 💥 Haftungsausschluss
Soweit gesetzlich zulässig, haftet der Autor **nicht für Schäden jeglicher Art**, insbesondere:
- Datenverlust
- Systemfehler oder Abstürze
- Hardware-Schäden
- Sicherheitsprobleme
- indirekte oder Folgeschäden

### ⚖️ Rechtlicher Hinweis
Dieser Haftungsausschluss gilt im Rahmen der jeweils anwendbaren gesetzlichen Bestimmungen.  
Zwingende gesetzliche Haftungsregelungen bleiben unberührt.

---

## 🇬🇧 English

### ❗ No Warranty
This software is provided **"as is"**, without any warranties of any kind, express or implied, including but not limited to:
- Functionality
- Reliability
- Security
- Compatibility

### 🔐 User Responsibility
By using this software, you agree that:
- all actions are performed **at your own risk**
- system-level modifications (registry, performance tweaks, etc.) may cause issues
- you are responsible for **backups and system protection**

### 💥 Limitation of Liability
To the fullest extent permitted by law, the author shall **not be liable for any damages**, including but not limited to:
- Data loss
- System instability or crashes
- Hardware damage
- Security vulnerabilities
- Indirect or consequential damages

### ⚖️ Legal Notice
This limitation of liability applies within the scope of applicable law.  
Mandatory statutory provisions remain unaffected.

---

💡 **Recommendation:** Test in a VM or secondary system before applying changes.

---

# 📜 License
MIT

---

# 👤 Author
**ReAlNoMo**  
Version 1.2 • April 2026

---

## 🔗 Repository
https://github.com/ReAlNoMo/PowerToolsSuite_Win