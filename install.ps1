#Requires -Version 7.0
<#
.SYNOPSIS
    PowerTools Suite Installer
.DESCRIPTION
    Downloads and installs PowerTools Suite from GitHub.
    Launches main application after installation.
.NOTES
    Author  : ReAlNoMo
    Version : 1.1
#>

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Msg, [string]$Type = "INFO")
    $tag = switch ($Type) {
        "OK"   { "[OK]  " }
        "WARN" { "[WARN]" }
        "ERR"  { "[ERR] " }
        default { "[INFO]" }
    }
    Write-Host "$tag $Msg" -ForegroundColor $(
        if ($Type -eq "OK")   { "Green" }
        elseif ($Type -eq "WARN") { "Yellow" }
        elseif ($Type -eq "ERR")  { "Red" }
        else { "Cyan" }
    )
}

# Paths
$InstallPath = Join-Path $env:LOCALAPPDATA "PowerTools-Suite"
$TempPath    = Join-Path $env:TEMP "PowerTools-Suite-Install-$([System.Guid]::NewGuid())"
$GitHubRaw   = "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main"

Write-Log "PowerTools Suite Installer" "INFO"
Write-Log "Target: $InstallPath" "INFO"
Write-Log "Using temp: $TempPath" "INFO"

# Create temp directory
if (-not (Test-Path $TempPath)) {
    New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
}

try {
    # Download core files
    Write-Log "Downloading core files..." "INFO"
    $coreFiles = @("PS-PowerToolsSuite.ps1", "README.md")
    foreach ($file in $coreFiles) {
        Write-Host "Downloading $file... " -NoNewline
        $url  = "$GitHubRaw/$file"
        $dest = Join-Path $TempPath $file
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url, $dest)
            Write-Host "done"
        }
        catch {
            Write-Log "Failed to download $file`: $_" "ERR"
            throw
        }
    }

    # Download modules
    Write-Log "Downloading modules..." "INFO"
    $modulePath = Join-Path $TempPath "modules"
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
    
    $modules = @(
        "01-HashVerifier.ps1",
        "02-ExplorerViewNormalizer.ps1",
        "03-HardwareInventory.ps1",
        "04-SandboxieBrowserLauncher.ps1",
        "05-GamingOptimizer.ps1",
        "06-LinuxISODownloader.ps1"
    )
    foreach ($mod in $modules) {
        Write-Host "Downloading $mod... " -NoNewline
        $url  = "$GitHubRaw/modules/$mod"
        $dest = Join-Path $modulePath $mod
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url, $dest)
            Write-Host "done"
        }
        catch {
            Write-Log "Failed to download $mod`: $_" "ERR"
            throw
        }
    }

    # Install to target
    Write-Log "Installing to $InstallPath..." "INFO"
    if (Test-Path $InstallPath) {
        Write-Log "Removing existing installation..." "WARN"
        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Copy-Item -Path $TempPath -Destination $InstallPath -Recurse -Force
    Write-Log "Installation complete" "OK"

    # Cleanup temp
    Write-Log "Cleaning up..." "INFO"
    Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue

    # Launch
    Write-Log "Starting launcher..." "INFO"
    $launcherPath = Join-Path $InstallPath "PS-PowerToolsSuite.ps1"
    Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$launcherPath`""
    Write-Log "Launcher started" "OK"

    Start-Sleep -Seconds 3
    exit 0
}
catch {
    Write-Log "Installation failed: $_" "ERR"
    Start-Sleep -Seconds 2
    exit 1
}
