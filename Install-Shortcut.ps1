#Requires -Version 5.1
<#
.SYNOPSIS
    Installs a PowerShell profile shortcut for PowerTools Suite.
.DESCRIPTION
    Adds a function 'PS-PowerToolsSuite' to your PowerShell profile so you can
    launch the Suite from any PowerShell window by typing:  PS-PowerToolsSuite
    Run this script ONCE after placing the Suite in its final folder.
#>

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainScript = Join-Path $scriptRoot "PS-PowerToolsSuite.ps1"

if (-not (Test-Path $mainScript)) {
    Write-Host "[FAIL] PS-PowerToolsSuite.ps1 not found in: $scriptRoot" -ForegroundColor Red
    Write-Host "       Place this installer next to the main launcher script." -ForegroundColor Red
    exit 1
}

$profilePath = $PROFILE
$profileDir  = Split-Path $profilePath
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$startTag = "# >>> POWERTOOLS SUITE SHORTCUT START >>>"
$endTag   = "# <<< POWERTOOLS SUITE SHORTCUT END <<<"

$block  = @()
$block += $startTag
$block += "function PS-PowerToolsSuite {"
$block += "    Start-Process powershell -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File',`"$mainScript`""
$block += "}"
$block += $endTag

$content = Get-Content $profilePath -ErrorAction SilentlyContinue
if ($content -match [regex]::Escape($startTag)) {
    $inside = $false
    $filtered = foreach ($line in $content) {
        if ($line -eq $startTag) { $inside = $true; continue }
        if ($line -eq $endTag)   { $inside = $false; continue }
        if (-not $inside) { $line }
    }
    $content = $filtered
}

$content += ""
$content += $block
$content | Set-Content -Path $profilePath -Encoding UTF8

Write-Host ""
Write-Host "[OK] Shortcut installed." -ForegroundColor Green
Write-Host ""
Write-Host "Profile updated:" -ForegroundColor Cyan
Write-Host "   $profilePath" -ForegroundColor Gray
Write-Host ""
Write-Host "Launch PowerTools Suite from any PowerShell window with:" -ForegroundColor Cyan
Write-Host "   PS-PowerToolsSuite" -ForegroundColor Yellow
Write-Host ""
Write-Host "Open a NEW PowerShell window for changes to take effect." -ForegroundColor DarkGray
Write-Host ""