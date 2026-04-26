#Requires -Version 7.0
<#
.SYNOPSIS
    PowerTools Suite Installer
.DESCRIPTION
    Downloads and installs PowerTools Suite from GitHub.
    Dynamically discovers all modules and assets via GitHub API.
    Launches main application after installation.
.NOTES
    Author  : ReAlNoMo
    Version : 1.3
#>

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"

# ===========================================================================
# CONFIG
# ===========================================================================
$InstallPath  = Join-Path $env:LOCALAPPDATA "PowerTools-Suite"
$TempPath     = Join-Path $env:TEMP "PTS-Install-$([System.Guid]::NewGuid().ToString('N'))"
$GitHubRaw    = "https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main"
$GitHubAPI    = "https://api.github.com/repos/ReAlNoMo/PowerToolsSuite_Win/contents"
$MaxRetries   = 3

$CoreFiles = @(
    "PS-PowerToolsSuite.ps1",
    "README.md"
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
# GITHUB API: GET FILE LIST FOR A FOLDER
# ===========================================================================
function Get-GitHubFileList {
    param(
        [string]$FolderPath
    )
    try {
        $apiUrl  = "$GitHubAPI/$FolderPath"
        $headers = @{ "User-Agent" = "PowerTools-Suite-Installer" }
        $resp    = Invoke-WebRequest -Uri $apiUrl -Headers $headers -UseBasicParsing -TimeoutSec 20
        $items   = ($resp.Content | ConvertFrom-Json)
        return ($items | Where-Object { $_.type -eq "file" } | Select-Object -ExpandProperty name)
    }
    catch {
        Write-Log "GitHub API call failed for '$FolderPath': $_" "WARN"
        return @()
    }
}

# ===========================================================================
# VERIFY FILE
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
Write-Log "PowerTools Suite Installer v1.3" "INFO"
Write-Log "Install target : $InstallPath"   "INFO"
Write-Log "Temp work dir  : $TempPath"      "INFO"
Write-Host ""

# Check connectivity
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

# Create temp directories
try {
    New-Item -ItemType Directory -Path $TempPath                          -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TempPath "modules")    -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TempPath "logo")       -Force | Out-Null
}
catch {
    Write-Log "Failed to create temp directory: $_" "ERR"
    exit 1
}

try {
    # -----------------------------------------------------------------------
    # DISCOVER MODULES VIA GITHUB API
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Log "Discovering modules from GitHub..." "INFO"
    $ModuleFiles = Get-GitHubFileList -FolderPath "modules"
    $ModuleFiles = $ModuleFiles | Where-Object { $_ -match "\.ps1$" }

    if ($ModuleFiles.Count -eq 0) {
        Write-Log "No modules found via API. Check repo or API rate limit." "ERR"
        throw "Module discovery returned 0 files."
    }
    Write-Log "Found $($ModuleFiles.Count) module(s): $($ModuleFiles -join ', ')" "OK"

    # -----------------------------------------------------------------------
    # DISCOVER LOGO FILES VIA GITHUB API
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Log "Discovering logo assets from GitHub..." "INFO"
    $LogoFiles = Get-GitHubFileList -FolderPath "logo"

    if ($LogoFiles.Count -eq 0) {
        Write-Log "No logo files found. Logo folder may be empty." "WARN"
    }
    else {
        Write-Log "Found $($LogoFiles.Count) logo file(s): $($LogoFiles -join ', ')" "OK"
    }

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
    # DOWNLOAD LOGO FILES
    # -----------------------------------------------------------------------
    if ($LogoFiles.Count -gt 0) {
        Write-Host ""
        Write-Log "Downloading logo assets..." "INFO"

        foreach ($logo in $LogoFiles) {
            $url  = "$GitHubRaw/logo/$logo"
            $dest = Join-Path $TempPath "logo\$logo"
            Write-Host "  Downloading $logo... " -NoNewline -ForegroundColor Gray
            try {
                Invoke-DownloadFile -Url $url -Destination $dest
                if (-not (Test-FileValid $dest)) { throw "File empty or missing after download" }
                Write-Host "OK" -ForegroundColor Green
            }
            catch {
                Write-Host "FAIL" -ForegroundColor Red
                Write-Log "Logo download failed (non-critical): $logo - $_" "WARN"
            }
        }
    }

    # -----------------------------------------------------------------------
    # VERIFY LAUNCHER IN TEMP
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

        Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | Where-Object {
            $_.MainWindowTitle -like "*PowerTools*"
        } | ForEach-Object {
            Write-Log "Stopping running instance (PID $($_.Id))..." "WARN"
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 1

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
    # SUMMARY
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Log "Installed $($ModuleFiles.Count) module(s)" "OK"
    Write-Log "Installed $($LogoFiles.Count) logo file(s)" "OK"

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

    if (Test-Path $TempPath) {
        Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Temp files removed" "INFO"
    Start-Sleep -Seconds 4
    exit 1
}
