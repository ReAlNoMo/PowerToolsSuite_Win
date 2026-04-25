#Requires -Version 7.0
<#
.SYNOPSIS
    PowerTools Suite Installer
.DESCRIPTION
    Downloads and installs PowerTools Suite from GitHub.
    Launches main application after installation.
.NOTES
    Author  : ReAlNoMo
    Version : 1.2
#>

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"   # Faster Invoke-WebRequest

# ===========================================================================
# CONFIG
# ===========================================================================
$InstallPath = Join-Path $env:LOCALAPPDATA "PowerTools-Suite"
$TempPath    = Join-Path $env:TEMP "PTS-Install-$([System.Guid]::NewGuid().ToString('N'))"
$GitHubRaw   = "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main"
$MaxRetries  = 3

$CoreFiles = @(
    "PS-PowerToolsSuite.ps1",
    "README.md"
)

$ModuleFiles = @(
    "01-HashVerifier.ps1",
    "02-ExplorerViewNormalizer.ps1",
    "03-HardwareInventory.ps1",
    "04-SandboxieBrowserLauncher.ps1",
    "05-GamingOptimizer.ps1",
    "06-LinuxISODownloader.ps1"
)

# ===========================================================================
# LOGGING
# ===========================================================================
function Write-Log {
    param(
        [string]$Msg,
        [ValidateSet("INFO","OK","WARN","ERR")]
        [string]$Type = "INFO"
    )
    $tag   = switch ($Type) { "OK"{"[OK]  "} "WARN"{"[WARN]"} "ERR"{"[ERR] "} default{"[INFO]"} }
    $color = switch ($Type) { "OK"{"Green"} "WARN"{"Yellow"} "ERR"{"Red"} default{"Cyan"} }
    Write-Host "$tag $Msg" -ForegroundColor $color
}

# ===========================================================================
# DOWNLOAD WITH RETRY
# ===========================================================================
function Invoke-DownloadFile {
    param(
        [string]$Url,
        [string]$Destination
    )

    $attempt = 0
    $lastErr  = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -TimeoutSec 30
            return
        }
        catch {
            $lastErr = $_
            if ($attempt -lt $MaxRetries) {
                Write-Log "Attempt $attempt failed. Retrying..." "WARN"
                Start-Sleep -Seconds 2
            }
        }
    }

    throw "Download failed after $MaxRetries attempts: $Url`n$lastErr"
}

# ===========================================================================
# VERIFY FILE EXISTS AND HAS CONTENT
# ===========================================================================
function Test-FileValid {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    return (Get-Item $Path).Length -gt 0
}

# ===========================================================================
# MAIN
# ===========================================================================
Write-Host ""
Write-Log "PowerTools Suite Installer v1.2" "INFO"
Write-Log "Install target : $InstallPath"    "INFO"
Write-Log "Temp work dir  : $TempPath"       "INFO"
Write-Host ""

# Check internet connectivity
Write-Log "Checking connectivity..." "INFO"
try {
    $null = Invoke-WebRequest -Uri "https://raw.githubusercontent.com" -UseBasicParsing -TimeoutSec 10 -Method Head
    Write-Log "GitHub reachable" "OK"
}
catch {
    Write-Log "Cannot reach GitHub. Check internet connection." "ERR"
    Start-Sleep -Seconds 3
    exit 1
}

# Create temp directory
try {
    New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TempPath "modules") -Force | Out-Null
}
catch {
    Write-Log "Failed to create temp directory: $_" "ERR"
    exit 1
}

try {
    # -----------------------------------------------------------------------
    # DOWNLOAD CORE FILES
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Log "Downloading core files..." "INFO"

    foreach ($file in $CoreFiles) {
        $url  = "$GitHubRaw/$file"
        $dest = Join-Path $TempPath $file
        Write-Host "  Downloading $file... " -NoNewline -ForegroundColor Gray

        try {
            Invoke-DownloadFile -Url $url -Destination $dest
            if (-not (Test-FileValid $dest)) { throw "File empty or missing after download" }
            Write-Host "OK" -ForegroundColor Green
        }
        catch {
            Write-Host "FAIL" -ForegroundColor Red
            Write-Log "Error: $_" "ERR"
            throw "Core file download failed: $file"
        }
    }

    # -----------------------------------------------------------------------
    # DOWNLOAD MODULE FILES
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Log "Downloading modules..." "INFO"

    foreach ($mod in $ModuleFiles) {
        $url  = "$GitHubRaw/modules/$mod"
        $dest = Join-Path $TempPath "modules\$mod"
        Write-Host "  Downloading $mod... " -NoNewline -ForegroundColor Gray

        try {
            Invoke-DownloadFile -Url $url -Destination $dest
            if (-not (Test-FileValid $dest)) { throw "File empty or missing after download" }
            Write-Host "OK" -ForegroundColor Green
        }
        catch {
            Write-Host "FAIL" -ForegroundColor Red
            Write-Log "Error: $_" "ERR"
            throw "Module download failed: $mod"
        }
    }

    # -----------------------------------------------------------------------
    # VERIFY LAUNCHER EXISTS IN TEMP
    # -----------------------------------------------------------------------
    $tempLauncher = Join-Path $TempPath "PS-PowerToolsSuite.ps1"
    if (-not (Test-FileValid $tempLauncher)) {
        throw "Main launcher missing from temp after download. Aborting install."
    }

    # -----------------------------------------------------------------------
    # REMOVE EXISTING INSTALLATION
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Log "Installing to: $InstallPath" "INFO"

    if (Test-Path $InstallPath) {
        Write-Log "Removing existing installation..." "WARN"
        try {
            Remove-Item -Path $InstallPath -Recurse -Force
            Write-Log "Existing install removed" "OK"
        }
        catch {
            Write-Log "Could not remove existing install: $_" "WARN"
            Write-Log "Continuing anyway (files will be overwritten)" "WARN"
        }
    }

    # -----------------------------------------------------------------------
    # COPY TO INSTALL PATH
    # -----------------------------------------------------------------------
    try {
        Copy-Item -Path $TempPath -Destination $InstallPath -Recurse -Force
        Write-Log "Files copied to install path" "OK"
    }
    catch {
        throw "Failed to copy files to install path: $_"
    }

    # -----------------------------------------------------------------------
    # POST-INSTALL VERIFY
    # -----------------------------------------------------------------------
    $finalLauncher = Join-Path $InstallPath "PS-PowerToolsSuite.ps1"
    if (-not (Test-FileValid $finalLauncher)) {
        throw "Post-install verification failed. Launcher missing at: $finalLauncher"
    }
    Write-Log "Installation verified" "OK"

    # -----------------------------------------------------------------------
    # CLEANUP TEMP
    # -----------------------------------------------------------------------
    try {
        Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Temp files cleaned up" "OK"
    }
    catch {
        Write-Log "Temp cleanup failed (non-critical): $_" "WARN"
    }

    # -----------------------------------------------------------------------
    # LAUNCH
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Log "Launching PowerTools Suite..." "INFO"

    try {
        Start-Process -FilePath "pwsh.exe" `
                      -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$finalLauncher`""
        Write-Log "Launcher started successfully" "OK"
    }
    catch {
        Write-Log "Failed to launch: $_" "ERR"
        Write-Log "Run manually: pwsh -File `"$finalLauncher`"" "WARN"
    }

    Write-Host ""
    Write-Log "Done." "OK"
    Start-Sleep -Seconds 3
    exit 0
}
catch {
    Write-Host ""
    Write-Log "Installation failed: $_" "ERR"

    # Cleanup temp on failure
    if (Test-Path $TempPath) {
        Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Temp files removed" "INFO"
    Start-Sleep -Seconds 4
    exit 1
}
