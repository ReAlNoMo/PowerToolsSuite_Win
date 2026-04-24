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
- Launch Chrome / Firefox sandboxed
- Incognito / Private mode
- Detect Sandboxie + browsers
- Configurable sandbox

⚠️ **Requirements**
- Sandboxie-Plus installed
- Chrome or Firefox

💡 **Use case**
> Safely browse untrusted websites or test malware

---

## 🎮 5. Windows 11 Gaming Optimizer
> **Category:** Performance  
> **Admin:** ⚠️ Yes  

> 🚀 Applies **16 performance tweaks** (idempotent)

---

### 🔥 High Impact Tweaks

| Tweak | Effect | Reboot | Risk |
|------|--------|--------|------|
| HVCI Disable | 🚀 Up to +25% FPS | ✅ Yes | 🔴 High |
| GPU Scheduling | ⏱️ -2ms latency | ✅ Yes | 🟢 Low |
| Win32Priority | 🎯 Better frame consistency | ❌ No | 🟢 Low |

---

### ⚙️ System Tweaks Overview

<details>
<summary>🔽 Show all tweaks</summary>

#### 🧠 CPU & Scheduling
- Win32PrioritySeparation
- SystemResponsiveness
- NetworkThrottling disabled

#### 🎨 Visual Effects
- Disable transparency
- Disable animations

#### 🎮 Gaming Features
- Game Mode
- GPU Scheduling

#### 🔒 Privacy
- Disable search history
- Disable cross-device sharing

</details>

---

### 🧠 UI Features
- ✅ Checkbox selection
- 🔍 Status detection (APPLIED / MISSING)
- 🔄 Re-scan button
- 🪵 Activity log
- 🔁 Safe re-run (idempotent)

---

### ⚠️ Important Notes

> 🔴 **Reboot required** for some tweaks  
> 🧠 AMD X3D CPUs → Game Mode MUST stay enabled  
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

# 📜 License
MIT

---

# 👤 Author
**ReAlNoMo**  
Version 1.1 • April 2026
