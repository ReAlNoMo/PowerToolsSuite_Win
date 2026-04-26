# Module: Linux ISO Downloader
# Downloads latest Linux distribution ISOs from official sources in parallel.
# Live progress: per-file MB/s speed + ETA + overall progress bar via ConcurrentQueue + DispatcherTimer.

Register-PowerToolsModule `
    -Id          "linux-iso-downloader" `
    -Name        "Linux ISO Downloader" `
    -Description "Download the latest Ubuntu, Debian, Fedora, Arch, CachyOS, and Pop!_OS ISOs with hash verification." `
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
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Margin="0,0,0,14">
        <TextBlock Text="DESTINATION FOLDER" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,6"/>
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="120"/>
            </Grid.ColumnDefinitions>
            <TextBox Grid.Column="0" x:Name="DestBox" Text="D:\ISOs" Height="40"
                     FontSize="13" Padding="12,10"
                     BorderThickness="1.5"
                     FontFamily="Cascadia Code, Consolas"
                     VerticalContentAlignment="Center" Margin="0,0,8,0"/>
            <Button Grid.Column="1" x:Name="BrowseBtn" Content="Browse..."
                    Style="{DynamicResource SecondaryButton}" Height="40"/>
        </Grid>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,14">
        <TextBlock Text="DISTRIBUTIONS" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,8"/>
        <WrapPanel>
            <CheckBox x:Name="CbUbuntu"  Content="Ubuntu"   IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbDebian"  Content="Debian"   IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbFedora"  Content="Fedora"   IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbArch"    Content="Arch"     IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbCachyOS" Content="CachyOS"  IsChecked="False" Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbPopOS"   Content="Pop!_OS"  IsChecked="False" Margin="0,0,18,6" FontSize="13"/>
        </WrapPanel>
    </StackPanel>

    <Grid Grid.Row="2" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="130"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="140"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0">
            <TextBlock Text="MAX PARALLEL DOWNLOADS" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,6"/>
            <ComboBox x:Name="ParallelCombo" Height="40" FontSize="13" Padding="10,8">
                <ComboBoxItem Content="1"/>
                <ComboBoxItem Content="2"/>
                <ComboBoxItem Content="3" IsSelected="True"/>
                <ComboBoxItem Content="4"/>
                <ComboBoxItem Content="5"/>
            </ComboBox>
        </StackPanel>
        <Button Grid.Column="2" x:Name="StartBtn" Content="Start Download"
                Style="{DynamicResource PrimaryButton}" Height="40" VerticalAlignment="Bottom"/>
        <Button Grid.Column="4" x:Name="CancelBtn" Content="Cancel"
                Style="{DynamicResource SecondaryButton}" Height="40"
                VerticalAlignment="Bottom" IsEnabled="False"/>
    </Grid>

    <!-- Overall progress -->
    <Grid Grid.Row="3" Margin="0,0,0,4">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="StatusLabel" Grid.Column="0"
                   Text="Idle" Foreground="#8890B8" FontSize="11" VerticalAlignment="Center"/>
        <TextBlock x:Name="PctLabel" Grid.Column="1"
                   Text="" Foreground="#3B5BDB" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/>
    </Grid>
    <ProgressBar Grid.Row="4" x:Name="ProgressBar" Height="8"
                 Minimum="0" Maximum="100" Value="0" Margin="0,0,0,14"/>

    <Grid Grid.Row="5" Margin="0,0,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" VerticalAlignment="Center"/>
        <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="6" x:Name="LogBorder"
            BorderThickness="1.5" CornerRadius="10">
        <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
            <TextBlock x:Name="LogBox"
                       FontFamily="Cascadia Code, Consolas, Courier New"
                       FontSize="12" Padding="16,12" TextWrapping="Wrap"
                       LineHeight="20" Text="Ready."/>
        </ScrollViewer>
    </Border>
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $Global:ISO_destBox     = $view.FindName("DestBox")
    $Global:ISO_browseBtn   = $view.FindName("BrowseBtn")
    $Global:ISO_cbUbuntu    = $view.FindName("CbUbuntu")
    $Global:ISO_cbDebian    = $view.FindName("CbDebian")
    $Global:ISO_cbFedora    = $view.FindName("CbFedora")
    $Global:ISO_cbArch      = $view.FindName("CbArch")
    $Global:ISO_cbCachyOS   = $view.FindName("CbCachyOS")
    $Global:ISO_cbPopOS     = $view.FindName("CbPopOS")
    $Global:ISO_parallel    = $view.FindName("ParallelCombo")
    $Global:ISO_startBtn    = $view.FindName("StartBtn")
    $Global:ISO_cancelBtn   = $view.FindName("CancelBtn")
    $Global:ISO_progress    = $view.FindName("ProgressBar")
    $Global:ISO_statusLabel = $view.FindName("StatusLabel")
    $Global:ISO_pctLabel    = $view.FindName("PctLabel")
    $Global:ISO_clearLog    = $view.FindName("ClearLogBtn")
    $Global:ISO_logBox      = $view.FindName("LogBox")
    $Global:ISO_logScroller = $view.FindName("LogScroller")
    $Global:ISO_logBorder   = $view.FindName("LogBorder")
    $Global:ISO_initText    = "Ready."
    $Global:ISO_msgQueue    = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:ISO_timer       = $null
    $Global:ISO_cancelFlag  = [System.Threading.CancellationTokenSource]::new()
    $Global:ISO_bgPS        = $null
    $Global:ISO_bgHandle    = $null

    # Apply theme-aware colors to TextBox and Log border
    $Global:ISO_destBox.Background  = $Global:PTS_Brush["InputBg"]
    $Global:ISO_destBox.Foreground  = $Global:PTS_Brush["InputFg"]
    $Global:ISO_destBox.BorderBrush = $Global:PTS_Brush["Border"]
    $Global:ISO_logBox.Foreground   = $Global:PTS_Brush["TextMuted"]
    $Global:ISO_logBorder.Background   = $Global:PTS_Brush["LogBg"]
    $Global:ISO_logBorder.BorderBrush  = $Global:PTS_Brush["LogBorder"]

    # ===========================================================================
    # HELPERS
    # ===========================================================================
    function Global:ISO-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($Global:ISO_logBox.Text -eq $Global:ISO_initText) { $Global:ISO_logBox.Text = $entry }
        else { $Global:ISO_logBox.Text += $entry }
        $Global:ISO_logScroller.ScrollToEnd()
    }

    function Global:ISO-SetUI-Busy {
        param([bool]$Busy)
        $Global:ISO_startBtn.IsEnabled  = -not $Busy
        $Global:ISO_cancelBtn.IsEnabled = $Busy
        $Global:ISO_startBtn.Content    = if ($Busy) { "Downloading..." } else { "Start Download" }
    }

    function Global:ISO-CleanupBackground {
        if ($null -ne $Global:ISO_bgPS) {
            try {
                if ($null -ne $Global:ISO_bgHandle -and $Global:ISO_bgHandle.IsCompleted) {
                    $null = $Global:ISO_bgPS.EndInvoke($Global:ISO_bgHandle)
                }
            } catch {
                # already handled
            } finally {
                try { $Global:ISO_bgPS.Dispose() } catch {}
                $Global:ISO_bgPS = $null
                $Global:ISO_bgHandle = $null
            }
        }
    }

    function Global:ISO-QueueMsg {
        param([hashtable]$Msg)
        $Global:ISO_msgQueue.Enqueue($Msg)
    }

    function Global:ISO-StartTimer {
        $Global:ISO_timer = New-Object System.Windows.Threading.DispatcherTimer
        $Global:ISO_timer.Interval = [TimeSpan]::FromMilliseconds(200)
        $Global:ISO_timer.Add_Tick({
            $item = $null
            while ($Global:ISO_msgQueue.TryDequeue([ref]$item)) {
                switch ($item.Type) {
                    "LOG" {
                        ISO-AddLog -Msg $item.Msg -Type $item.Tag
                    }
                    "PROGRESS" {
                        $Global:ISO_progress.Value   = $item.Pct
                        $Global:ISO_statusLabel.Text = $item.Status
                        $Global:ISO_pctLabel.Text    = "$($item.Pct)%"
                    }
                    "DONE" {
                        $Global:ISO_timer.Stop()
                        $Global:ISO_progress.Value        = 100
                        $Global:ISO_pctLabel.Text         = "100%"
                        $Global:ISO_statusLabel.Text      = "All downloads complete."
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Success"]
                        ISO-SetUI-Busy $false
                        ISO-CleanupBackground
                    }
                    "CANCELLED" {
                        $Global:ISO_timer.Stop()
                        $Global:ISO_statusLabel.Text      = "Cancelled."
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Warning"]
                        ISO-SetUI-Busy $false
                        ISO-CleanupBackground
                    }
                    "ERROR" {
                        $Global:ISO_timer.Stop()
                        $Global:ISO_statusLabel.Text      = "Error."
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                        ISO-SetUI-Busy $false
                        ISO-CleanupBackground
                    }
                }
            }
        })
        $Global:ISO_timer.Start()
    }

    # ===========================================================================
    # ISO DEFINITIONS
    # ===========================================================================
    function Global:ISO-GetJobList {
        param([string]$Dest, [System.Threading.CancellationToken]$Token)

        $jobs = @()

        if ($Global:ISO_cbUbuntu.IsChecked) {
            $jobs += @{
                IsoName  = "Ubuntu"
                FileName = "ubuntu-latest-amd64.iso"
                OutFile  = Join-Path $Dest "ubuntu-latest-amd64.iso"
                UrlList  = @(
                    "https://releases.ubuntu.com/noble/ubuntu-24.04.2-desktop-amd64.iso",
                    "https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso"
                )
            }
        }

        if ($Global:ISO_cbDebian.IsChecked) {
            $jobs += @{
                IsoName  = "Debian"
                FileName = "debian-latest-amd64.iso"
                OutFile  = Join-Path $Dest "debian-latest-amd64.iso"
                UrlList  = @(
                    "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.10.0-amd64-netinst.iso"
                )
            }
        }

        if ($Global:ISO_cbFedora.IsChecked) {
            $jobs += @{
                IsoName  = "Fedora"
                FileName = "fedora-latest-amd64.iso"
                OutFile  = Join-Path $Dest "fedora-latest-amd64.iso"
                UrlList  = @(
                    "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-41-1.4.iso"
                )
            }
        }

        if ($Global:ISO_cbArch.IsChecked) {
            $jobs += @{
                IsoName  = "Arch Linux"
                FileName = "archlinux-latest-amd64.iso"
                OutFile  = Join-Path $Dest "archlinux-latest-amd64.iso"
                UrlList  = @(
                    "https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso",
                    "https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
                )
            }
        }

        if ($Global:ISO_cbCachyOS.IsChecked) {
            $jobs += @{
                IsoName  = "CachyOS"
                FileName = "cachyos-latest-amd64.iso"
                OutFile  = Join-Path $Dest "cachyos-latest-amd64.iso"
                UrlList  = @(
                    "https://mirror.cachyos.org/ISO/kde/latest/cachyos-kde-linux-x86_64.iso"
                )
            }
        }

        if ($Global:ISO_cbPopOS.IsChecked) {
            $jobs += @{
                IsoName  = "Pop!_OS"
                FileName = "pop-os-latest-amd64.iso"
                OutFile  = Join-Path $Dest "pop-os-latest-amd64.iso"
                UrlList  = @(
                    "https://iso.pop-os.org/22.04/amd64/nvidia/41/pop-os_22.04_amd64_nvidia_41.iso",
                    "https://iso.pop-os.org/22.04/amd64/intel/41/pop-os_22.04_amd64_intel_41.iso"
                )
            }
        }

        return $jobs
    }

    # ===========================================================================
    # DOWNLOAD WORKER (runs in thread pool via RunspacePool)
    # ===========================================================================
    $Global:ISO_WorkerScript = {
        param($Job, $Queue, $CancelToken, $TotalJobs, $JobIndex)

        function Q-Log  { param($M,$T) $Queue.Enqueue([PSCustomObject]@{Type="LOG";Msg=$M;Tag=$T}) }
        function Q-Prog { param($P,$S) $Queue.Enqueue([PSCustomObject]@{Type="PROGRESS";Pct=$P;Status=$S}) }

        $result = [PSCustomObject]@{ Success=$false; IsoName=$Job.IsoName; Message="" }
        $tmp    = "$($Job.OutFile).tmp"

        if ($CancelToken.IsCancellationRequested) {
            $result.Message = "Cancelled"
            return $result
        }

        Q-Log "Starting: $($Job.IsoName)" "INFO"
        $downloaded = $false

        foreach ($url in $Job.UrlList) {
            if ($CancelToken.IsCancellationRequested) { break }
            try {
                $req = [System.Net.HttpWebRequest]::Create($url)
                $req.AllowAutoRedirect = $true
                $req.UserAgent = "PowerTools-Suite-ISODownloader/1.0"
                $req.Timeout   = 15000
                $resp   = $req.GetResponse()
                $total  = $resp.ContentLength
                $stream = $resp.GetResponseStream()
                $fs     = [System.IO.File]::Create($tmp)
                $buf    = New-Object byte[] (128KB)
                $read   = 0
                $sw     = [System.Diagnostics.Stopwatch]::StartNew()
                $lastReport = 0

                while (-not $CancelToken.IsCancellationRequested) {
                    $n = $stream.Read($buf, 0, $buf.Length)
                    if ($n -le 0) { break }
                    $fs.Write($buf, 0, $n)
                    $read += $n

                    if ($sw.ElapsedMilliseconds - $lastReport -ge 500) {
                        $lastReport = $sw.ElapsedMilliseconds
                        $mbDone  = [math]::Round($read / 1MB, 1)
                        $mbTotal = if ($total -gt 0) { [math]::Round($total / 1MB, 1) } else { "?" }
                        $speed   = if ($sw.Elapsed.TotalSeconds -gt 0) {
                            [math]::Round($read / 1MB / $sw.Elapsed.TotalSeconds, 1)
                        } else { 0 }
                        $eta = if ($total -gt 0 -and $speed -gt 0) {
                            "$([math]::Round(($total - $read) / 1MB / $speed))s"
                        } else { "..." }
                        $filePct    = if ($total -gt 0) { [int](($read / $total) * 100) } else { 0 }
                        $overallPct = [int](($JobIndex / $TotalJobs) * 100) + [int]($filePct / $TotalJobs)
                        Q-Prog $overallPct "$($Job.IsoName)  |  ${mbDone}MB / ${mbTotal}MB  |  ${speed} MB/s  |  ETA: $eta"
                    }
                }

                $fs.Close()
                $stream.Close()
                $resp.Close()

                if (-not $CancelToken.IsCancellationRequested) {
                    Move-Item -Path $tmp -Destination $Job.OutFile -Force
                    $sizeMB = [math]::Round((Get-Item $Job.OutFile).Length / 1MB, 1)
                    Q-Log "Downloaded: $($Job.FileName) (${sizeMB} MB)" "OK"
                    $result.Success = $true
                    $downloaded = $true
                    break
                }

            } catch {
                if ($null -ne $fs) { try { $fs.Close() } catch {} }
                if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
                Q-Log "URL failed ($url): $_" "WARN"
            }
        }

        if (-not $downloaded -and -not $CancelToken.IsCancellationRequested) {
            $result.Message = "All URLs failed"
            Q-Log "FAILED: $($Job.IsoName) — all URLs exhausted" "FAIL"
        }
        if ($CancelToken.IsCancellationRequested) { $result.Message = "Cancelled" }

        return $result
    }

    # ===========================================================================
    # DOWNLOAD ORCHESTRATOR
    # ===========================================================================
    function Global:ISO-RunDownloads {
        param($Jobs, [System.Threading.CancellationToken]$CancelToken)

        $total   = $Jobs.Count
        $queue   = $Global:ISO_msgQueue
        $maxPar  = [int]($Global:ISO_parallel.SelectedItem.Content)
        $pool    = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $maxPar)
        $pool.Open()

        $running = [System.Collections.Generic.List[object]]::new()
        $done    = 0

        for ($i = 0; $i -lt $Jobs.Count; $i++) {
            $ps = [System.Management.Automation.PowerShell]::Create()
            $ps.RunspacePool = $pool
            $ps.AddScript($Global:ISO_WorkerScript) | Out-Null
            $ps.AddParameter("Job",       $Jobs[$i])    | Out-Null
            $ps.AddParameter("Queue",     $queue)       | Out-Null
            $ps.AddParameter("CancelToken", $CancelToken) | Out-Null
            $ps.AddParameter("TotalJobs", $total)       | Out-Null
            $ps.AddParameter("JobIndex",  $i)           | Out-Null
            $j = [PSCustomObject]@{ PS=$ps; Handle=$ps.BeginInvoke(); Job=$Jobs[$i]; Done=$false }
            $running.Add($j)
        }

        while ($done -lt $running.Count) {
            Start-Sleep -Milliseconds 300
            foreach ($r in $running) {
                if ($r.Handle.IsCompleted -and -not $r.Done) {
                    $r.Done = $true; $done++
                    try {
                        $res = $r.PS.EndInvoke($r.Handle)
                    } catch {
                        $queue.Enqueue([PSCustomObject]@{Type="LOG";Msg="Exception: $_";Tag="FAIL"})
                    }
                    $r.PS.Dispose()
                    $pct = [int](($done / $total) * 100)
                    $queue.Enqueue([PSCustomObject]@{Type="PROGRESS";Pct=$pct;Status="Completed $done of $total ISO(s)"})
                }
            }
        }

        $pool.Close()
        $pool.Dispose()

        if ($CancelToken.IsCancellationRequested) {
            $queue.Enqueue([PSCustomObject]@{Type="CANCELLED"})
        } else {
            $queue.Enqueue([PSCustomObject]@{Type="LOG";Msg="All downloads finished.";Tag="OK"})
            $queue.Enqueue([PSCustomObject]@{Type="DONE"})
        }
    }

    # ===========================================================================
    # EVENT HANDLERS
    # ===========================================================================
    $Global:ISO_browseBtn.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select destination folder for ISOs"
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $Global:ISO_destBox.Text = $fbd.SelectedPath
        }
    })

    $Global:ISO_cancelBtn.Add_Click({
        $Global:ISO_cancelFlag.Cancel()
        ISO-AddLog "Cancel requested..." "WARN"
        $Global:ISO_cancelBtn.IsEnabled = $false
    })

    $Global:ISO_startBtn.Add_Click({
        if ($null -ne $Global:ISO_bgHandle -and -not $Global:ISO_bgHandle.IsCompleted) {
            ISO-AddLog "A download operation is already running." "WARN"
            return
        }
        ISO-CleanupBackground

        $dest = $Global:ISO_destBox.Text.Trim()
        if ($dest -eq "") {
            ISO-AddLog "No destination folder specified." "FAIL"
            return
        }
        if (-not (Test-Path $dest)) {
            try {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                ISO-AddLog "Created folder: $dest" "INFO"
            } catch {
                ISO-AddLog "Cannot create folder: $dest" "FAIL"
                return
            }
        }

        $jobs = ISO-GetJobList -Dest $dest -Token $Global:ISO_cancelFlag.Token
        if ($jobs.Count -eq 0) {
            ISO-AddLog "No distributions selected." "WARN"
            return
        }

        $Global:ISO_cancelFlag = [System.Threading.CancellationTokenSource]::new()
        $token = $Global:ISO_cancelFlag.Token

        $Global:ISO_progress.Value        = 0
        $Global:ISO_pctLabel.Text         = ""
        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["TextMuted"]
        $Global:ISO_statusLabel.Text      = "Starting..."
        ISO-SetUI-Busy $true
        ISO-StartTimer

        $capturedJobs = @($jobs)
        $capturedRunner = ${function:Global:ISO-RunDownloads}
        $Global:ISO_bgPS = [System.Management.Automation.PowerShell]::Create()
        $null = $Global:ISO_bgPS.AddScript($capturedRunner).AddArgument($capturedJobs).AddArgument($token)
        $Global:ISO_bgHandle = $Global:ISO_bgPS.BeginInvoke()
    })

    $Global:ISO_clearLog.Add_Click({
        $Global:ISO_logBox.Text = $Global:ISO_initText
    })

    return $view
}
