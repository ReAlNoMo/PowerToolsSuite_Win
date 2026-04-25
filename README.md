# ⚡ PowerTools Suite

> 🧰 **Unified WPF launcher for Windows utility scripts**  
> 🚀 One-click install via PowerShell

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

# 🧰 Modules

---

## 🎨 Dark Mode
> **Global theme toggle** for entire UI
- Toggle button (bottom-left sidebar)
- Light + Dark themes
- Dynamic brush updates
- Persistent across modules
- All native controls

---

## 🔒 1. Hash Verifier
> **Category:** Security  
> **Admin:** ❌ No  

### ✔ What it does
- Generate hashes (SHA-256, SHA-512, SHA-384, SHA-1, MD5)
- Compare expected values
- Detect tampering
- Log results with timestamps

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
- Styled **HTML report**

📄 **Output**
```
Desktop\Hardware_Report_YYYY-MM-DD_HH-MM.html
```

### ✨ Features
- Dark theme report
- Sortable tables
- Activity log
- Re-open last report

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
> **Category:** Performance  
> **Admin:** ⚠️ Yes  

> 🚀 Applies **29 performance tweaks** with risk levels (idempotent)

---

### 🔥 High Impact Tweaks

| Tweak | Effect | Reboot | Risk |
|------|--------|--------|------|
| HVCI Disable | 🚀 Up to +25% FPS | ✅ Yes | 🔴 High |
| GPU Scheduling | ⏱️ -2ms latency | ✅ Yes | 🟢 Low |
| Spectre/Meltdown Disable | ⚡ +5-10% CPU | ✅ Yes | 🔴 High |
| NVMe Stack Optimization | 💾 SSD speed boost | ✅ Yes | 🟡 Medium |
| Win32Priority | 🎯 Better frame consistency | ❌ No | 🟢 Low |

---

### ⚙️ System Tweaks Overview (29 Total)

<details>
<summary>🔽 Show all tweaks</summary>

#### 🧠 CPU & Scheduling
- Win32PrioritySeparation
- SystemResponsiveness
- NetworkThrottling disabled
- Timer Resolution Boost
- Process Priority Boost

#### 🎨 Visual Effects
- Disable transparency
- Disable animations
- Disable blur effects
- Reduce shadow depth

#### 💾 Storage & I/O
- NVMe Stack (Build 26100+)
- Disk I/O Priority
- Cache optimization

#### 🎮 Gaming Features
- Game Mode
- GPU Scheduling
- DirectX 12 optimization
- DXVK settings

#### 🔒 Security (High Risk)
- HVCI Disable
- Spectre/Meltdown Disable
- Virtualization tweaks

#### 🌐 Network
- DNS caching
- TCP optimization
- UDP buffer tuning

#### 🔋 Power & Thermal
- Power Plan (High Performance)
- Thermal throttling control

#### 🔒 Privacy
- Disable search history
- Disable cross-device sharing
- Telemetry reduction

</details>

---

### 🧠 UI Features
- ✅ Checkbox selection with risk indicators
- 🔍 Hardware detection (Intel/AMD/NVIDIA/AMD GPU)
- ⚠️ X3D CPU auto-detection
- 🔍 Status detection (APPLIED / MISSING)
- 🔄 Re-scan button
- 🪵 Activity log with timestamps
- 💾 Profile Save/Load (JSON format)
- 🔄 Registry Backup before changes
- 🔧 Restore Points auto-creation
- 🎨 Dark Mode support

---

### 📋 Profile System
- Save current tweak configuration
- Load saved profiles
- Hardware context stored
- JSON format (human-readable)
- Multiple profiles supported

---

### ⚠️ Important Notes

> 🔴 **Reboot required** for some tweaks  
> 🧠 **AMD X3D CPUs** → Game Mode MUST stay enabled (auto-detected)  
> 🔒 **High-Risk tweaks** → User confirmation required  
> 💾 **Registry backup** → Automatic before changes  
> ⚡ Competitive vs AAA tuning supported  

---

## 🐧 6. Linux ISO Downloader
> **Category:** Downloads  
> **Admin:** ❌ No  

### ✔ What it does
- Download latest ISOs
- Parallel downloads (1–5)
- SHA256 verification
- Auto mirror fallback

---

### 📦 Supported Distros

| Distro | Type | Hash |
|--------|------|------|
| Ubuntu | Desktop + Server | ✅ |
| Debian | Netinst | ✅ |
| Fedora | Workstation | ❌ |
| Arch | Monthly | ❌ |
| CachyOS | Desktop | ❌ |
| Pop!_OS | Intel/NVIDIA | ✅ |

---

### ✨ Features
- Progress bar
- Resume / skip existing files
- Activity log
- Mirror failover

📁 **Default Output**
```
D:\ISOs
```

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

---

### ✔ Best Practices
- Inline XAML only
- Logging with timestamps
- Try/Catch everywhere
- Use theme brushes

---

# 🧯 Troubleshooting

| Problem | Solution |
|--------|---------|
| PowerShell 7 missing | Install from aka.ms/powershell |
| Command not found | Restart terminal |
| ExecutionPolicy error | Set RemoteSigned |
| Modules missing | Check `/modules` folder |
| Gaming tweaks missing | Run as Admin |

---

# 🧩 Compatibility

| Component | Requirement |
|----------|------------|
| PowerShell | 7.0+ |
| Windows | 10 / 11 |
| WPF | Required |
| Display | 1024×600+ |


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



# 📜 License
MIT

---

# 👤 Author
**ReAlNoMo**  
Version 1.2 • April 2026
