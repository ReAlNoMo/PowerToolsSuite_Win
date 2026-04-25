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
                     FontSize="13" Padding="12,10" Background="#FFFFFF" Foreground="#111827"
                     BorderBrush="#D0D6F0" BorderThickness="1.5"
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

    <Border Grid.Row="6" Background="#FAFBFF" BorderBrush="#D8DEFA"
            BorderThickness="1.5" CornerRadius="10">
        <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
            <TextBlock x:Name="LogBox" Foreground="#8890B8"
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
    $Global:ISO_initText    = "Ready."
    $Global:ISO_msgQueue    = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:ISO_timer       = $null
    $Global:ISO_cancelFlag  = [System.Threading.CancellationTokenSource]::new()

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
                        $Global:ISO_progress.Value    = $item.Pct
                        $Global:ISO_statusLabel.Text  = $item.Status
                        $Global:ISO_pctLabel.Text     = "$($item.Pct)%"
                    }
                    "DONE" {
                        $Global:ISO_timer.Stop()
                        $Global:ISO_progress.Value        = 100
                        $Global:ISO_pctLabel.Text         = "100%"
                        $Global:ISO_statusLabel.Text      = "All downloads complete"
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Success"]
                        ISO-SetUI-Busy $false
                    }
                    "CANCELLED" {
                        $Global:ISO_timer.Stop()
                        $Global:ISO_statusLabel.Text      = "Cancelled"
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Warning"]
                        ISO-SetUI-Busy $false
                    }
                    "ERROR" {
                        $Global:ISO_timer.Stop()
                        $Global:ISO_statusLabel.Text      = "Error"
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                        ISO-SetUI-Busy $false
                    }
                }
            }
        })
        $Global:ISO_timer.Start()
    }

    # Resolve functions (run on UI thread before background starts — fast web lookups)
    function Global:ISO-GetWeb {
        param([string]$Url)
        $wr = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 20 `
              -Headers @{"User-Agent"="PowerTools-Suite-ISO"}
        return $wr.Content
    }

    function Global:ISO-TestUrl {
        param([string]$Url)
        try {
            $r = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 5
            return $r.StatusCode -lt 400
        } catch { return $false }
    }

    function Global:ISO-SelectMirror {
        param([string[]]$Urls)
        foreach ($u in $Urls) { if (ISO-TestUrl $u) { return $u } }
        return $Urls[-1]
    }

    function Global:ISO-ResolveUbuntu {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving Ubuntu latest LTS..." "INFO"
        $page  = ISO-GetWeb "https://releases.ubuntu.com/"
        $cands = [regex]::Matches($page,'href="(\d{2}\.04)\/"') | ForEach-Object {$_.Groups[1].Value} | Sort-Object -Descending
        $ver = $null; $hc = $null
        foreach ($c in $cands) {
            try {
                $t = ISO-GetWeb "https://releases.ubuntu.com/$c/SHA256SUMS"
                if (($t -split "`n") | Where-Object { $_ -match "amd64.*\.iso$" -and $_ -notmatch "beta" }) {
                    $ver = $c; $hc = $t; break
                }
            } catch {}
        }
        if (-not $ver) { ISO-AddLog "Ubuntu: no stable LTS found" "WARN"; return $jobs }
        ISO-AddLog "Ubuntu $ver found" "OK"
        $mirrors = @(
            "https://mirror.hs-esslingen.de/pub/Mirrors/releases.ubuntu.com/$ver",
            "https://ubuntu.mirror.lrz.de/releases/$ver",
            "https://releases.ubuntu.com/$ver"
        )
        foreach ($ed in @("desktop","live-server")) {
            $line = ($hc -split "`n") | Where-Object {
                $_ -match "amd64" -and $_ -match $ed -and $_ -match "\.iso$" -and $_ -notmatch "beta"
            } | Select-Object -First 1
            if (-not $line) { continue }
            $parts = $line.Trim() -split "\s+"; $hash = $parts[0]; $iso = $parts[1] -replace "^\*",""
            $out   = Join-Path $Dest $iso
            if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; continue }
            $urls  = $mirrors | ForEach-Object { "$_/$iso" }
            ISO-AddLog "Queued: $iso" "INFO"
            $jobs += @{ IsoName=$iso; Url=(ISO-SelectMirror $urls); UrlList=$urls; Hash=$hash; OutFile=$out }
        }
        return $jobs
    }

    function Global:ISO-ResolveDebian {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving Debian current release..." "INFO"
        try {
            $base = "https://cdimage.debian.org/debian-cd/current/amd64"
            $hc   = ISO-GetWeb "$base/iso-cd/SHA256SUMS"
            $m    = [regex]::Match($hc,'debian-(\d+\.\d+\.\d+)-amd64-netinst\.iso')
            if (-not $m.Success) { ISO-AddLog "Debian: version not found" "WARN"; return $jobs }
            $ver = $m.Groups[1].Value
            ISO-AddLog "Debian $ver found" "OK"
            $iso  = "debian-$ver-amd64-netinst.iso"
            $out  = Join-Path $Dest $iso
            if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; return $jobs }
            $line = ($hc -split "`n") | Where-Object { $_ -match [regex]::Escape($iso) } | Select-Object -First 1
            $hash = ($line -split "\s+")[0]
            $urls = @(
                "https://ftp.de.debian.org/debian-cd/$ver/amd64/iso-cd/$iso",
                "$base/iso-cd/$iso"
            )
            ISO-AddLog "Queued: $iso" "INFO"
            $jobs += @{ IsoName=$iso; Url=(ISO-SelectMirror $urls); UrlList=$urls; Hash=$hash; OutFile=$out }
        } catch { ISO-AddLog "Debian resolve error: $_" "FAIL" }
        return $jobs
    }

    function Global:ISO-ResolveFedora {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving Fedora latest release..." "INFO"
        try {
            $idx = ISO-GetWeb "https://dl.fedoraproject.org/pub/fedora/linux/releases/"
            $ver = [regex]::Matches($idx,'<a href="(\d+)/"') |
                   ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object -Descending | Select-Object -First 1
            if (-not $ver) { ISO-AddLog "Fedora: version not found" "WARN"; return $jobs }
            $wsIdx = ISO-GetWeb "https://dl.fedoraproject.org/pub/fedora/linux/releases/$ver/Workstation/x86_64/iso/"
            $build = [regex]::Matches($wsIdx,"Fedora-Workstation-Live-x86_64-$ver-(\d+\.\d+)\.iso") |
                     ForEach-Object { $_.Groups[1].Value } | Sort-Object -Descending | Select-Object -First 1
            if (-not $build) { ISO-AddLog "Fedora: build tag not found" "WARN"; return $jobs }
            ISO-AddLog "Fedora $ver (build $build) found" "OK"
            $iso  = "Fedora-Workstation-Live-x86_64-$ver-$build.iso"
            $out  = Join-Path $Dest $iso
            if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; return $jobs }
            $url  = "https://dl.fedoraproject.org/pub/fedora/linux/releases/$ver/Workstation/x86_64/iso/$iso"
            ISO-AddLog "Queued: $iso" "INFO"
            $jobs += @{ IsoName=$iso; Url=$url; UrlList=@($url); Hash=$null; OutFile=$out }
        } catch { ISO-AddLog "Fedora resolve error: $_" "FAIL" }
        return $jobs
    }

    function Global:ISO-ResolveArch {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving Arch latest ISO..." "INFO"
        try {
            $base = "https://mirror.rackspace.com/archlinux/iso/latest"
            $page = ISO-GetWeb $base
            $iso  = [regex]::Matches($page,'archlinux-\d{4}\.\d{2}\.\d{2}-x86_64\.iso') |
                    ForEach-Object { $_.Value } | Select-Object -First 1
            if (-not $iso) { ISO-AddLog "Arch: ISO not found" "WARN"; return $jobs }
            ISO-AddLog "Arch $iso found" "OK"
            $out  = Join-Path $Dest $iso
            if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; return $jobs }
            ISO-AddLog "Queued: $iso" "INFO"
            $jobs += @{ IsoName=$iso; Url="$base/$iso"; UrlList=@("$base/$iso"); Hash=$null; OutFile=$out }
        } catch { ISO-AddLog "Arch resolve error: $_" "FAIL" }
        return $jobs
    }

    function Global:ISO-ResolveCachyOS {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving CachyOS latest release..." "INFO"
        try {
            $api   = ISO-GetWeb "https://api.github.com/repos/CachyOS/CachyOS-ISO/releases/latest"
            $obj   = $api | ConvertFrom-Json
            $asset = $obj.assets | Where-Object { $_.name -match "cachyos-desktop-linux.*\.iso$" } | Select-Object -First 1
            if (-not $asset) { ISO-AddLog "CachyOS: asset not found" "WARN"; return $jobs }
            ISO-AddLog "CachyOS $($asset.name) found" "OK"
            $out   = Join-Path $Dest $asset.name
            if (Test-Path $out) { ISO-AddLog "Already exists: $($asset.name)" "OK"; return $jobs }
            ISO-AddLog "Queued: $($asset.name)" "INFO"
            $jobs += @{ IsoName=$asset.name; Url=$asset.browser_download_url; UrlList=@($asset.browser_download_url); Hash=$null; OutFile=$out }
        } catch { ISO-AddLog "CachyOS resolve error: $_" "FAIL" }
        return $jobs
    }

    function Global:ISO-ResolvePopOS {
        param([string]$Dest)
        $jobs   = @()
        ISO-AddLog "Resolving Pop!_OS latest revision..." "INFO"
        $baseVer = "24.04"; $isoBase = "https://iso.pop-os.org/$baseVer/amd64"; $rev = $null
        for ($i = 60; $i -ge 1; $i--) {
            try {
                $c = (Invoke-WebRequest -Uri "$isoBase/intel/$i/SHA256SUMS" -UseBasicParsing -TimeoutSec 5 `
                      -Headers @{"User-Agent"="PowerTools-Suite-ISO"}).Content
                if ($c -match "pop-os") { $rev = $i; break }
            } catch {}
        }
        if (-not $rev) { ISO-AddLog "Pop!_OS: revision not found" "WARN"; return $jobs }
        ISO-AddLog "Pop!_OS $baseVer rev $rev found" "OK"
        foreach ($v in @("intel","nvidia")) {
            try {
                $iso  = "pop-os_${baseVer}_amd64_${v}_${rev}.iso"
                $url  = "$isoBase/$v/$rev/$iso"
                $out  = Join-Path $Dest $iso
                if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; continue }
                $sums = (Invoke-WebRequest -Uri "$isoBase/$v/$rev/SHA256SUMS" -UseBasicParsing -TimeoutSec 10 `
                         -Headers @{"User-Agent"="PowerTools-Suite-ISO"}).Content
                $line = ($sums -split "`n") | Where-Object { $_ -match [regex]::Escape($iso) } | Select-Object -First 1
                $hash = if ($line) { ($line -split "\s+")[0] } else { $null }
                ISO-AddLog "Queued: $iso" "INFO"
                $jobs += @{ IsoName=$iso; Url=$url; UrlList=@($url); Hash=$hash; OutFile=$out }
            } catch { ISO-AddLog "Pop!_OS $v`: $_" "WARN" }
        }
        return $jobs
    }

    # Background download script — runs in Runspace, reports via Queue
    $Global:ISO_downloadScript = {
        param($AllJobs, $MaxParallel, $Queue, $CancelToken)

        function Q-Log  { param($M,$T="INFO") $Queue.Enqueue([PSCustomObject]@{Type="LOG";Msg=$M;Tag=$T}) }
        function Q-Prog { param($P,$S)        $Queue.Enqueue([PSCustomObject]@{Type="PROGRESS";Pct=$P;Status=$S}) }

        $total    = $AllJobs.Count
        $done     = 0
        $pool     = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxParallel)
        $pool.Open()

        # Per-file download scriptblock
        $dlScript = {
            param($Job, $Queue, $CancelToken)

            function Q-Log  { param($M,$T="INFO") $Queue.Enqueue([PSCustomObject]@{Type="LOG";Msg=$M;Tag=$T}) }
            function Q-Prog { param($P,$S)        $Queue.Enqueue([PSCustomObject]@{Type="PROGRESS";Pct=$P;Status=$S}) }

            $out = $Job.OutFile; $tmp = "$out.part"
            $result = @{ IsoName=$Job.IsoName; Success=$false; Message="" }

            try {
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
                        $req.Timeout = 15000
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

                            # Report progress every ~500ms
                            if ($sw.ElapsedMilliseconds - $lastReport -ge 500) {
                                $lastReport = $sw.ElapsedMilliseconds
                                $mbDone  = [math]::Round($read / 1MB, 1)
                                $mbTotal = if ($total -gt 0) { [math]::Round($total / 1MB, 1) } else { "?" }
                                $speed   = if ($sw.Elapsed.TotalSeconds -gt 0) {
                                    [math]::Round($read / 1MB / $sw.Elapsed.TotalSeconds, 2)
                                } else { 0 }
                                $eta = if ($total -gt 0 -and $speed -gt 0) {
                                    $secLeft = [math]::Round(($total - $read) / 1MB / $speed)
                                    "${secLeft}s"
                                } else { "..." }
                                Q-Log "$($Job.IsoName): $mbDone MB / $mbTotal MB  |  ${speed} MB/s  |  ETA: $eta" "INFO"
                            }
                        }

                        $fs.Close(); $stream.Close(); $resp.Close()
                        $downloaded = $true
                        break
                    } catch {
                        if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
                        Q-Log "$($Job.IsoName): mirror failed, trying next..." "WARN"
                    }
                }

                if ($CancelToken.IsCancellationRequested) {
                    if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
                    $result.Message = "Cancelled"
                    return $result
                }

                if (-not $downloaded) { throw "All mirror URLs failed" }

                Move-Item -Path $tmp -Destination $out -Force
                Q-Log "$($Job.IsoName): download complete, verifying..." "INFO"

                # Hash verification
                if ($Job.Hash) {
                    $h   = [System.Security.Cryptography.SHA256]::Create()
                    $fs2 = [System.IO.File]::OpenRead($out)
                    $b2  = New-Object byte[] (1MB)
                    while ($true) {
                        $r = $fs2.Read($b2, 0, $b2.Length)
                        if ($r -le 0) { break }
                        $h.TransformBlock($b2, 0, $r, $null, 0) | Out-Null
                    }
                    $h.TransformFinalBlock(@(), 0, 0) | Out-Null
                    $fs2.Close()
                    $actual = ($h.Hash | ForEach-Object { $_.ToString("x2") }) -join ""
                    if ($actual -ne $Job.Hash.ToLower().Trim()) {
                        Remove-Item $out -Force
                        throw "Hash mismatch — file removed"
                    }
                    Q-Log "$($Job.IsoName): hash verified OK" "OK"
                }

                $result.Success = $true
                $result.Message = "Done"
            }
            catch {
                if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
                $result.Message = "$_"
            }
            return $result
        }

        # Launch all jobs
        $running = @()
        foreach ($j in $AllJobs) {
            if ($CancelToken.IsCancellationRequested) { break }
            $ps = [System.Management.Automation.PowerShell]::Create()
            $ps.RunspacePool = $pool
            $ps.AddScript($dlScript).AddArgument($j).AddArgument($Queue).AddArgument($CancelToken) | Out-Null
            $running += @{ PS=$ps; Handle=$ps.BeginInvoke(); Job=$j; Done=$false }
        }

        # Poll until all done
        while ($done -lt $running.Count) {
            Start-Sleep -Milliseconds 300

            if ($CancelToken.IsCancellationRequested) {
                $Queue.Enqueue([PSCustomObject]@{Type="LOG";Msg="Cancel requested — waiting for active downloads to stop...";Tag="WARN"})
            }

            foreach ($r in $running) {
                if ($r.Handle.IsCompleted -and -not $r.Done) {
                    $r.Done = $true; $done++
                    try {
                        $res = $r.PS.EndInvoke($r.Handle)
                        if ($res.Success) {
                            Q-Log "[$done/$total] $($res.IsoName) — complete" "OK"
                        } elseif ($res.Message -eq "Cancelled") {
                            Q-Log "[$done/$total] $($res.IsoName) — cancelled" "WARN"
                        } else {
                            Q-Log "[$done/$total] $($res.IsoName) — FAILED: $($res.Message)" "FAIL"
                        }
                    } catch {
                        Q-Log "[$done/$total] $($r.Job.IsoName) — exception: $_" "FAIL"
                    }
                    $r.PS.Dispose()
                    $pct = [int](($done / $total) * 100)
                    Q-Prog $pct "Completed $done of $total ISO(s)"
                }
            }
        }

        $pool.Close()
        $pool.Dispose()

        if ($CancelToken.IsCancellationRequested) {
            $Queue.Enqueue([PSCustomObject]@{Type="CANCELLED"})
        } else {
            Q-Log "All downloads finished." "OK"
            $Queue.Enqueue([PSCustomObject]@{Type="DONE"})
        }
    }

    # -----------------------------------------------------------------------
    # EVENT HANDLERS
    # -----------------------------------------------------------------------
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
        $dest = $Global:ISO_destBox.Text.Trim()
        if ($dest -eq "") { ISO-AddLog "No destination folder." "WARN"; return }

        if (-not (Test-Path $dest)) {
            try { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
            catch { ISO-AddLog "Cannot create folder: $_" "FAIL"; return }
            ISO-AddLog "Created folder: $dest" "INFO"
        }

        # Resolve all jobs on UI thread (fast lookups only)
        ISO-AddLog "Resolving versions..." "INFO"
        $allJobs = @()
        try {
            if ($Global:ISO_cbUbuntu.IsChecked)  { $allJobs += ISO-ResolveUbuntu  -Dest $dest }
            if ($Global:ISO_cbDebian.IsChecked)  { $allJobs += ISO-ResolveDebian  -Dest $dest }
            if ($Global:ISO_cbFedora.IsChecked)  { $allJobs += ISO-ResolveFedora  -Dest $dest }
            if ($Global:ISO_cbArch.IsChecked)    { $allJobs += ISO-ResolveArch    -Dest $dest }
            if ($Global:ISO_cbCachyOS.IsChecked) { $allJobs += ISO-ResolveCachyOS -Dest $dest }
            if ($Global:ISO_cbPopOS.IsChecked)   { $allJobs += ISO-ResolvePopOS   -Dest $dest }
        } catch {
            ISO-AddLog "Resolve error: $_" "FAIL"; return
        }

        if ($allJobs.Count -eq 0) {
            ISO-AddLog "Nothing to download — all ISOs already exist or none selected." "OK"
            return
        }

        $max = [int]$Global:ISO_parallel.Text
        ISO-AddLog "$($allJobs.Count) ISO(s) queued  |  max $max parallel download(s)" "INFO"

        # Reset state
        $Global:ISO_cancelFlag              = [System.Threading.CancellationTokenSource]::new()
        $Global:ISO_msgQueue                = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
        $Global:ISO_progress.Value          = 0
        $Global:ISO_pctLabel.Text           = "0%"
        $Global:ISO_statusLabel.Text        = "Starting downloads..."
        $Global:ISO_statusLabel.Foreground  = $Global:PTS_Brush["TextMuted"]

        ISO-SetUI-Busy $true
        ISO-StartTimer

        # Launch background runspace
        $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $rs.Open()
        $ps = [System.Management.Automation.PowerShell]::Create()
        $ps.Runspace = $rs
        $ps.AddScript($Global:ISO_downloadScript) | Out-Null
        $ps.AddArgument($allJobs)                 | Out-Null
        $ps.AddArgument($max)                     | Out-Null
        $ps.AddArgument($Global:ISO_msgQueue)     | Out-Null
        $ps.AddArgument($Global:ISO_cancelFlag.Token) | Out-Null
        $ps.BeginInvoke() | Out-Null
    })

    $Global:ISO_clearLog.Add_Click({
        $Global:ISO_logBox.Text = ""
        ISO-AddLog "Log cleared." "INFO"
    })

    return $view
}
