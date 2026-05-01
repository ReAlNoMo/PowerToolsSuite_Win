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
            <TextBox Grid.Column="0" x:Name="DestBox" Text="" Height="40"
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
        <TextBox x:Name="LogBox"
                 IsReadOnly="True"
                 IsReadOnlyCaretVisible="True"
                 Focusable="True"
                 IsTabStop="True"
                 AcceptsReturn="True"
                 TextWrapping="Wrap"
                 VerticalScrollBarVisibility="Auto"
                 HorizontalScrollBarVisibility="Disabled"
                 BorderThickness="0"
                 Background="Transparent"
                 FontFamily="Cascadia Code, Consolas, Courier New"
                 FontSize="12"
                 Padding="16,12"
                 Text="Ready."/>
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
    $Global:ISO_logBorder   = $view.FindName("LogBorder")
    $Global:ISO_initText    = "Ready."
    $Global:ISO_msgQueue    = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:ISO_timer       = $null
    $Global:ISO_cancelFlag  = [System.Threading.CancellationTokenSource]::new()
    $Global:ISO_bgPS        = $null
    $Global:ISO_bgHandle    = $null

    # Set default destination to user Downloads folder
    $defaultDest = Join-Path $env:USERPROFILE "Downloads\ISOs"
    if ([string]::IsNullOrWhiteSpace($Global:ISO_destBox.Text)) {
        $Global:ISO_destBox.Text = $defaultDest
    }

    # Apply theme-aware colors to TextBox and Log border
    $Global:ISO_destBox.Background  = $Global:PTS_Brush["InputBg"]
    $Global:ISO_destBox.Foreground  = $Global:PTS_Brush["InputFg"]
    $Global:ISO_destBox.BorderBrush = $Global:PTS_Brush["Border"]
    $Global:ISO_cbUbuntu.Foreground = $Global:PTS_Brush["TextMid"]
    $Global:ISO_cbDebian.Foreground = $Global:PTS_Brush["TextMid"]
    $Global:ISO_cbFedora.Foreground = $Global:PTS_Brush["TextMid"]
    $Global:ISO_cbArch.Foreground   = $Global:PTS_Brush["TextMid"]
    $Global:ISO_cbCachyOS.Foreground= $Global:PTS_Brush["TextMid"]
    $Global:ISO_cbPopOS.Foreground  = $Global:PTS_Brush["TextMid"]
    $Global:ISO_parallel.Foreground = $Global:PTS_Brush["InputFg"]
    $Global:ISO_parallel.Background = $Global:PTS_Brush["InputBg"]
    $Global:ISO_parallel.BorderBrush= $Global:PTS_Brush["Border"]
    foreach ($cbItem in $Global:ISO_parallel.Items) {
        if ($cbItem -is [System.Windows.Controls.ComboBoxItem]) {
            $cbItem.Foreground = $Global:PTS_Brush["InputFg"]
            $cbItem.Background = $Global:PTS_Brush["InputBg"]
        }
    }
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
        $Global:ISO_logBox.ScrollToEnd()
    }

    function Global:ISO-GetInnerScrollViewer {
        param([System.Windows.DependencyObject]$Root)
        if ($null -eq $Root) { return $null }
        if ($Root -is [System.Windows.Controls.ScrollViewer]) { return $Root }
        $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Root)
        for ($idx = 0; $idx -lt $count; $idx++) {
            $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Root, $idx)
            $found = ISO-GetInnerScrollViewer -Root $child
            if ($null -ne $found) { return $found }
        }
        return $null
    }

    $wheelHandlerISO = [System.Windows.Input.MouseWheelEventHandler]{
        param($sender, $e)
        try {
            $sv = ISO-GetInnerScrollViewer -Root $sender
            if ($sv -is [System.Windows.Controls.ScrollViewer]) {
                $step = if ($e.Delta -gt 0) { -3 } else { 3 }
                $newOffset = $sv.VerticalOffset + $step
                if ($newOffset -lt 0) { $newOffset = 0 }
                if ($newOffset -gt $sv.ScrollableHeight) { $newOffset = $sv.ScrollableHeight }
                $sv.ScrollToVerticalOffset($newOffset)
                $e.Handled = $true
            }
        } catch {
            # keep default behavior
        }
    }
    $Global:ISO_logBox.AddHandler([System.Windows.UIElement]::PreviewMouseWheelEvent, $wheelHandlerISO, $true)
    $Global:ISO_logBox.AddHandler([System.Windows.UIElement]::MouseWheelEvent,        $wheelHandlerISO, $true)

    $Global:ISO_logBox.Add_PreviewKeyDown({
        param($sender, $e)
        if (($e.KeyboardDevice.Modifiers -band [System.Windows.Input.ModifierKeys]::Control) -and $e.Key -eq [System.Windows.Input.Key]::A) {
            $sender.SelectAll()
            $e.Handled = $true
        }
    })

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
    # RELEASE URL RESOLVERS
    # ===========================================================================
    function Global:ISO-EnableTls {
        try {
            $proto = [System.Net.SecurityProtocolType]::Tls12
            if ([enum]::GetNames([System.Net.SecurityProtocolType]) -contains "Tls13") {
                $proto = $proto -bor [System.Net.SecurityProtocolType]::Tls13
            }
            [System.Net.ServicePointManager]::SecurityProtocol = $proto
        } catch {}
    }

    function Global:ISO-GetNewestVersion {
        param([string[]]$Versions)
        $parsed = foreach ($v in ($Versions | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
            try {
                [PSCustomObject]@{ Raw = $v; Ver = [version]$v }
            } catch {}
        }
        if (-not $parsed) { return $null }
        return ($parsed | Sort-Object Ver -Descending | Select-Object -First 1).Raw
    }

    function Global:ISO-GetRedirectLocation {
        param([string]$Url)
        try {
            $hdr = & curl.exe -I --max-time 20 $Url 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $hdr) { return $null }
            foreach ($line in $hdr) {
                if ($line -match "^[Ll]ocation:\s*(\S+)\s*$") {
                    return $Matches[1].Trim()
                }
            }
        } catch {}
        return $null
    }

    function Global:ISO-GetLatestUbuntuUrls {
        ISO-EnableTls
        try {
            $index = (Invoke-WebRequest -UseBasicParsing -Uri "https://releases.ubuntu.com/releases/" -TimeoutSec 25 -ErrorAction Stop).Content
            $versions = [regex]::Matches($index, "Ubuntu\s+(\d+\.\d+(?:\.\d+)?)") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            $latest = ISO-GetNewestVersion -Versions $versions
            if (-not $latest) { return @() }

            $dirContent = (Invoke-WebRequest -UseBasicParsing -Uri ("https://releases.ubuntu.com/{0}/" -f $latest) -TimeoutSec 25 -ErrorAction Stop).Content
            $isoFiles = [regex]::Matches($dirContent, "ubuntu-[0-9.]+-desktop-amd64\.iso") | ForEach-Object { $_.Value } | Select-Object -Unique
            if (-not $isoFiles -or $isoFiles.Count -eq 0) {
                $isoFiles = @("ubuntu-$latest-desktop-amd64.iso")
            }

            $urls = New-Object System.Collections.Generic.List[string]
            foreach ($iso in $isoFiles) {
                $urls.Add("https://mirrors.edge.kernel.org/ubuntu-releases/$latest/$iso")
                $urls.Add("https://releases.ubuntu.com/$latest/$iso")
            }
            return @($urls | Select-Object -Unique)
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestDebianUrls {
        ISO-EnableTls
        try {
            $downloadPage = (Invoke-WebRequest -UseBasicParsing -Uri "https://www.debian.org/download.en.html" -TimeoutSec 25 -ErrorAction Stop).Content
            $isoName = [regex]::Match($downloadPage, "debian-\d+(?:\.\d+){2}-amd64-netinst\.iso").Value
            if (-not $isoName) { return @() }

            $primary = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$isoName"
            $knownMirror = "https://saimei.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/$isoName"
            $mirror = ISO-GetRedirectLocation -Url $primary

            $list = New-Object System.Collections.Generic.List[string]
            if (-not [string]::IsNullOrWhiteSpace($mirror)) { $list.Add($mirror) }
            $list.Add($knownMirror)
            $list.Add($primary)
            return @($list | Select-Object -Unique)
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestFedoraUrls {
        ISO-EnableTls
        try {
            $pkgPage = (Invoke-WebRequest -UseBasicParsing -Uri "https://packages.fedoraproject.org/pkgs/fedora-release/fedora-release/" -TimeoutSec 25 -ErrorAction Stop).Content
            $versions = [regex]::Matches($pkgPage, "Fedora\s+(\d+)") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            $release = ($versions | ForEach-Object { [int]$_ } | Sort-Object -Descending | Select-Object -First 1)
            if (-not $release) { return @() }

            $bases = @(
                "https://download.fedoraproject.org/pub/fedora/linux/releases",
                "https://download-ib01.fedoraproject.org/pub/fedora/linux/releases"
            )

            $resolvedName = $null
            for ($minor = 9; $minor -ge 0 -and -not $resolvedName; $minor--) {
                $rev = "1.$minor"
                foreach ($candidateName in @(
                    "Fedora-Workstation-Live-$release-$rev.x86_64.iso",
                    "Fedora-Workstation-Live-x86_64-$release-$rev.iso"
                )) {
                    $probeUrl = "$($bases[0])/$release/Workstation/x86_64/iso/$candidateName"
                    $code = (& curl.exe -I -L --max-time 15 -s -o NUL -w "%{http_code}" $probeUrl 2>$null)
                    if ($LASTEXITCODE -eq 0 -and $code -eq "200") {
                        $resolvedName = $candidateName
                        break
                    }
                }
            }

            if ($resolvedName) {
                return @($bases | ForEach-Object { "$_/$release/Workstation/x86_64/iso/$resolvedName" })
            }

            $urls = New-Object System.Collections.Generic.List[string]
            foreach ($base in $bases) {
                for ($minor = 9; $minor -ge 0; $minor--) {
                    $rev = "1.$minor"
                    $urls.Add("$base/$release/Workstation/x86_64/iso/Fedora-Workstation-Live-$release-$rev.x86_64.iso")
                    $urls.Add("$base/$release/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-$release-$rev.iso")
                }
            }
            return @($urls | Select-Object -Unique)
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestCachyOSUrls {
        ISO-EnableTls
        try {
            $index = Invoke-WebRequest -UseBasicParsing -Uri "https://mirror.cachyos.org/ISO/desktop/" -TimeoutSec 25 -ErrorAction Stop
            $dirs = $index.Links | Where-Object { $_.href -match "^\d{6}/$" } | ForEach-Object { $_.href.TrimEnd("/") }
            if (-not $dirs -or $dirs.Count -eq 0) { return @() }

            $latestDir = ($dirs | Sort-Object -Descending | Select-Object -First 1)
            $dirPage = Invoke-WebRequest -UseBasicParsing -Uri "https://mirror.cachyos.org/ISO/desktop/$latestDir/" -TimeoutSec 25 -ErrorAction Stop
            $iso = $dirPage.Links | Where-Object { $_.href -match "^cachyos-desktop-linux-\d{6}\.iso$" } | Select-Object -First 1 -ExpandProperty href
            if (-not $iso) { $iso = "cachyos-desktop-linux-$latestDir.iso" }

            return @("https://mirror.cachyos.org/ISO/desktop/$latestDir/$iso")
        } catch {
            return @()
        }
    }

    # ===========================================================================
    # ISO DEFINITIONS
    # ===========================================================================
    function Global:ISO-GetJobList {
        param([string]$Dest, [System.Threading.CancellationToken]$Token)

        $jobs = @()

        if ($Global:ISO_cbUbuntu.IsChecked) {
            $ubuntuUrls = ISO-GetLatestUbuntuUrls
            if (-not $ubuntuUrls -or $ubuntuUrls.Count -eq 0) {
                $ubuntuUrls = @(
                    "https://mirrors.edge.kernel.org/ubuntu-releases/26.04/ubuntu-26.04-desktop-amd64.iso",
                    "https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso",
                    "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso"
                )
            }

            $jobs += @{
                IsoName  = "Ubuntu"
                FileName = "ubuntu-latest-amd64.iso"
                OutFile  = Join-Path $Dest "ubuntu-latest-amd64.iso"
                UrlList  = @($ubuntuUrls)
            }
        }

        if ($Global:ISO_cbDebian.IsChecked) {
            $debianUrls = ISO-GetLatestDebianUrls
            if (-not $debianUrls -or $debianUrls.Count -eq 0) {
                $debianUrls = @(
                    "https://saimei.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso",
                    "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"
                )
            }

            $jobs += @{
                IsoName  = "Debian"
                FileName = "debian-latest-amd64.iso"
                OutFile  = Join-Path $Dest "debian-latest-amd64.iso"
                UrlList  = @($debianUrls)
            }
        }

        if ($Global:ISO_cbFedora.IsChecked) {
            $fedoraUrls = ISO-GetLatestFedoraUrls
            if (-not $fedoraUrls -or $fedoraUrls.Count -eq 0) {
                $fedoraUrls = @(
                    "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Workstation/x86_64/iso/Fedora-Workstation-Live-44-1.7.x86_64.iso",
                    "https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/44/Workstation/x86_64/iso/Fedora-Workstation-Live-44-1.7.x86_64.iso"
                )
            }

            $jobs += @{
                IsoName  = "Fedora"
                FileName = "fedora-latest-amd64.iso"
                OutFile  = Join-Path $Dest "fedora-latest-amd64.iso"
                UrlList  = @($fedoraUrls)
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
            $cachyUrls = ISO-GetLatestCachyOSUrls
            if (-not $cachyUrls -or $cachyUrls.Count -eq 0) {
                $cachyUrls = @(
                    "https://mirror.cachyos.org/ISO/desktop/260426/cachyos-desktop-linux-260426.iso",
                    "https://iso.cachyos.org/desktop/260426/cachyos-desktop-linux-260426.iso"
                )
            }

            $jobs += @{
                IsoName  = "CachyOS"
                FileName = "cachyos-latest-amd64.iso"
                OutFile  = Join-Path $Dest "cachyos-latest-amd64.iso"
                UrlList  = @($cachyUrls)
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
        function Q-Err {
            param(
                [string]$Context,
                [string]$Url,
                [int]$Attempt,
                [System.Exception]$Exception,
                [string]$ExtraMessage
            )

            if ([string]::IsNullOrWhiteSpace($Job.ErrorLogPath)) { return }
            try {
                $entry = [ordered]@{
                    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
                    context       = $Context
                    module_id     = "linux-iso-downloader"
                    distro        = $Job.IsoName
                    output_file   = $Job.OutFile
                    url           = $Url
                    attempt       = $Attempt
                    machine_name  = $env:COMPUTERNAME
                    ps_version    = $PSVersionTable.PSVersion.ToString()
                    process_id    = $PID
                    exception     = if ($Exception) {
                        [ordered]@{
                            type      = $Exception.GetType().FullName
                            message   = $Exception.Message
                            hresult   = $Exception.HResult
                            source    = $Exception.Source
                            stack     = $Exception.StackTrace
                            inner_msg = if ($Exception.InnerException) { $Exception.InnerException.Message } else { $null }
                        }
                    } else { $null }
                    message       = $ExtraMessage
                }

                [System.IO.File]::AppendAllText(
                    $Job.ErrorLogPath,
                    (($entry | ConvertTo-Json -Depth 7 -Compress) + [Environment]::NewLine),
                    [System.Text.UTF8Encoding]::new($false)
                )
            } catch {}
        }

        $result = [PSCustomObject]@{ Success=$false; IsoName=$Job.IsoName; Message="" }
        $tmp    = "$($Job.OutFile).tmp"
        $fs = $null
        $stream = $null
        $resp = $null

        try {
            $proto = [System.Net.SecurityProtocolType]::Tls12
            if ([enum]::GetNames([System.Net.SecurityProtocolType]) -contains "Tls13") {
                $proto = $proto -bor [System.Net.SecurityProtocolType]::Tls13
            }
            [System.Net.ServicePointManager]::SecurityProtocol = $proto
        } catch {}

        if ($CancelToken.IsCancellationRequested) {
            $result.Message = "Cancelled"
            return $result
        }

        Q-Log "Starting: $($Job.IsoName)" "INFO"
        $downloaded = $false

        foreach ($url in $Job.UrlList) {
            if ($CancelToken.IsCancellationRequested) { break }
            for ($attempt = 1; $attempt -le 2 -and -not $downloaded; $attempt++) {
                if ($CancelToken.IsCancellationRequested) { break }
                try {
                    $req = [System.Net.HttpWebRequest]::Create($url)
                    $req.AllowAutoRedirect = $true
                    $req.UserAgent = "PowerTools-Suite-ISODownloader/1.0"
                    $req.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
                    $req.KeepAlive = $true
                    $req.Timeout = 60000
                    $req.ReadWriteTimeout = 60000
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
                    $fs = $null
                    $stream = $null
                    $resp = $null

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
                    if ($null -ne $stream) { try { $stream.Close() } catch {} }
                    if ($null -ne $resp) { try { $resp.Close() } catch {} }
                    $fs = $null
                    $stream = $null
                    $resp = $null
                    if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }

                    $msg = $_.Exception.Message
                    Q-Log "URL failed ($url) [attempt $attempt/2]: $msg" "WARN"
                    Q-Err -Context "LinuxISO.DownloadAttemptFailed" -Url $url -Attempt $attempt -Exception $_.Exception -ExtraMessage $_.ToString()

                    if ($attempt -lt 2 -and -not $CancelToken.IsCancellationRequested) {
                        Start-Sleep -Seconds (2 * $attempt)
                    }
                }
            }
            if ($downloaded) { break }
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
        param(
            [object[]]$Jobs,
            [System.Threading.CancellationToken]$CancelToken,
            [System.Collections.Concurrent.ConcurrentQueue[object]]$Queue,
            [int]$MaxPar,
            [scriptblock]$WorkerScript
        )

        try {
            if (-not $Jobs -or $Jobs.Count -eq 0) {
                $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "No download jobs received by coordinator."; Tag = "FAIL" })
                $Queue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
                return
            }

            $total = $Jobs.Count
            if ($MaxPar -lt 1) { $MaxPar = 1 }
            if ($MaxPar -gt $total) { $MaxPar = $total }

            $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxPar)
            $pool.Open()

            $running = [System.Collections.Generic.List[object]]::new()
            $done = 0
            $ok = 0
            $failed = 0

            for ($i = 0; $i -lt $Jobs.Count; $i++) {
                if ($CancelToken.IsCancellationRequested) { break }
                $Queue.Enqueue([PSCustomObject]@{
                    Type = "LOG"
                    Msg  = "Queueing job: $($Jobs[$i].IsoName)"
                    Tag  = "INFO"
                })
                $ps = [System.Management.Automation.PowerShell]::Create()
                $ps.RunspacePool = $pool
                $null = $ps.AddScript($WorkerScript).AddArgument($Jobs[$i]).AddArgument($Queue).AddArgument($CancelToken).AddArgument($total).AddArgument($i)
                $running.Add([PSCustomObject]@{ PS = $ps; Handle = $ps.BeginInvoke(); Job = $Jobs[$i]; Done = $false })
            }

            while ($done -lt $running.Count) {
                Start-Sleep -Milliseconds 300
                foreach ($r in $running) {
                    if ($r.Handle.IsCompleted -and -not $r.Done) {
                        $r.Done = $true
                        $done++
                        try {
                            $res = $r.PS.EndInvoke($r.Handle)
                            if ($res -and $res.Count -gt 0 -and $res[0].Success) {
                                $ok++
                            } else {
                                $failed++
                                $reason = if ($res -and $res.Count -gt 0 -and $res[0].Message) { $res[0].Message } else { "No reason returned" }
                                $Queue.Enqueue([PSCustomObject]@{
                                    Type = "LOG"
                                    Msg  = "Job failed: $($r.Job.IsoName) ($reason)"
                                    Tag  = "FAIL"
                                })
                            }
                        } catch {
                            $failed++
                            $Queue.Enqueue([PSCustomObject]@{
                                Type = "LOG"
                                Msg  = "Worker exception: $($_.ToString())"
                                Tag  = "FAIL"
                            })
                        } finally {
                            $r.PS.Dispose()
                        }
                        $pct = [int](($done / $total) * 100)
                        $Queue.Enqueue([PSCustomObject]@{
                            Type   = "PROGRESS"
                            Pct    = $pct
                            Status = "Completed $done of $total ISO(s)"
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
                $Queue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
            } else {
                $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "All downloads finished."; Tag = "OK" })
                $Queue.Enqueue([PSCustomObject]@{ Type = "DONE" })
            }
        } catch {
            $Queue.Enqueue([PSCustomObject]@{
                Type = "LOG"
                Msg  = "Fatal coordinator error: $($_.ToString())"
                Tag  = "FAIL"
            })
            $Queue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
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
        try {
            ISO-AddLog "Start requested." "INFO"

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

            $errorLogPath = if (Get-Command -Name Get-PowerToolsErrorLogPath -ErrorAction SilentlyContinue) {
                Get-PowerToolsErrorLogPath
            } else {
                Join-Path $env:TEMP "PowerToolsSuite-errors.jsonl"
            }
            foreach ($job in $jobs) {
                $job.ErrorLogPath = $errorLogPath
            }

            ISO-AddLog "Selected distributions: $((@($jobs | ForEach-Object { $_.IsoName }) -join ', '))" "INFO"
            ISO-AddLog "Destination: $dest" "INFO"
            ISO-AddLog "Detailed error log: $errorLogPath" "INFO"

            $Global:ISO_cancelFlag = [System.Threading.CancellationTokenSource]::new()
            $token = $Global:ISO_cancelFlag.Token

            # clear stale queue messages from previous run
            $item = $null
            while ($Global:ISO_msgQueue.TryDequeue([ref]$item)) {}

            $Global:ISO_progress.Value         = 0
            $Global:ISO_pctLabel.Text          = ""
            $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["TextMuted"]
            $Global:ISO_statusLabel.Text       = "Starting..."
            ISO-SetUI-Busy $true
            ISO-StartTimer

            $maxPar = 3
            if ($Global:ISO_parallel.SelectedItem -and $Global:ISO_parallel.SelectedItem.Content) {
                [void][int]::TryParse("$($Global:ISO_parallel.SelectedItem.Content)", [ref]$maxPar)
            }
            if ($maxPar -lt 1) { $maxPar = 1 }

            $capturedJobs   = @($jobs)
            $capturedRunner = ${function:Global:ISO-RunDownloads}
            $capturedQueue  = $Global:ISO_msgQueue
            $capturedWorker = $Global:ISO_WorkerScript

            $Global:ISO_bgPS = [System.Management.Automation.PowerShell]::Create()
            $null = $Global:ISO_bgPS.AddScript($capturedRunner).AddArgument($capturedJobs).AddArgument($token).AddArgument($capturedQueue).AddArgument($maxPar).AddArgument($capturedWorker)
            $Global:ISO_bgHandle = $Global:ISO_bgPS.BeginInvoke()
            ISO-AddLog "Download coordinator started (parallel max: $maxPar)." "INFO"
        } catch {
            ISO-AddLog "Failed to start download operation: $($_.ToString())" "FAIL"
            $Global:ISO_statusLabel.Text       = "Error during startup."
            $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
            ISO-SetUI-Busy $false
            ISO-CleanupBackground
        }
    })

    $Global:ISO_clearLog.Add_Click({
        $Global:ISO_logBox.Text = $Global:ISO_initText
    })

    return $view
}
