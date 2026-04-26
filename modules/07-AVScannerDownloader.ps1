<#
Robust patch for your "AV Scanner Downloader" module.
Date: 2026-04-26

How to apply:
1) In your module script, set a safer default destination after controls are resolved.
2) Replace function Global:AV-GetScannerList with the block below.
3) Replace $Global:AV_dlScript with the block below.
4) In StartBtn.Add_Click worker task, replace the runspace result loop with the block below.
#>

########################################
# 1) Safer default destination
########################################
# Paste this right after you assign $Global:AV_destBox:
#
# $defaultDest = Join-Path $env:USERPROFILE "Downloads\AVScanners"
# if ([string]::IsNullOrWhiteSpace($Global:AV_destBox.Text) -or $Global:AV_destBox.Text -eq "C:\AVScanners") {
#     $Global:AV_destBox.Text = $defaultDest
# }


########################################
# 2) Replace AV-GetScannerList
########################################
function Global:AV-GetScannerList {
    param([string]$Dest)

    $list = @()

    if ($Global:AV_cbEEK.IsChecked) {
        $list += @{
            Name          = "Emsisoft Emergency Kit"
            FileName      = "EmsisoftEmergencyKit.exe"
            Url           = "https://dl.emsisoft.com/EmsisoftEmergencyKit.exe"
            LandingPageUrl= "https://www.emsisoft.com/en/emergency-kit/"
            AllowedHosts  = @("dl.emsisoft.com","www.emsisoft.com","emsisoft.com")
            OutFile       = Join-Path $Dest "EmsisoftEmergencyKit.exe"
        }
    }

    if ($Global:AV_cbKVRT.IsChecked) {
        $list += @{
            Name          = "Kaspersky KVRT"
            FileName      = "KVRT.exe"
            Url           = "https://devapps.kaspersky.com/mcc/static/kvrt/en-US/vital-product/KVRT.exe"
            FallbackUrls  = @(
                "https://devbuilds.s.kaspersky-labs.com/devbuilds/KVRT/latest/full/KVRT.exe"
            )
            LandingPageUrl= "https://www.kaspersky.com/free-virus-scan"
            AllowedHosts  = @("devapps.kaspersky.com","devbuilds.s.kaspersky-labs.com","www.kaspersky.com","kaspersky.com")
            OutFile       = Join-Path $Dest "KVRT.exe"
        }
    }

    if ($Global:AV_cbAdwCleaner.IsChecked) {
        $list += @{
            Name          = "Malwarebytes AdwCleaner"
            FileName      = "adwcleaner_latest.exe"
            Url           = "https://adwcleaner.malwarebytes.com/adwcleaner/adwcleaner_latest.exe"
            LandingPageUrl= "https://www.malwarebytes.com/adwcleaner"
            AllowedHosts  = @("adwcleaner.malwarebytes.com","www.malwarebytes.com","malwarebytes.com")
            OutFile       = Join-Path $Dest "adwcleaner_latest.exe"
        }
    }

    if ($Global:AV_cbHouseCall.IsChecked) {
        $list += @{
            Name          = "Trend Micro HouseCall"
            FileName      = "HousecallLauncher64.exe"
            Url           = "https://housecall.trendmicro.com/housecall/downloads/HousecallLauncher64.exe"
            FallbackUrls  = @(
                "https://us.shop.trendmicro.com/en_us/products/house-call.asp",
                "https://shop.trendmicro.com/en_us/products/house-call.asp",
                "https://www.trendmicro.com/en_us/forHome/products/housecall.html"
            )
            LandingPageUrl= "https://www.trendmicro.com/en_us/forHome/products/housecall.html"
            AllowedHosts  = @("housecall.trendmicro.com","shop.trendmicro.com","us.shop.trendmicro.com","www.trendmicro.com","trendmicro.com")
            OutFile       = Join-Path $Dest "HousecallLauncher64.exe"
        }
    }

    return $list
}


########################################
# 3) Replace $Global:AV_dlScript
########################################
$Global:AV_dlScript = {
    param(
        [hashtable]$Job,
        [System.Collections.Concurrent.ConcurrentQueue[object]]$Queue,
        [System.Threading.CancellationToken]$CancelToken
    )

    function Q-Log {
        param([string]$Msg, [string]$Tag = "INFO")
        $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = $Msg; Tag = $Tag })
    }

    function New-Req {
        param([string]$Url)
        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.Method = "GET"
        $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerTools-Suite-AVDownloader/2.0"
        $req.Timeout = 30000
        $req.ReadWriteTimeout = 30000
        $req.AllowAutoRedirect = $true
        $req.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
        $req.Accept = "application/octet-stream,application/x-msdownload,application/vnd.microsoft.portable-executable,text/html,*/*"
        return $req
    }

    function Get-StringResponse {
        param([string]$Url)

        $resp = $null
        $stream = $null
        $reader = $null
        try {
            $resp = (New-Req -Url $Url).GetResponse()
            $stream = $resp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            return $reader.ReadToEnd()
        } finally {
            if ($null -ne $reader) { try { $reader.Close() } catch {} }
            if ($null -ne $stream) { try { $stream.Close() } catch {} }
            if ($null -ne $resp)   { try { $resp.Close() } catch {} }
        }
    }

    function Add-CandidateUrl {
        param(
            [System.Collections.Generic.List[string]]$List,
            [string]$Url
        )
        if ([string]::IsNullOrWhiteSpace($Url)) { return }
        if ($List -notcontains $Url) { [void]$List.Add($Url) }
    }

    function Is-AllowedHost {
        param([string]$Url, [string[]]$AllowedHosts)
        try {
            $u = [System.Uri]$Url
            if (-not $AllowedHosts -or $AllowedHosts.Count -eq 0) { return $true }
            foreach ($h in $AllowedHosts) {
                if ($u.Host -eq $h -or $u.Host.EndsWith(".$h")) { return $true }
            }
            return $false
        } catch {
            return $false
        }
    }

    function Get-ExeLinksFromPage {
        param(
            [string]$PageUrl,
            [string[]]$AllowedHosts
        )

        $out = [System.Collections.Generic.List[string]]::new()
        try {
            $html = Get-StringResponse -Url $PageUrl
            $baseUri = [System.Uri]$PageUrl

            $rx = 'https?://[^"''\s>]+|href\s*=\s*["'']([^"''#]+)["'']|src\s*=\s*["'']([^"''#]+)["'']'
            $m = [regex]::Matches($html, $rx, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            foreach ($mm in $m) {
                $candidate = $null
                if ($mm.Value -match '^https?://') {
                    $candidate = $mm.Value
                } elseif ($mm.Groups.Count -gt 1 -and $mm.Groups[1].Value) {
                    try { $candidate = ([System.Uri]::new($baseUri, $mm.Groups[1].Value)).AbsoluteUri } catch {}
                } elseif ($mm.Groups.Count -gt 2 -and $mm.Groups[2].Value) {
                    try { $candidate = ([System.Uri]::new($baseUri, $mm.Groups[2].Value)).AbsoluteUri } catch {}
                }

                if (-not $candidate) { continue }
                if (-not (Is-AllowedHost -Url $candidate -AllowedHosts $AllowedHosts)) { continue }

                if ($candidate -match '\.exe($|\?)' -or
                    $candidate -match 'adwcleaner' -or
                    $candidate -match 'kvrt' -or
                    $candidate -match 'housecall' -or
                    $candidate -match 'emergencykit') {
                    Add-CandidateUrl -List $out -Url $candidate
                }
            }
        } catch {
            # page parse failure is non-fatal
        }
        return $out
    }

    function Test-DownloadedFile {
        param([string]$Path)

        if (-not (Test-Path $Path)) { throw "Temporary file was not created." }
        $fi = Get-Item $Path
        if ($fi.Length -lt 200KB) { throw "Downloaded file too small ($($fi.Length) bytes)." }

        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $b1 = $fs.ReadByte()
            $b2 = $fs.ReadByte()
            if ($b1 -ne 0x4D -or $b2 -ne 0x5A) {
                throw "Downloaded file is not a PE executable (MZ signature missing)."
            }
        } finally {
            $fs.Close()
        }
    }

    # enforce modern TLS where available
    try {
        $sec = [System.Net.SecurityProtocolType]::Tls12
        if ([enum]::GetNames([System.Net.SecurityProtocolType]) -contains "Tls13") {
            $sec = $sec -bor [System.Net.SecurityProtocolType]::Tls13
        }
        [System.Net.ServicePointManager]::SecurityProtocol = $sec
    } catch {}

    $result = [PSCustomObject]@{
        Success = $false
        Name    = $Job.Name
        Message = ""
        UrlUsed = ""
    }

    $name = $Job.Name
    $outFile = $Job.OutFile
    $tmpFile = "$outFile.$([guid]::NewGuid().ToString('N')).tmp"

    if ($CancelToken.IsCancellationRequested) {
        $result.Message = "Cancelled"
        return $result
    }

    Q-Log "Starting: $name" "INFO"

    if (Test-Path $outFile) {
        $age = (Get-Date) - (Get-Item $outFile).LastWriteTime
        if ($age.TotalHours -lt 24) {
            Q-Log "Skipped (fresh copy exists): $($Job.FileName)" "WARN"
            $result.Success = $true
            $result.Message = "Skipped"
            return $result
        }
    }

    $urlsToTry = [System.Collections.Generic.List[string]]::new()
    Add-CandidateUrl -List $urlsToTry -Url $Job.Url

    if ($Job.ContainsKey("FallbackUrl") -and $Job.FallbackUrl) {
        Add-CandidateUrl -List $urlsToTry -Url $Job.FallbackUrl
    }
    if ($Job.ContainsKey("FallbackUrls") -and $Job.FallbackUrls) {
        foreach ($u in $Job.FallbackUrls) { Add-CandidateUrl -List $urlsToTry -Url $u }
    }
    if ($Job.ContainsKey("LandingPageUrl") -and $Job.LandingPageUrl) {
        $parsed = Get-ExeLinksFromPage -PageUrl $Job.LandingPageUrl -AllowedHosts $Job.AllowedHosts
        foreach ($u in $parsed) { Add-CandidateUrl -List $urlsToTry -Url $u }
    }

    foreach ($tryUrl in $urlsToTry) {
        if ($CancelToken.IsCancellationRequested) { break }

        $resp = $null
        $stream = $null
        $fs = $null
        try {
            Q-Log "${name}: trying $tryUrl" "INFO"

            $resp = (New-Req -Url $tryUrl).GetResponse()
            $contentType = "$($resp.ContentType)".ToLowerInvariant()
            $finalUrl = ""
            try { $finalUrl = $resp.ResponseUri.AbsoluteUri } catch {}

            $cd = ""
            try { $cd = "$($resp.Headers['Content-Disposition'])".ToLowerInvariant() } catch {}

            $looksBinary = $false
            if ($contentType -match 'application/octet-stream|application/x-msdownload|application/vnd.microsoft.portable-executable') { $looksBinary = $true }
            if ($finalUrl -match '\.exe($|\?)') { $looksBinary = $true }
            if ($cd -match '\.exe') { $looksBinary = $true }

            if (-not $looksBinary) {
                throw "Non-binary response. Content-Type='$contentType' FinalUrl='$finalUrl'"
            }

            $total = $resp.ContentLength
            $stream = $resp.GetResponseStream()
            $fs = [System.IO.File]::Create($tmpFile)
            $buf = New-Object byte[] 65536
            $downloaded = 0L
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $lastReport = 0L

            while (-not $CancelToken.IsCancellationRequested) {
                $read = $stream.Read($buf, 0, $buf.Length)
                if ($read -le 0) { break }
                $fs.Write($buf, 0, $read)
                $downloaded += $read

                $now = $sw.ElapsedMilliseconds
                if (($now - $lastReport) -ge 500) {
                    $lastReport = $now
                    $speed = if ($sw.Elapsed.TotalSeconds -gt 0) {
                        [math]::Round(($downloaded / 1MB) / $sw.Elapsed.TotalSeconds, 1)
                    } else { 0 }
                    $dlMB = [math]::Round($downloaded / 1MB, 1)
                    $totMB = if ($total -gt 0) { [math]::Round($total / 1MB, 1) } else { "?" }
                    $eta = if ($total -gt 0 -and $speed -gt 0) {
                        "$([math]::Round(($total - $downloaded) / 1MB / $speed))s"
                    } else { "..." }
                    Q-Log "$name  |  ${dlMB}MB / ${totMB}MB  |  ${speed} MB/s  |  ETA: $eta" "INFO"
                }
            }

            $fs.Close(); $fs = $null
            $stream.Close(); $stream = $null
            $resp.Close(); $resp = $null

            if ($CancelToken.IsCancellationRequested) {
                if (Test-Path $tmpFile) { Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue }
                $result.Message = "Cancelled"
                return $result
            }

            Test-DownloadedFile -Path $tmpFile
            Move-Item -LiteralPath $tmpFile -Destination $outFile -Force

            $sizeMB = [math]::Round((Get-Item $outFile).Length / 1MB, 1)
            Q-Log "Downloaded: $($Job.FileName) (${sizeMB} MB) via $tryUrl" "OK"

            $result.Success = $true
            $result.Message = "Done"
            $result.UrlUsed = $tryUrl
            return $result
        } catch {
            if ($null -ne $fs) { try { $fs.Close() } catch {} }
            if ($null -ne $stream) { try { $stream.Close() } catch {} }
            if ($null -ne $resp) { try { $resp.Close() } catch {} }
            if (Test-Path $tmpFile) { Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue }

            $errMsg = $_.Exception.Message
            Q-Log "${name}: URL failed ($tryUrl) - $errMsg" "WARN"
        }
    }

    Q-Log "FAILED: $name - all URLs exhausted." "FAIL"
    $result.Message = "All URLs failed"
    return $result
}


########################################
# 4) Replace runspace result handling in StartBtn click
########################################
# Replace only the Task.Run body from "$maxThreads = ..." down to queue final DONE/ERROR.
#
# $null = [System.Threading.Tasks.Task]::Run([Action]{
#     try {
#         $maxThreads = [math]::Min($capturedTotal, 4)
#         $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $maxThreads)
#         $pool.Open()
#
#         $jobs = [System.Collections.Generic.List[hashtable]]::new()
#         foreach ($scanner in $capturedScanners) {
#             if ($capturedToken.IsCancellationRequested) { break }
#             $ps = [System.Management.Automation.PowerShell]::Create()
#             $ps.RunspacePool = $pool
#             $null = $ps.AddScript($capturedScript).AddArgument($scanner).AddArgument($capturedQueue).AddArgument($capturedToken)
#             $jobs.Add(@{ PS = $ps; Handle = $ps.BeginInvoke(); Done = $false })
#         }
#
#         $done = 0
#         $ok = 0
#         $failed = 0
#
#         while ($done -lt $jobs.Count) {
#             Start-Sleep -Milliseconds 300
#             foreach ($j in $jobs) {
#                 if (-not $j.Done -and $j.Handle.IsCompleted) {
#                     $j["Done"] = $true
#                     $done++
#                     try {
#                         $r = $j.PS.EndInvoke($j.Handle)
#                         if ($r -and $r.Count -gt 0 -and $r[0].Success) { $ok++ } else { $failed++ }
#                     } catch {
#                         $failed++
#                         $errMsg = $_.ToString()
#                         $capturedQueue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "Worker error: $errMsg"; Tag = "FAIL" })
#                     } finally {
#                         $j.PS.Dispose()
#                     }
#
#                     $pct = [int](($done / $capturedTotal) * 100)
#                     $capturedQueue.Enqueue([PSCustomObject]@{
#                         Type = "PROGRESS"
#                         Pct = $pct
#                         Status = "Completed $done of $capturedTotal scanner(s)"
#                     })
#                 }
#             }
#         }
#
#         $pool.Close()
#         $pool.Dispose()
#
#         if ($capturedToken.IsCancellationRequested) {
#             $capturedQueue.Enqueue([PSCustomObject]@{ Type = "CANCELLED" })
#         } elseif ($failed -gt 0) {
#             $capturedQueue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "Finished with errors. Success: $ok, Failed: $failed"; Tag = "FAIL" })
#             $capturedQueue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
#         } else {
#             $capturedQueue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "All downloads finished."; Tag = "OK" })
#             $capturedQueue.Enqueue([PSCustomObject]@{ Type = "DONE" })
#         }
#     } catch {
#         $capturedQueue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "Fatal worker error: $($_.ToString())"; Tag = "FAIL" })
#         $capturedQueue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
#     }
# })
