# Module: AV Scanner Downloader
# Downloads latest on-demand antivirus scanners from official vendor sources.
# Live progress: per-file MB/s speed + ETA + overall progress bar via ConcurrentQueue + DispatcherTimer.

Register-PowerToolsModule `
    -Id          "av-scanner-downloader" `
    -Name        "AV Scanner Downloader" `
    -Description "Download the latest Emsisoft EEK, Kaspersky KVRT, Malwarebytes AdwCleaner, and Trend Micro HouseCall from official sources." `
    -Category    "Downloads" `
    -Show        {

    [xml]$viewXaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
    </Grid.RowDefinitions>

    <!-- DESTINATION FOLDER -->
    <StackPanel Grid.Row="0" Margin="0,0,0,14">
        <TextBlock Text="DESTINATION FOLDER" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,6"/>
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="120"/>
            </Grid.ColumnDefinitions>
            <TextBox Grid.Column="0" x:Name="DestBox" Text="C:\AVScanners" Height="40"
                     FontSize="13" Padding="12,10"
                     BorderThickness="1.5"
                     FontFamily="Cascadia Code, Consolas"
                     VerticalContentAlignment="Center" Margin="0,0,8,0"/>
            <Button Grid.Column="1" x:Name="BrowseBtn" Content="Browse..."
                    Style="{DynamicResource SecondaryButton}" Height="40"/>
        </Grid>
    </StackPanel>

    <!-- SCANNER SELECTION -->
    <StackPanel Grid.Row="1" Margin="0,0,0,14">
        <TextBlock Text="SCANNERS" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,8"/>
        <WrapPanel>
            <CheckBox x:Name="CbEEK"        Content="Emsisoft Emergency Kit"   IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbKVRT"       Content="Kaspersky KVRT"           IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbAdwCleaner" Content="Malwarebytes AdwCleaner"  IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbHouseCall"  Content="Trend Micro HouseCall"    IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
        </WrapPanel>
    </StackPanel>

    <!-- INFO BAR -->
    <Border Grid.Row="2" x:Name="InfoBar" BorderThickness="1"
            CornerRadius="6" Padding="12,8" Margin="0,0,0,14">
        <TextBlock x:Name="InfoBarText" FontSize="11" TextWrapping="Wrap"
                   Text="All tools are downloaded directly from official vendor servers. Files are portable and require no installation."/>
    </Border>

    <!-- PROGRESS -->
    <Grid Grid.Row="3" Margin="0,0,0,10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="50"/>
        </Grid.ColumnDefinitions>
        <ProgressBar x:Name="ProgressBar" Grid.Column="0" Height="10"
                     Minimum="0" Maximum="100" Value="0"
                     Foreground="#3B5BDB" Background="#E0E5F5"
                     BorderThickness="0" Margin="0,0,10,0"/>
        <TextBlock x:Name="PctLabel" Grid.Column="1" Text="0%"
                   FontSize="11" FontWeight="SemiBold"
                   VerticalAlignment="Center" HorizontalAlignment="Right"/>
    </Grid>

    <!-- STATUS + BUTTONS -->
    <Grid Grid.Row="4" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="160"/>
            <ColumnDefinition Width="110"/>
            <ColumnDefinition Width="110"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="StatusLabel" Grid.Column="0" Text="Ready."
                   FontSize="12" VerticalAlignment="Center"/>
        <Button x:Name="StartBtn"    Grid.Column="1" Content="Start Download"
                Style="{DynamicResource PrimaryButton}" Height="38" Margin="0,0,8,0"/>
        <Button x:Name="CancelBtn"   Grid.Column="2" Content="Cancel"
                Style="{DynamicResource SecondaryButton}" Height="38" Margin="0,0,8,0"
                IsEnabled="False"/>
        <Button x:Name="ClearLogBtn" Grid.Column="3" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Height="38"/>
    </Grid>

    <!-- LOG -->
    <Border Grid.Row="5" x:Name="LogBorder" BorderThickness="1.5" CornerRadius="8">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="9"
                       FontWeight="Bold" Margin="12,8,0,4"/>
            <ScrollViewer Grid.Row="1" x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogBox"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="11" Padding="12,0,12,10" TextWrapping="Wrap"
                           LineHeight="18" Text="Ready."/>
            </ScrollViewer>
        </Grid>
    </Border>
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $Global:AV_destBox      = $view.FindName("DestBox")
    $Global:AV_browseBtn    = $view.FindName("BrowseBtn")
    $Global:AV_cbEEK        = $view.FindName("CbEEK")
    $Global:AV_cbKVRT       = $view.FindName("CbKVRT")
    $Global:AV_cbAdwCleaner = $view.FindName("CbAdwCleaner")
    $Global:AV_cbHouseCall  = $view.FindName("CbHouseCall")
    $Global:AV_startBtn     = $view.FindName("StartBtn")
    $Global:AV_cancelBtn    = $view.FindName("CancelBtn")
    $Global:AV_progress     = $view.FindName("ProgressBar")
    $Global:AV_statusLabel  = $view.FindName("StatusLabel")
    $Global:AV_pctLabel     = $view.FindName("PctLabel")
    $Global:AV_clearLogBtn  = $view.FindName("ClearLogBtn")
    $Global:AV_logBox       = $view.FindName("LogBox")
    $Global:AV_logScroller  = $view.FindName("LogScroller")
    $Global:AV_logBorder    = $view.FindName("LogBorder")
    $Global:AV_infoBar      = $view.FindName("InfoBar")
    $Global:AV_infoBarText  = $view.FindName("InfoBarText")
    $Global:AV_initText     = "Ready."
    $Global:AV_msgQueue     = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:AV_timer        = $null
    $Global:AV_cancelFlag   = [System.Threading.CancellationTokenSource]::new()
    $Global:AV_bgPS         = $null
    $Global:AV_bgHandle     = $null

    # safer default destination
    $defaultDest = Join-Path $env:USERPROFILE "Downloads\AVScanners"
    if ([string]::IsNullOrWhiteSpace($Global:AV_destBox.Text) -or $Global:AV_destBox.Text -eq "C:\AVScanners") {
        $Global:AV_destBox.Text = $defaultDest
    }

    # Apply theme-aware colors
    $Global:AV_destBox.Background     = $Global:PTS_Brush["InputBg"]
    $Global:AV_destBox.Foreground     = $Global:PTS_Brush["InputFg"]
    $Global:AV_destBox.BorderBrush    = $Global:PTS_Brush["Border"]
    $Global:AV_logBox.Foreground      = $Global:PTS_Brush["TextMuted"]
    $Global:AV_logBorder.Background   = $Global:PTS_Brush["LogBg"]
    $Global:AV_logBorder.BorderBrush  = $Global:PTS_Brush["LogBorder"]
    $Global:AV_infoBar.Background     = $Global:PTS_Brush["Surface"]
    $Global:AV_infoBar.BorderBrush    = $Global:PTS_Brush["Border"]
    $Global:AV_infoBarText.Foreground = $Global:PTS_Brush["TextMid"]
    $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["TextMuted"]
    $Global:AV_pctLabel.Foreground    = $Global:PTS_Brush["Primary"]

    # ===========================================================================
    # HELPERS
    # ===========================================================================
    function Global:AV-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) {
            "OK"   { "[OK]  " }
            "FAIL" { "[FAIL]" }
            "WARN" { "[WARN]" }
            default{ "[INFO]" }
        }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($Global:AV_logBox.Text -eq $Global:AV_initText) { $Global:AV_logBox.Text = $entry }
        else { $Global:AV_logBox.Text += $entry }
        $Global:AV_logScroller.ScrollToEnd()
    }

    function Global:AV-SetUI-Busy {
        param([bool]$Busy)
        $Global:AV_startBtn.IsEnabled  = -not $Busy
        $Global:AV_cancelBtn.IsEnabled = $Busy
        $Global:AV_startBtn.Content    = if ($Busy) { "Downloading..." } else { "Start Download" }
    }

    function Global:AV-CleanupBackground {
        if ($null -ne $Global:AV_bgPS) {
            try {
                if ($null -ne $Global:AV_bgHandle -and $Global:AV_bgHandle.IsCompleted) {
                    $null = $Global:AV_bgPS.EndInvoke($Global:AV_bgHandle)
                }
            } catch {
                # already reported elsewhere or runspace disposed
            } finally {
                try { $Global:AV_bgPS.Dispose() } catch {}
                $Global:AV_bgPS = $null
                $Global:AV_bgHandle = $null
            }
        }
    }

    function Global:AV-StartTimer {
        if ($null -ne $Global:AV_timer) {
            try { $Global:AV_timer.Stop() } catch {}
        }

        $Global:AV_timer = New-Object System.Windows.Threading.DispatcherTimer
        $Global:AV_timer.Interval = [TimeSpan]::FromMilliseconds(200)
        $Global:AV_timer.Add_Tick({
            $item = $null
            while ($Global:AV_msgQueue.TryDequeue([ref]$item)) {
                switch ($item.Type) {
                    "LOG" {
                        AV-AddLog -Msg $item.Msg -Type $item.Tag
                    }
                    "PROGRESS" {
                        $Global:AV_progress.Value   = $item.Pct
                        $Global:AV_statusLabel.Text = $item.Status
                        $Global:AV_pctLabel.Text    = "$($item.Pct)%"
                    }
                    "DONE" {
                        $Global:AV_timer.Stop()
                        $Global:AV_progress.Value         = 100
                        $Global:AV_pctLabel.Text          = "100%"
                        $Global:AV_statusLabel.Text       = "All downloads complete."
                        $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["Success"]
                        AV-SetUI-Busy $false
                        AV-CleanupBackground
                    }
                    "CANCELLED" {
                        $Global:AV_timer.Stop()
                        $Global:AV_statusLabel.Text       = "Cancelled."
                        $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["Warning"]
                        AV-SetUI-Busy $false
                        AV-CleanupBackground
                    }
                    "ERROR" {
                        $Global:AV_timer.Stop()
                        $Global:AV_statusLabel.Text       = if ($item.Status) { $item.Status } else { "Error during download." }
                        $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                        AV-SetUI-Busy $false
                        AV-CleanupBackground
                    }
                }
            }
        })
        $Global:AV_timer.Start()
    }

    # ===========================================================================
    # DOWNLOAD WORKER SCRIPT (executes inside RunspacePool)
    # ===========================================================================
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

        # Skip if fresh copy exists (< 24h)
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

    $Global:AV_orchestratorScript = {
        param(
            [object[]]$Scanners,
            [int]$Total,
            [System.Collections.Concurrent.ConcurrentQueue[object]]$Queue,
            [System.Threading.CancellationToken]$CancelToken,
            [scriptblock]$WorkerScript
        )

        try {
            $maxThreads = [math]::Min($Total, 4)
            $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $maxThreads)
            $pool.Open()

            $jobs = [System.Collections.Generic.List[hashtable]]::new()
            foreach ($scanner in $Scanners) {
                if ($CancelToken.IsCancellationRequested) { break }
                $Queue.Enqueue([PSCustomObject]@{
                    Type = "LOG"
                    Msg  = "Queueing job: $($scanner.Name)"
                    Tag  = "INFO"
                })
                $ps = [System.Management.Automation.PowerShell]::Create()
                $ps.RunspacePool = $pool
                $null = $ps.AddScript($WorkerScript).AddArgument($scanner).AddArgument($Queue).AddArgument($CancelToken)
                $jobs.Add(@{ PS = $ps; Handle = $ps.BeginInvoke(); Done = $false })
            }

            $done = 0
            $ok = 0
            $failed = 0

            while ($done -lt $jobs.Count) {
                Start-Sleep -Milliseconds 300
                foreach ($j in $jobs) {
                    if (-not $j.Done -and $j.Handle.IsCompleted) {
                        $j["Done"] = $true
                        $done++
                        try {
                            $r = $j.PS.EndInvoke($j.Handle)
                            if ($r -and $r.Count -gt 0 -and $r[0].Success) {
                                $ok++
                                $Queue.Enqueue([PSCustomObject]@{
                                    Type = "LOG"
                                    Msg  = "Job success: $($r[0].Name)"
                                    Tag  = "OK"
                                })
                            } else {
                                $failed++
                                $failedName = if ($r -and $r.Count -gt 0 -and $r[0].Name) { $r[0].Name } else { "Unknown" }
                                $failedReason = if ($r -and $r.Count -gt 0 -and $r[0].Message) { $r[0].Message } else { "No reason returned" }
                                $Queue.Enqueue([PSCustomObject]@{
                                    Type = "LOG"
                                    Msg  = "Job failed: $failedName ($failedReason)"
                                    Tag  = "FAIL"
                                })
                            }
                        } catch {
                            $failed++
                            $errMsg = $_.ToString()
                            $Queue.Enqueue([PSCustomObject]@{
                                Type = "LOG"
                                Msg  = "Worker error: $errMsg"
                                Tag  = "FAIL"
                            })
                        } finally {
                            $j.PS.Dispose()
                        }

                        $pct = [int](($done / $Total) * 100)
                        $Queue.Enqueue([PSCustomObject]@{
                            Type   = "PROGRESS"
                            Pct    = $pct
                            Status = "Completed $done of $Total scanner(s)"
                        })
                    }
                }
            }

            $pool.Close()
            $pool.Dispose()

            if ($CancelToken.IsCancellationRequested) {
                $Queue.Enqueue([PSCustomObject]@{ Type = "CANCELLED" })
            } elseif ($failed -gt 0) {
                $Queue.Enqueue([PSCustomObject]@{
                    Type = "LOG"
                    Msg  = "Finished with errors. Success: $ok, Failed: $failed"
                    Tag  = "FAIL"
                })
                $Queue.Enqueue([PSCustomObject]@{
                    Type   = "ERROR"
                    Status = "Finished with errors ($ok ok / $failed failed)."
                })
            } else {
                $Queue.Enqueue([PSCustomObject]@{
                    Type = "LOG"
                    Msg  = "All downloads finished."
                    Tag  = "OK"
                })
                $Queue.Enqueue([PSCustomObject]@{ Type = "DONE" })
            }
        } catch {
            $Queue.Enqueue([PSCustomObject]@{
                Type = "LOG"
                Msg  = "Fatal coordinator error: $($_.ToString())"
                Tag  = "FAIL"
            })
            $Queue.Enqueue([PSCustomObject]@{
                Type   = "ERROR"
                Status = "Fatal error during download task."
            })
        }
    }

    # ===========================================================================
    # SCANNER JOB LIST
    # ===========================================================================
    function Global:AV-GetScannerList {
        param([string]$Dest)
        $list = @()
        if ($Global:AV_cbEEK.IsChecked) {
            $list += @{
                Name           = "Emsisoft Emergency Kit"
                FileName       = "EmsisoftEmergencyKit.exe"
                Url            = "https://dl.emsisoft.com/EmsisoftEmergencyKit.exe"
                LandingPageUrl = "https://www.emsisoft.com/en/emergency-kit/"
                AllowedHosts   = @("dl.emsisoft.com","www.emsisoft.com","emsisoft.com")
                OutFile        = Join-Path $Dest "EmsisoftEmergencyKit.exe"
            }
        }
        if ($Global:AV_cbKVRT.IsChecked) {
            $list += @{
                Name           = "Kaspersky KVRT"
                FileName       = "KVRT.exe"
                Url            = "https://devapps.kaspersky.com/mcc/static/kvrt/en-US/vital-product/KVRT.exe"
                FallbackUrls   = @(
                    "https://devbuilds.s.kaspersky-labs.com/devbuilds/KVRT/latest/full/KVRT.exe"
                )
                LandingPageUrl = "https://www.kaspersky.com/free-virus-scan"
                AllowedHosts   = @("devapps.kaspersky.com","devbuilds.s.kaspersky-labs.com","www.kaspersky.com","kaspersky.com")
                OutFile        = Join-Path $Dest "KVRT.exe"
            }
        }
        if ($Global:AV_cbAdwCleaner.IsChecked) {
            $list += @{
                Name           = "Malwarebytes AdwCleaner"
                FileName       = "adwcleaner_latest.exe"
                Url            = "https://adwcleaner.malwarebytes.com/adwcleaner/adwcleaner_latest.exe"
                LandingPageUrl = "https://www.malwarebytes.com/adwcleaner"
                AllowedHosts   = @("adwcleaner.malwarebytes.com","www.malwarebytes.com","malwarebytes.com")
                OutFile        = Join-Path $Dest "adwcleaner_latest.exe"
            }
        }
        if ($Global:AV_cbHouseCall.IsChecked) {
            $list += @{
                Name           = "Trend Micro HouseCall"
                FileName       = "HousecallLauncher64.exe"
                Url            = "https://housecall.trendmicro.com/housecall/downloads/HousecallLauncher64.exe"
                FallbackUrls   = @(
                    "https://us.shop.trendmicro.com/en_us/products/house-call.asp",
                    "https://shop.trendmicro.com/en_us/products/house-call.asp",
                    "https://www.trendmicro.com/en_us/forHome/products/housecall.html"
                )
                LandingPageUrl = "https://www.trendmicro.com/en_us/forHome/products/housecall.html"
                AllowedHosts   = @("housecall.trendmicro.com","shop.trendmicro.com","us.shop.trendmicro.com","www.trendmicro.com","trendmicro.com")
                OutFile        = Join-Path $Dest "HousecallLauncher64.exe"
            }
        }
        return $list
    }

    # ===========================================================================
    # START HANDLER
    # ===========================================================================
    $Global:AV_startBtn.Add_Click({
        try {
            AV-AddLog "Start requested." "INFO"

            if ($null -ne $Global:AV_bgHandle -and -not $Global:AV_bgHandle.IsCompleted) {
                AV-AddLog "A download operation is already running." "WARN"
                return
            }
            AV-CleanupBackground

            $dest = "$($Global:AV_destBox.Text)".Trim()
            if ([string]::IsNullOrWhiteSpace($dest)) {
                AV-AddLog "No destination folder specified." "FAIL"
                return
            }
            if (-not (Test-Path $dest)) {
                try {
                    New-Item -ItemType Directory -Path $dest -Force | Out-Null
                    AV-AddLog "Created folder: $dest" "INFO"
                } catch {
                    $errMsg = $_.ToString()
                    AV-AddLog "Cannot create folder: $dest - $errMsg" "FAIL"
                    return
                }
            }

            $scanners = AV-GetScannerList -Dest $dest
            if ($scanners.Count -eq 0) {
                AV-AddLog "No scanners selected." "WARN"
                return
            }

            AV-AddLog "Selected scanners: $((@($scanners | ForEach-Object { $_.Name }) -join ', '))" "INFO"
            AV-AddLog "Destination: $dest" "INFO"

            $Global:AV_cancelFlag = [System.Threading.CancellationTokenSource]::new()

            # clear stale queue messages from previous run
            $item = $null
            while ($Global:AV_msgQueue.TryDequeue([ref]$item)) {}

            $Global:AV_progress.Value         = 0
            $Global:AV_pctLabel.Text          = "0%"
            $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["TextMuted"]
            $Global:AV_statusLabel.Text       = "Starting..."
            AV-SetUI-Busy $true
            AV-StartTimer

            $capturedScanners = @($scanners)
            $capturedTotal    = $scanners.Count
            $capturedQueue    = $Global:AV_msgQueue
            $capturedToken    = $Global:AV_cancelFlag.Token
            $capturedScript   = $Global:AV_dlScript
            $capturedOrch     = $Global:AV_orchestratorScript

            $Global:AV_bgPS = [System.Management.Automation.PowerShell]::Create()
            $null = $Global:AV_bgPS.AddScript($capturedOrch).AddArgument($capturedScanners).AddArgument($capturedTotal).AddArgument($capturedQueue).AddArgument($capturedToken).AddArgument($capturedScript)
            $Global:AV_bgHandle = $Global:AV_bgPS.BeginInvoke()

            AV-AddLog "Download coordinator started (parallel max: $([Math]::Min($capturedTotal,4)))." "INFO"
        } catch {
            $errMsg = $_.ToString()
            AV-AddLog "Failed to start download operation: $errMsg" "FAIL"
            $Global:AV_statusLabel.Text       = "Error during startup."
            $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
            AV-SetUI-Busy $false
            AV-CleanupBackground
        }
    })

    # ===========================================================================
    # CANCEL HANDLER
    # ===========================================================================
    $Global:AV_cancelBtn.Add_Click({
        if ($null -ne $Global:AV_cancelFlag -and -not $Global:AV_cancelFlag.IsCancellationRequested) {
            $Global:AV_cancelFlag.Cancel()
            AV-AddLog "Cancel requested..." "WARN"
        }
    })

    # ===========================================================================
    # BROWSE HANDLER
    # ===========================================================================
    $Global:AV_browseBtn.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description         = "Select destination folder for AV scanners"
        $dlg.SelectedPath        = $Global:AV_destBox.Text
        $dlg.ShowNewFolderButton = $true
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $Global:AV_destBox.Text = $dlg.SelectedPath
        }
    })

    # ===========================================================================
    # CLEAR LOG HANDLER
    # ===========================================================================
    $Global:AV_clearLogBtn.Add_Click({
        $Global:AV_logBox.Text = $Global:AV_initText
    })

    return $view
}
