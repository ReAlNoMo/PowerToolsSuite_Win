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
            <CheckBox x:Name="CbEEK"       Content="Emsisoft Emergency Kit"      IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbKVRT"      Content="Kaspersky KVRT"              IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbAdwCleaner" Content="Malwarebytes AdwCleaner"    IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbHouseCall" Content="Trend Micro HouseCall"       IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
        </WrapPanel>
    </StackPanel>

    <!-- INFO BAR -->
    <Border Grid.Row="2" Background="#EEF1FC" BorderBrush="#D0D6F0" BorderThickness="1"
            CornerRadius="6" Padding="12,8" Margin="0,0,0,14">
        <TextBlock Text="All tools are downloaded directly from official vendor servers. Files are portable and require no installation."
                   Foreground="#4A5280" FontSize="11" TextWrapping="Wrap"/>
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
                   Foreground="#4A5280" FontSize="11" FontWeight="SemiBold"
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
                   Foreground="#8890B8" FontSize="12" VerticalAlignment="Center"/>
        <Button x:Name="StartBtn"  Grid.Column="1" Content="Start Download"
                Style="{DynamicResource PrimaryButton}" Height="38" Margin="0,0,8,0"/>
        <Button x:Name="CancelBtn" Grid.Column="2" Content="Cancel"
                Style="{DynamicResource SecondaryButton}" Height="38" Margin="0,0,8,0"
                IsEnabled="False"/>
        <Button x:Name="ClearLogBtn" Grid.Column="3" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Height="38"/>
    </Grid>

    <!-- LOG -->
    <Border Grid.Row="5" x:Name="LogBorder"
            BorderThickness="1.5" CornerRadius="8">
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
    $Global:AV_initText     = "Ready."
    $Global:AV_msgQueue     = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:AV_timer        = $null
    $Global:AV_cancelFlag   = [System.Threading.CancellationTokenSource]::new()

    # Apply theme-aware colors
    $Global:AV_destBox.Background   = $Global:PTS_Brush["InputBg"]
    $Global:AV_destBox.Foreground   = $Global:PTS_Brush["InputFg"]
    $Global:AV_destBox.BorderBrush  = $Global:PTS_Brush["Border"]
    $Global:AV_logBox.Foreground    = $Global:PTS_Brush["TextMuted"]
    $Global:AV_logBorder.Background  = $Global:PTS_Brush["LogBg"]
    $Global:AV_logBorder.BorderBrush = $Global:PTS_Brush["LogBorder"]

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

    function Global:AV-QueueMsg {
        param([hashtable]$Msg)
        $Global:AV_msgQueue.Enqueue($Msg)
    }

    function Global:AV-StartTimer {
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
                        $Global:AV_progress.Value        = 100
                        $Global:AV_pctLabel.Text         = "100%"
                        $Global:AV_statusLabel.Text      = "All downloads complete."
                        $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["Success"]
                        AV-SetUI-Busy $false
                    }
                    "CANCELLED" {
                        $Global:AV_timer.Stop()
                        $Global:AV_statusLabel.Text      = "Cancelled."
                        $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["Warning"]
                        AV-SetUI-Busy $false
                    }
                    "ERROR" {
                        $Global:AV_timer.Stop()
                        $Global:AV_statusLabel.Text      = "Error during download."
                        $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                        AV-SetUI-Busy $false
                    }
                }
            }
        })
        $Global:AV_timer.Start()
    }

    # ===========================================================================
    # SCANNER DEFINITIONS
    # All URLs are official vendor-hosted endpoints
    # ===========================================================================
    function Global:AV-GetScannerList {
        param([string]$Dest)
        $list = @()

        if ($Global:AV_cbEEK.IsChecked) {
            $list += @{
                Name    = "Emsisoft Emergency Kit"
                FileName = "EmsisoftEmergencyKit.exe"
                Url     = "https://dl.emsisoft.com/EmsisoftEmergencyKit.exe"
                OutFile = Join-Path $Dest "EmsisoftEmergencyKit.exe"
            }
        }

        if ($Global:AV_cbKVRT.IsChecked) {
            $list += @{
                Name    = "Kaspersky KVRT"
                FileName = "KVRT.exe"
                Url     = "https://devapps.kaspersky.com/mcc/static/kvrt/en-US/vital-product/KVRT.exe"
                OutFile = Join-Path $Dest "KVRT.exe"
                FallbackUrl = "https://www.kaspersky.com/downloads/free-virus-removal-tool"
            }
        }

        if ($Global:AV_cbAdwCleaner.IsChecked) {
            $list += @{
                Name    = "Malwarebytes AdwCleaner"
                FileName = "adwcleaner_latest.exe"
                Url     = "https://adwcleaner.malwarebytes.com/adwcleaner/adwcleaner_latest.exe"
                OutFile = Join-Path $Dest "adwcleaner_latest.exe"
            }
        }

        if ($Global:AV_cbHouseCall.IsChecked) {
            $list += @{
                Name    = "Trend Micro HouseCall"
                FileName = "HousecallLauncher64.exe"
                Url     = "https://housecall.trendmicro.com/housecall/downloads/HousecallLauncher64.exe"
                OutFile = Join-Path $Dest "HousecallLauncher64.exe"
            }
        }

        return $list
    }

    # ===========================================================================
    # DOWNLOAD ENGINE (background thread)
    # ===========================================================================
    function Global:AV-DownloadFile {
        param(
            [hashtable]$Scanner,
            [int]$Index,
            [int]$Total,
            [System.Threading.CancellationToken]$Token
        )

        $name    = $Scanner.Name
        $url     = $Scanner.Url
        $outFile = $Scanner.OutFile

        AV-QueueMsg @{ Type="LOG"; Msg="Starting: $name"; Tag="INFO" }
        AV-QueueMsg @{ Type="PROGRESS"; Pct=[int](($Index / $Total) * 100); Status="Downloading $name..." }

        # Skip if already exists and recent (within 24h)
        if (Test-Path $outFile) {
            $age = (Get-Date) - (Get-Item $outFile).LastWriteTime
            if ($age.TotalHours -lt 24) {
                AV-QueueMsg @{ Type="LOG"; Msg="Skipped (fresh copy exists): $($Scanner.FileName)"; Tag="WARN" }
                return $true
            }
        }

        $tmpFile = "$outFile.tmp"
        try {
            $req = [System.Net.HttpWebRequest]::Create($url)
            $req.Method    = "GET"
            $req.UserAgent = "PowerTools-Suite-AVDownloader/1.0"
            $req.Timeout   = 30000
            $resp   = $req.GetResponse()
            $total  = $resp.ContentLength
            $stream = $resp.GetResponseStream()
            $fs     = [System.IO.File]::Create($tmpFile)
            $buf    = New-Object byte[] 65536
            $downloaded = 0
            $sw     = [System.Diagnostics.Stopwatch]::StartNew()
            $lastReport = 0

            while ($true) {
                if ($Token.IsCancellationRequested) {
                    $fs.Close(); $stream.Close()
                    if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force }
                    AV-QueueMsg @{ Type="LOG"; Msg="Cancelled: $name"; Tag="WARN" }
                    return $false
                }
                $read = $stream.Read($buf, 0, $buf.Length)
                if ($read -le 0) { break }
                $fs.Write($buf, 0, $read)
                $downloaded += $read

                $now = $sw.ElapsedMilliseconds
                if (($now - $lastReport) -ge 500) {
                    $lastReport = $now
                    $speed = if ($sw.Elapsed.TotalSeconds -gt 0) {
                        [math]::Round($downloaded / 1024 / 1024 / $sw.Elapsed.TotalSeconds, 1)
                    } else { 0 }

                    $dlMB  = [math]::Round($downloaded / 1MB, 1)
                    $totMB = if ($total -gt 0) { [math]::Round($total / 1MB, 1) } else { "?" }
                    $eta   = if ($total -gt 0 -and $speed -gt 0) {
                        $rem = ($total - $downloaded) / 1MB / $speed
                        "$([math]::Round($rem))s"
                    } else { "..." }

                    $filePct = if ($total -gt 0) { [int](($downloaded / $total) * 100) } else { 0 }
                    $overallPct = [int](($Index / $Total) * 100) + [int]($filePct / $Total)

                    $status = "$name  |  ${dlMB}MB / ${totMB}MB  |  ${speed} MB/s  |  ETA: $eta"
                    AV-QueueMsg @{ Type="PROGRESS"; Pct=$overallPct; Status=$status }
                }
            }

            $fs.Close()
            $stream.Close()
            $resp.Close()

            Move-Item -Path $tmpFile -Destination $outFile -Force
            $sizeMB = [math]::Round((Get-Item $outFile).Length / 1MB, 1)
            AV-QueueMsg @{ Type="LOG"; Msg="Downloaded: $($Scanner.FileName) (${sizeMB} MB)"; Tag="OK" }
            return $true

        } catch {
            if ($null -ne $fs)  { try { $fs.Close()   } catch {} }
            if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue }

            # Try fallback URL if defined
            if ($Scanner.FallbackUrl -and $Scanner.FallbackUrl -ne $url) {
                AV-QueueMsg @{ Type="LOG"; Msg="Primary URL failed, trying fallback: $name"; Tag="WARN" }
                $Scanner2 = $Scanner.Clone()
                $Scanner2.Url = $Scanner.FallbackUrl
                $Scanner2.Remove("FallbackUrl")
                return AV-DownloadFile -Scanner $Scanner2 -Index $Index -Total $Total -Token $Token
            }

            AV-QueueMsg @{ Type="LOG"; Msg="FAILED: $name - $_"; Tag="FAIL" }
            return $false
        }
    }

    # ===========================================================================
    # START HANDLER
    # ===========================================================================
    $Global:AV_startBtn.Add_Click({
        $dest = $Global:AV_destBox.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($dest)) {
            AV-AddLog "No destination folder specified." "FAIL"
            return
        }
        if (-not (Test-Path $dest)) {
            try {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                AV-AddLog "Created folder: $dest" "INFO"
            } catch {
                AV-AddLog "Cannot create folder: $dest" "FAIL"
                return
            }
        }

        $scanners = AV-GetScannerList -Dest $dest
        if ($scanners.Count -eq 0) {
            AV-AddLog "No scanners selected." "WARN"
            return
        }

        $Global:AV_cancelFlag = [System.Threading.CancellationTokenSource]::new()
        $token = $Global:AV_cancelFlag.Token

        $Global:AV_progress.Value        = 0
        $Global:AV_pctLabel.Text         = "0%"
        $Global:AV_statusLabel.Foreground = $Global:PTS_Brush["TextMuted"]
        $Global:AV_statusLabel.Text      = "Starting..."
        AV-SetUI-Busy $true
        AV-StartTimer

        $total    = $scanners.Count
        $captured = @($scanners)

        $null = [System.Threading.Tasks.Task]::Run([Action]{
            $allOk = $true
            for ($i = 0; $i -lt $captured.Count; $i++) {
                if ($token.IsCancellationRequested) {
                    AV-QueueMsg @{ Type="CANCELLED" }
                    return
                }
                $ok = AV-DownloadFile -Scanner $captured[$i] -Index $i -Total $total -Token $token
                if (-not $ok -and -not $token.IsCancellationRequested) { $allOk = $false }
            }
            if ($token.IsCancellationRequested) {
                AV-QueueMsg @{ Type="CANCELLED" }
            } elseif ($allOk) {
                AV-QueueMsg @{ Type="LOG"; Msg="All selected scanners downloaded successfully."; Tag="OK" }
                AV-QueueMsg @{ Type="DONE" }
            } else {
                AV-QueueMsg @{ Type="LOG"; Msg="Some downloads failed. Check log above."; Tag="WARN" }
                AV-QueueMsg @{ Type="DONE" }
            }
        })
    })

    # ===========================================================================
    # CANCEL HANDLER
    # ===========================================================================
    $Global:AV_cancelBtn.Add_Click({
        $Global:AV_cancelFlag.Cancel()
        AV-AddLog "Cancel requested..." "WARN"
    })

    # ===========================================================================
    # BROWSE HANDLER
    # ===========================================================================
    $Global:AV_browseBtn.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description        = "Select destination folder for AV scanners"
        $dlg.SelectedPath       = $Global:AV_destBox.Text
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
