# Module: Linux ISO Downloader
# Downloads latest Linux distribution ISOs from official sources in parallel.

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
            <CheckBox x:Name="CbUbuntu"  Content="Ubuntu"  IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbDebian"  Content="Debian"  IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbFedora"  Content="Fedora"  IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbArch"    Content="Arch"    IsChecked="True"  Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbCachyOS" Content="CachyOS" IsChecked="False" Margin="0,0,18,6" FontSize="13"/>
            <CheckBox x:Name="CbPopOS"   Content="Pop!_OS" IsChecked="False" Margin="0,0,18,6" FontSize="13"/>
        </WrapPanel>
    </StackPanel>

    <Grid Grid.Row="2" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="140"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Margin="0,0,12,0">
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
        <Button Grid.Column="1" x:Name="StartBtn" Content="Start Download"
                Style="{DynamicResource PrimaryButton}" Height="40" VerticalAlignment="Bottom"/>
    </Grid>

    <ProgressBar Grid.Row="3" x:Name="ProgressBar" Height="8" Minimum="0" Maximum="100"
                 Margin="0,0,0,12" Value="0"/>

    <Grid Grid.Row="4" Margin="0,0,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" VerticalAlignment="Center"/>
        <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="5" Background="#FAFBFF" BorderBrush="#D8DEFA"
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

    $script:ISO_destBox     = $view.FindName("DestBox")
    $script:ISO_browseBtn   = $view.FindName("BrowseBtn")
    $script:ISO_cbUbuntu    = $view.FindName("CbUbuntu")
    $script:ISO_cbDebian    = $view.FindName("CbDebian")
    $script:ISO_cbFedora    = $view.FindName("CbFedora")
    $script:ISO_cbArch      = $view.FindName("CbArch")
    $script:ISO_cbCachyOS   = $view.FindName("CbCachyOS")
    $script:ISO_cbPopOS     = $view.FindName("CbPopOS")
    $script:ISO_parallel    = $view.FindName("ParallelCombo")
    $script:ISO_startBtn    = $view.FindName("StartBtn")
    $script:ISO_progress    = $view.FindName("ProgressBar")
    $script:ISO_clearLog    = $view.FindName("ClearLogBtn")
    $script:ISO_logBox      = $view.FindName("LogBox")
    $script:ISO_logScroller = $view.FindName("LogScroller")
    $script:ISO_initText    = "Ready."

    function Global:ISO-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:ISO_logBox.Text -eq $script:ISO_initText) { $script:ISO_logBox.Text = $entry }
        else { $script:ISO_logBox.Text += $entry }
        $script:ISO_logScroller.Dispatcher.Invoke([action]{ $script:ISO_logScroller.ScrollToEnd() })
    }

    function Global:ISO-GetWeb {
        param([string]$Url)
        $wc = New-Object System.Net.WebClient
        $wc.Encoding = [System.Text.Encoding]::UTF8
        $wc.Headers.Add("User-Agent","PowerTools-Suite-ISO")
        return $wc.DownloadString($Url)
    }

    function Global:ISO-TestUrl {
        param([string]$Url)
        try {
            $req = [System.Net.HttpWebRequest]::Create($Url)
            $req.Method="HEAD"; $req.Timeout=5000; $req.AllowAutoRedirect=$true
            $r=$req.GetResponse(); $r.Close(); return $true
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
        ISO-AddLog "Resolving Ubuntu..." "INFO"
        $page = ISO-GetWeb "https://releases.ubuntu.com/"
        $cands = [regex]::Matches($page,'href="(\d{2}\.04)\/"') | ForEach-Object {$_.Groups[1].Value} | Sort-Object -Descending
        $ver=$null; $hc=$null
        foreach ($c in $cands) {
            try { $t=ISO-GetWeb "https://releases.ubuntu.com/$c/SHA256SUMS"
                  if (($t -split "`n") | Where-Object {$_ -match "amd64.*\.iso$" -and $_ -notmatch "beta"}) { $ver=$c; $hc=$t; break }
            } catch {}
        }
        if (-not $ver) { ISO-AddLog "Ubuntu: no stable LTS found" "WARN"; return $jobs }
        ISO-AddLog "Ubuntu $ver (stable)" "INFO"
        $mirrors = @(
            "https://mirror.hs-esslingen.de/pub/Mirrors/releases.ubuntu.com/$ver",
            "https://ubuntu.mirror.lrz.de/releases/$ver",
            "https://releases.ubuntu.com/$ver"
        )
        foreach ($ed in @("desktop","live-server")) {
            $line = ($hc -split "`n") | Where-Object {$_ -match "amd64" -and $_ -match $ed -and $_ -match "\.iso$" -and $_ -notmatch "beta"} | Select-Object -First 1
            if (-not $line) { continue }
            $parts = $line.Trim() -split "\s+"; $hash=$parts[0]; $iso=$parts[1] -replace "^\*",""
            $out = Join-Path $Dest $iso
            if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; continue }
            $urls = $mirrors | ForEach-Object {"$_/$iso"}
            $jobs += @{IsoName=$iso; Url=(ISO-SelectMirror $urls); UrlList=$urls; Hash=$hash; OutFile=$out}
        }
        return $jobs
    }

    function Global:ISO-ResolveDebian {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving Debian..." "INFO"
        try {
            $base = "https://cdimage.debian.org/debian-cd/current/amd64"
            $hc = ISO-GetWeb "$base/iso-cd/SHA256SUMS"
            $m = [regex]::Match($hc,'debian-(\d+\.\d+\.\d+)-amd64-netinst\.iso')
            if (-not $m.Success) { ISO-AddLog "Debian: version not found" "WARN"; return $jobs }
            $ver=$m.Groups[1].Value; ISO-AddLog "Debian $ver" "INFO"
            $netM = @("https://ftp.de.debian.org/debian-cd/$ver/amd64/iso-cd","$base/iso-cd")
            $iso = "debian-$ver-amd64-netinst.iso"; $out = Join-Path $Dest $iso
            if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK" }
            else {
                $line = ($hc -split "`n") | Where-Object {$_ -match [regex]::Escape($iso)} | Select-Object -First 1
                $hash = ($line -split "\s+")[0]
                $urls = $netM | ForEach-Object {"$_/$iso"}
                $jobs += @{IsoName=$iso; Url=(ISO-SelectMirror $urls); UrlList=$urls; Hash=$hash; OutFile=$out}
            }
        } catch { ISO-AddLog "Debian resolve error: $_" "FAIL" }
        return $jobs
    }

    function Global:ISO-ResolveFedora {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving Fedora..." "INFO"
        try {
            $idx = ISO-GetWeb "https://dl.fedoraproject.org/pub/fedora/linux/releases/"
            $ver = [regex]::Matches($idx,'<a href="(\d+)/"') | ForEach-Object {[int]$_.Groups[1].Value} | Sort-Object -Descending | Select-Object -First 1
            if (-not $ver) { ISO-AddLog "Fedora: version not found" "WARN"; return $jobs }
            $wsIdx = ISO-GetWeb "https://dl.fedoraproject.org/pub/fedora/linux/releases/$ver/Workstation/x86_64/iso/"
            $build = [regex]::Matches($wsIdx,"Fedora-Workstation-Live-x86_64-$ver-(\d+\.\d+)\.iso") | ForEach-Object {$_.Groups[1].Value} | Sort-Object -Descending | Select-Object -First 1
            if (-not $build) { ISO-AddLog "Fedora: build tag not found" "WARN"; return $jobs }
            ISO-AddLog "Fedora $ver (build $build)" "INFO"
            $iso = "Fedora-Workstation-Live-x86_64-$ver-$build.iso"
            $out = Join-Path $Dest $iso
            if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; return $jobs }
            $url = "https://dl.fedoraproject.org/pub/fedora/linux/releases/$ver/Workstation/x86_64/iso/$iso"
            $jobs += @{IsoName=$iso; Url=$url; UrlList=@($url); Hash=$null; OutFile=$out}
        } catch { ISO-AddLog "Fedora resolve error: $_" "FAIL" }
        return $jobs
    }

    function Global:ISO-ResolveArch {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving Arch..." "INFO"
        try {
            $base = "https://mirror.rackspace.com/archlinux/iso/latest"
            $page = ISO-GetWeb $base
            $iso = [regex]::Matches($page,'archlinux-\d{4}\.\d{2}\.\d{2}-x86_64\.iso') | ForEach-Object {$_.Value} | Select-Object -First 1
            if (-not $iso) { ISO-AddLog "Arch: ISO not found" "WARN"; return $jobs }
            $out = Join-Path $Dest $iso
            if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; return $jobs }
            $jobs += @{IsoName=$iso; Url="$base/$iso"; UrlList=@("$base/$iso"); Hash=$null; OutFile=$out}
        } catch { ISO-AddLog "Arch resolve error: $_" "FAIL" }
        return $jobs
    }

    function Global:ISO-ResolveCachyOS {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving CachyOS..." "INFO"
        try {
            $api = ISO-GetWeb "https://api.github.com/repos/CachyOS/CachyOS-ISO/releases/latest"
            $obj = $api | ConvertFrom-Json
            $asset = $obj.assets | Where-Object {$_.name -match "cachyos-desktop-linux.*\.iso$"} | Select-Object -First 1
            if (-not $asset) { ISO-AddLog "CachyOS: asset not found" "WARN"; return $jobs }
            $out = Join-Path $Dest $asset.name
            if (Test-Path $out) { ISO-AddLog "Already exists: $($asset.name)" "OK"; return $jobs }
            $jobs += @{IsoName=$asset.name; Url=$asset.browser_download_url; UrlList=@($asset.browser_download_url); Hash=$null; OutFile=$out}
        } catch { ISO-AddLog "CachyOS resolve error: $_" "FAIL" }
        return $jobs
    }

    function Global:ISO-ResolvePopOS {
        param([string]$Dest)
        $jobs = @()
        ISO-AddLog "Resolving Pop!_OS..." "INFO"
        $baseVer="24.04"; $isoBase="https://iso.pop-os.org/$baseVer/amd64"; $rev=$null
        for ($i=60; $i -ge 1; $i--) {
            try {
                $wc=New-Object System.Net.WebClient; $wc.Headers.Add("User-Agent","PowerTools-Suite-ISO")
                $c=$wc.DownloadString("$isoBase/intel/$i/SHA256SUMS")
                if ($c -match "pop-os") { $rev=$i; break }
            } catch {}
        }
        if (-not $rev) { ISO-AddLog "Pop!_OS: revision not found" "WARN"; return $jobs }
        ISO-AddLog "Pop!_OS $baseVer rev $rev" "INFO"
        foreach ($v in @("intel","nvidia")) {
            try {
                $iso="pop-os_${baseVer}_amd64_${v}_${rev}.iso"; $url="$isoBase/$v/$rev/$iso"; $out=Join-Path $Dest $iso
                if (Test-Path $out) { ISO-AddLog "Already exists: $iso" "OK"; continue }
                $wc=New-Object System.Net.WebClient; $wc.Headers.Add("User-Agent","PowerTools-Suite-ISO")
                $sums=$wc.DownloadString("$isoBase/$v/$rev/SHA256SUMS")
                $line=($sums -split "`n") | Where-Object {$_ -match [regex]::Escape($iso)} | Select-Object -First 1
                $hash=if($line){($line -split "\s+")[0]}else{$null}
                $jobs += @{IsoName=$iso; Url=$url; UrlList=@($url); Hash=$hash; OutFile=$out}
            } catch { ISO-AddLog "Pop!_OS $v`: $_" "WARN" }
        }
        return $jobs
    }

    $script:ISO_downloadScript = {
        param($Job)
        $out=$Job.OutFile; $tmp="$out.part"
        $result=@{IsoName=$Job.IsoName; Success=$false; Message=""}
        try {
            $done=$false
            foreach ($u in $Job.UrlList) {
                try {
                    $req=[System.Net.HttpWebRequest]::Create($u); $req.AllowAutoRedirect=$true
                    $resp=$req.GetResponse(); $s=$resp.GetResponseStream()
                    $fs=[System.IO.File]::Create($tmp); $buf=New-Object byte[] 65536
                    while($true){$r=$s.Read($buf,0,$buf.Length); if($r -le 0){break}; $fs.Write($buf,0,$r)}
                    $fs.Close(); $s.Close(); $resp.Close(); $done=$true; break
                } catch { if(Test-Path $tmp){Remove-Item $tmp -Force} }
            }
            if (-not $done) { throw "All mirror URLs failed" }
            Move-Item -Path $tmp -Destination $out -Force
            if ($Job.Hash) {
                $h=[System.Security.Cryptography.SHA256]::Create()
                $fs2=[System.IO.File]::OpenRead($out); $b2=New-Object byte[] 1048576
                while($true){$r=$fs2.Read($b2,0,$b2.Length); if($r -le 0){break}; $h.TransformBlock($b2,0,$r,$null,0)|Out-Null}
                $h.TransformFinalBlock(@(),0,0)|Out-Null; $fs2.Close()
                $actual=($h.Hash|ForEach-Object{$_.ToString("x2")})-join ""
                if($actual -ne $Job.Hash.ToLower().Trim()){Remove-Item $out -Force; $result.Message="Hash mismatch"; return $result}
            }
            $result.Success=$true; $result.Message="Done"
        } catch {
            if(Test-Path $tmp){Remove-Item $tmp -Force -EA SilentlyContinue}
            $result.Message="$_"
        }
        return $result
    }

    $script:ISO_browseBtn.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select destination folder for ISOs"
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $script:ISO_destBox.Text = $fbd.SelectedPath
        }
    })

    $script:ISO_startBtn.Add_Click({
        $script:ISO_startBtn.IsEnabled    = $false
        $script:ISO_startBtn.Content      = "Working..."
        $script:ISO_progress.Value        = 0
        try {
            $dest = $script:ISO_destBox.Text.Trim()
            if (-not (Test-Path $dest)) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                ISO-AddLog "Created folder: $dest" "INFO"
            }

            $allJobs = @()
            if ($script:ISO_cbUbuntu.IsChecked)  { $allJobs += ISO-ResolveUbuntu  -Dest $dest }
            if ($script:ISO_cbDebian.IsChecked)  { $allJobs += ISO-ResolveDebian  -Dest $dest }
            if ($script:ISO_cbFedora.IsChecked)  { $allJobs += ISO-ResolveFedora  -Dest $dest }
            if ($script:ISO_cbArch.IsChecked)    { $allJobs += ISO-ResolveArch    -Dest $dest }
            if ($script:ISO_cbCachyOS.IsChecked) { $allJobs += ISO-ResolveCachyOS -Dest $dest }
            if ($script:ISO_cbPopOS.IsChecked)   { $allJobs += ISO-ResolvePopOS   -Dest $dest }

            if ($allJobs.Count -eq 0) { ISO-AddLog "Nothing to download." "OK"; return }

            $max = [int]$script:ISO_parallel.Text
            ISO-AddLog "$($allJobs.Count) ISO(s) queued  |  max $max parallel" "INFO"

            $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $max)
            $pool.Open()
            $running = @()
            foreach ($j in $allJobs) {
                ISO-AddLog "Starting: $($j.IsoName)" "INFO"
                $ps = [System.Management.Automation.PowerShell]::Create()
                $ps.RunspacePool = $pool
                $ps.AddScript($script:ISO_downloadScript).AddArgument($j) | Out-Null
                $running += @{PS=$ps; Handle=$ps.BeginInvoke(); Job=$j; Done=$false}
            }

            $total=$running.Count; $done=0
            while ($done -lt $total) {
                Start-Sleep -Milliseconds 1500
                foreach ($r in $running) {
                    if ($r.Handle.IsCompleted -and -not $r.Done) {
                        $r.Done=$true; $done++
                        try {
                            $res=$r.PS.EndInvoke($r.Handle)
                            if($res.Success){ISO-AddLog "[$done/$total] $($res.IsoName)" "OK"}
                            else            {ISO-AddLog "[$done/$total] $($res.IsoName): $($res.Message)" "FAIL"}
                        } catch {ISO-AddLog "[$done/$total] $($r.Job.IsoName): $_" "FAIL"}
                        $r.PS.Dispose()
                    }
                }
                $script:ISO_progress.Value = [int](($done / $total) * 100)
            }
            $pool.Close()
            ISO-AddLog "All downloads complete. Files in: $dest" "OK"
        }
        catch { ISO-AddLog "Error: $_" "FAIL" }
        finally {
            $script:ISO_startBtn.IsEnabled = $true
            $script:ISO_startBtn.Content   = "Start Download"
        }
    })

    $script:ISO_clearLog.Add_Click({
        $script:ISO_logBox.Text = ""
        ISO-AddLog "Log cleared." "INFO"
    })

    return $view
}
