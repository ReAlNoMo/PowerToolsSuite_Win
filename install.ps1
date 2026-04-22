#Requires -Version 7.0
<#
.SYNOPSIS
    PowerTools Suite Installer
.DESCRIPTION
    Downloads PowerTools Suite from GitHub and installs to user's system.
    Supports both local run and remote execution via irm | iex.
.EXAMPLE
    irm "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/install.ps1" | iex
#>

param(
    [string]$InstallPath = "$env:USERPROFILE\AppData\Local\PowerTools-Suite"
)

# ===========================================================================
# CONFIG
# ===========================================================================
$GitHubRepo = "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main"
$TempDir = Join-Path $env:TEMP "PowerTools-Suite-Install-$([datetime]::Now.Ticks)"
$ModulesUrl = @(
    "01-HashVerifier"
    "02-ExplorerViewNormalizer"
    "03-HardwareInventory"
    "04-SandboxieBrowserLauncher"
    "05-GamingOptimizer"
    "06-LinuxISODownloader"
)
$CoreFiles = @(
    "PS-PowerToolsSuite.ps1"
    "Install-Shortcut.ps1"
    "README.md"
)

# ===========================================================================
# FUNCTIONS
# ===========================================================================
function Write-Status {
    param([string]$Msg, [string]$Type = "INFO")
    $prefix = switch ($Type) {
        "OK"   { "[OK]   " }
        "FAIL" { "[FAIL] " }
        "WARN" { "[WARN] " }
        default { "[INFO] " }
    }
    Write-Host "$prefix$Msg" -ForegroundColor $(
        if ($Type -eq "OK") { "Green" }
        elseif ($Type -eq "FAIL") { "Red" }
        elseif ($Type -eq "WARN") { "Yellow" }
        else { "Cyan" }
    )
}

function Download-File {
    param([string]$Url, [string]$OutPath)
    try {
        Write-Host -NoNewline "Downloading $(Split-Path $OutPath -Leaf)... "
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($Url, $OutPath)
        Write-Host "done" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "failed" -ForegroundColor Red
        Write-Status "Error: $_" "FAIL"
        return $false
    }
}

# ===========================================================================
# MAIN
# ===========================================================================
Clear-Host
Write-Status "PowerTools Suite Installer" "INFO"
Write-Status "Target: $InstallPath" "INFO"
Write-Host ""

# Create temp dir
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}
Write-Status "Using temp: $TempDir" "INFO"

# Download core files
Write-Host ""
Write-Status "Downloading core files..." "INFO"
$allDownloaded = $true
foreach ($file in $CoreFiles) {
    $url = "$GitHubRepo/$file"
    $out = Join-Path $TempDir $file
    if (-not (Download-File $url $out)) {
        $allDownloaded = $false
    }
}

# Create modules dir in temp
$tempModulesDir = Join-Path $TempDir "modules"
New-Item -ItemType Directory -Path $tempModulesDir -Force | Out-Null

# Download modules
Write-Host ""
Write-Status "Downloading modules..." "INFO"
foreach ($mod in $ModulesUrl) {
    $url = "$GitHubRepo/modules/$mod.ps1"
    $out = Join-Path $tempModulesDir "$mod.ps1"
    if (-not (Download-File $url $out)) {
        $allDownloaded = $false
    }
}

if (-not $allDownloaded) {
    Write-Host ""
    Write-Status "Download failed. Check your internet connection." "FAIL"
    exit 1
}

# Copy to install path
Write-Host ""
Write-Status "Installing to $InstallPath..." "INFO"
if (Test-Path $InstallPath) {
    Write-Status "Removing existing installation..." "WARN"
    Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
}

try {
    Copy-Item -Path $TempDir -Destination $InstallPath -Recurse -Force
    Write-Status "Installation complete" "OK"
} catch {
    Write-Status "Copy failed: $_" "FAIL"
    exit 1
}

# Cleanup
Write-Status "Cleaning up..." "INFO"
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# Register profile shortcut
Write-Host ""
Write-Status "Registering PowerShell command..." "INFO"

$profileScriptPath = Join-Path $InstallPath "Install-Shortcut.ps1"
if (Test-Path $profileScriptPath) {
    try {
        & $profileScriptPath
        Write-Status "Profile shortcut registered" "OK"
    } catch {
        Write-Status "Profile registration failed (non-fatal): $_" "WARN"
    }
} else {
    Write-Status "Install-Shortcut.ps1 not found (non-fatal)" "WARN"
}

# Offer to launch
Write-Host ""
Read-Host "Installation complete. Press ENTER to launch PowerTools Suite"

$launcherPath = Join-Path $InstallPath "PS-PowerToolsSuite.ps1"
if (Test-Path $launcherPath) {
    & $launcherPath
} else {
    Write-Status "Launcher not found" "FAIL"
    exit 1
}
