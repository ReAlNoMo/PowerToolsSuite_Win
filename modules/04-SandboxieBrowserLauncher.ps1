# Module: Sandboxie Browser Launcher
# Launches browsers inside a Sandboxie-Plus sandbox in private/incognito mode.
# Browser detection via Windows Registry + Where-Object fallback (path-independent).

Register-PowerToolsModule `
    -Id          "sandboxie-browser-launcher" `
    -Name        "Sandboxie Browser Launcher" `
    -Description "Launch Chrome, Firefox, Brave, Chromium, Vivaldi, or LibreWolf inside a Sandboxie-Plus sandbox." `
    -Category    "Security" `
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

    <Border Grid.Row="0" x:Name="PrereqBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="18,16" Margin="0,0,0,14">
        <StackPanel>
            <TextBlock Text="PREREQUISITE CHECK" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock x:Name="PrereqText" FontSize="13"
                       TextWrapping="Wrap" LineHeight="20"/>
        </StackPanel>
    </Border>

    <StackPanel Grid.Row="1" Margin="0,0,0,14">
        <TextBlock Text="SANDBOX NAME" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,6"/>
        <TextBox x:Name="SandboxBox" Text="DefaultBox" Height="40" FontSize="13"
                 Padding="12,10" BorderThickness="1.5"
                 VerticalContentAlignment="Center"/>
    </StackPanel>

    <Grid Grid.Row="2" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ChromeBtn"   Content="Chrome (Incognito)"
                Style="{DynamicResource PrimaryButton}" Height="50" FontSize="13"/>
        <Button Grid.Column="2" x:Name="FirefoxBtn"  Content="Firefox (Private)"
                Style="{DynamicResource PrimaryButton}" Height="50" FontSize="13"/>
        <Button Grid.Column="4" x:Name="BraveBtn"    Content="Brave (Incognito)"
                Style="{DynamicResource PrimaryButton}" Height="50" FontSize="13"/>
    </Grid>

    <Grid Grid.Row="3" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ChromiumBtn"  Content="Chromium (Incognito)"
                Style="{DynamicResource PrimaryButton}" Height="50" FontSize="13"/>
        <Button Grid.Column="2" x:Name="VivaldiBtn"   Content="Vivaldi (Private)"
                Style="{DynamicResource PrimaryButton}" Height="50" FontSize="13"/>
        <Button Grid.Column="4" x:Name="LibreWolfBtn" Content="LibreWolf (Private)"
                Style="{DynamicResource PrimaryButton}" Height="50" FontSize="13"/>
    </Grid>

    <Border Grid.Row="4" x:Name="StatusBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="16,12" Margin="0,0,0,14">
        <TextBlock x:Name="StatusText" FontSize="12" Text="Ready."/>
    </Border>

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
                       FontSize="12" Padding="16,14" TextWrapping="Wrap"
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

    $script:SBX_prereqBorder = $view.FindName("PrereqBorder")
    $script:SBX_prereqText   = $view.FindName("PrereqText")
    $script:SBX_sandboxBox   = $view.FindName("SandboxBox")
    $script:SBX_chromeBtn    = $view.FindName("ChromeBtn")
    $script:SBX_firefoxBtn   = $view.FindName("FirefoxBtn")
    $script:SBX_braveBtn     = $view.FindName("BraveBtn")
    $script:SBX_chromiumBtn  = $view.FindName("ChromiumBtn")
    $script:SBX_vivaldiBtn   = $view.FindName("VivaldiBtn")
    $script:SBX_librewolfBtn = $view.FindName("LibreWolfBtn")
    $script:SBX_statusBorder = $view.FindName("StatusBorder")
    $script:SBX_statusText   = $view.FindName("StatusText")
    $script:SBX_clearLog     = $view.FindName("ClearLogBtn")
    $script:SBX_logBox       = $view.FindName("LogBox")
    $script:SBX_logBorder    = $view.FindName("LogBorder")
    $script:SBX_logScroller  = $view.FindName("LogScroller")
    $script:SBX_initText     = "Ready."

    # Apply theme-aware colors
    $script:SBX_prereqBorder.Background  = $Global:PTS_Brush["Surface"]
    $script:SBX_prereqBorder.BorderBrush = $Global:PTS_Brush["Border"]
    $script:SBX_prereqText.Foreground    = $Global:PTS_Brush["TextMid"]
    $script:SBX_sandboxBox.Background    = $Global:PTS_Brush["InputBg"]
    $script:SBX_sandboxBox.Foreground    = $Global:PTS_Brush["InputFg"]
    $script:SBX_sandboxBox.BorderBrush   = $Global:PTS_Brush["Border"]
    $script:SBX_statusBorder.Background  = $Global:PTS_Brush["LogBg"]
    $script:SBX_statusBorder.BorderBrush = $Global:PTS_Brush["LogBorder"]
    $script:SBX_statusText.Foreground    = $Global:PTS_Brush["TextMuted"]
    $script:SBX_logBox.Foreground        = $Global:PTS_Brush["TextMuted"]
    $script:SBX_logBorder.Background     = $Global:PTS_Brush["LogBg"]
    $script:SBX_logBorder.BorderBrush    = $Global:PTS_Brush["LogBorder"]

    # ===========================================================================
    # REGISTRY-BASED BROWSER DETECTION (path-independent)
    # Checks: Registry App Paths, HKLM/HKCU Uninstall, WHERE command fallback
    # ===========================================================================
    function Global:SBX-FindBrowser {
        param([string]$ExeName, [string[]]$RegistryNames)

        # Method 1: App Paths registry (most reliable)
        $appPathKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExeName",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExeName"
        )
        foreach ($key in $appPathKeys) {
            try {
                $val = (Get-ItemProperty -Path $key -Name "(default)" -EA Stop)."(default)"
                if ($val -and (Test-Path $val)) { return $val }
            } catch {}
        }

        # Method 2: Uninstall registry (HKLM + HKCU, 32 + 64 bit)
        $uninstallRoots = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        foreach ($root in $uninstallRoots) {
            if (-not (Test-Path $root)) { continue }
            $keys = Get-ChildItem -Path $root -EA SilentlyContinue
            foreach ($key in $keys) {
                try {
                    $props = Get-ItemProperty -Path $key.PSPath -EA Stop
                    $match = $false
                    foreach ($name in $RegistryNames) {
                        if ($props.DisplayName -like "*$name*") { $match = $true; break }
                    }
                    if (-not $match) { continue }

                    # Try InstallLocation first
                    if ($props.InstallLocation) {
                        $candidate = Join-Path $props.InstallLocation $ExeName
                        if (Test-Path $candidate) { return $candidate }
                    }
                    # Try DisplayIcon (often full path to exe)
                    if ($props.DisplayIcon) {
                        $iconPath = $props.DisplayIcon -split "," | Select-Object -First 1
                        $iconPath = $iconPath.Trim('"')
                        if ($iconPath -like "*$ExeName*" -and (Test-Path $iconPath)) { return $iconPath }
                    }
                } catch {}
            }
        }

        # Method 3: WHERE command (searches PATH + common locations)
        try {
            $found = (Get-Command $ExeName -EA Stop).Source
            if ($found -and (Test-Path $found)) { return $found }
        } catch {}

        return $null
    }

    function Global:SBX-FindSandboxie {
        # Check registry App Paths
        $appPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Start.exe"
        try {
            $val = (Get-ItemProperty -Path $appPath -Name "(default)" -EA Stop)."(default)"
            if ($val -and (Test-Path $val) -and $val -like "*Sandboxie*") { return $val }
        } catch {}

        # Check Uninstall registry
        $uninstallRoots = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        foreach ($root in $uninstallRoots) {
            if (-not (Test-Path $root)) { continue }
            Get-ChildItem -Path $root -EA SilentlyContinue | ForEach-Object {
                try {
                    $props = Get-ItemProperty -Path $_.PSPath -EA Stop
                    if ($props.DisplayName -like "*Sandboxie*") {
                        if ($props.InstallLocation) {
                            $candidate = Join-Path $props.InstallLocation "Start.exe"
                            if (Test-Path $candidate) { return $candidate }
                        }
                    }
                } catch {}
            }
        }

        # Fallback: well-known paths (both Program Files variants)
        @(
            "$env:ProgramFiles\Sandboxie-Plus\Start.exe"
            "$env:ProgramFiles\Sandboxie\Start.exe"
            "${env:ProgramFiles(x86)}\Sandboxie-Plus\Start.exe"
            "${env:ProgramFiles(x86)}\Sandboxie\Start.exe"
        ) | ForEach-Object { if (Test-Path $_) { return $_ } }

        return $null
    }

    # ===========================================================================
    # RESOLVE PATHS AT LOAD TIME
    # ===========================================================================
    $script:SBX_sandboxieExe = SBX-FindSandboxie

    $script:SBX_browsers = @(
        @{
            Id     = "chrome"
            Name   = "Google Chrome"
            Exe    = "chrome.exe"
            Reg    = @("Google Chrome")
            Arg    = "--incognito"
            Path   = SBX-FindBrowser -ExeName "chrome.exe" -RegistryNames @("Google Chrome")
        }
        @{
            Id     = "firefox"
            Name   = "Mozilla Firefox"
            Exe    = "firefox.exe"
            Reg    = @("Firefox", "Mozilla Firefox")
            Arg    = "-private-window"
            Path   = SBX-FindBrowser -ExeName "firefox.exe" -RegistryNames @("Firefox", "Mozilla Firefox")
        }
        @{
            Id     = "brave"
            Name   = "Brave"
            Exe    = "brave.exe"
            Reg    = @("Brave", "Brave Browser")
            Arg    = "--incognito"
            Path   = SBX-FindBrowser -ExeName "brave.exe" -RegistryNames @("Brave", "Brave Browser")
        }
        @{
            Id     = "chromium"
            Name   = "Chromium"
            Exe    = "chromium.exe"
            Reg    = @("Chromium")
            Arg    = "--incognito"
            Path   = SBX-FindBrowser -ExeName "chromium.exe" -RegistryNames @("Chromium")
        }
        @{
            Id     = "vivaldi"
            Name   = "Vivaldi"
            Exe    = "vivaldi.exe"
            Reg    = @("Vivaldi")
            Arg    = "--private"
            Path   = SBX-FindBrowser -ExeName "vivaldi.exe" -RegistryNames @("Vivaldi")
        }
        @{
            Id     = "librewolf"
            Name   = "LibreWolf"
            Exe    = "librewolf.exe"
            Reg    = @("LibreWolf")
            Arg    = "-private-window"
            Path   = SBX-FindBrowser -ExeName "librewolf.exe" -RegistryNames @("LibreWolf")
        }
    )

    $script:SBX_buttonMap = @{
        "chrome"    = $script:SBX_chromeBtn
        "firefox"   = $script:SBX_firefoxBtn
        "brave"     = $script:SBX_braveBtn
        "chromium"  = $script:SBX_chromiumBtn
        "vivaldi"   = $script:SBX_vivaldiBtn
        "librewolf" = $script:SBX_librewolfBtn
    }

    # ===========================================================================
    # HELPERS
    # ===========================================================================
    function Global:SBX-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:SBX_logBox.Text -eq $script:SBX_initText) { $script:SBX_logBox.Text = $entry }
        else { $script:SBX_logBox.Text += $entry }
        $script:SBX_logScroller.Dispatcher.Invoke([action]{ $script:SBX_logScroller.ScrollToEnd() })
    }

    function Global:SBX-Launch {
        param([string]$BrowserId)
        $browser = $script:SBX_browsers | Where-Object { $_.Id -eq $BrowserId } | Select-Object -First 1
        $sandbox = $script:SBX_sandboxBox.Text.Trim()

        if ([string]::IsNullOrEmpty($sandbox)) {
            [System.Windows.MessageBox]::Show("Please enter a sandbox name.", "Input Required",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
        if (-not $browser.Path -or -not (Test-Path $browser.Path)) {
            SBX-AddLog "$($browser.Name) not found on this system." "FAIL"
            return
        }
        if (-not $script:SBX_sandboxieExe -or -not (Test-Path $script:SBX_sandboxieExe)) {
            SBX-AddLog "Sandboxie-Plus not found." "FAIL"
            return
        }
        try {
            Start-Process -FilePath $script:SBX_sandboxieExe -ArgumentList "/box:$sandbox", $browser.Path, $browser.Arg
            $script:SBX_statusText.Text       = "$($browser.Name) started in [$sandbox]"
            $script:SBX_statusText.Foreground = $Global:PTS_Brush["Success"]
            SBX-AddLog "$($browser.Name) launched in sandbox [$sandbox]" "OK"
            SBX-AddLog "Path: $($browser.Path)" "INFO"
        } catch {
            SBX-AddLog "Launch failed: $_" "FAIL"
        }
    }

    # ===========================================================================
    # PREREQUISITE CHECK
    # ===========================================================================
    $lines = @()
    if ($script:SBX_sandboxieExe) {
        $lines += "[OK]  Sandboxie-Plus detected: $script:SBX_sandboxieExe"
    } else {
        $lines += "[--]  Sandboxie-Plus NOT found"
    }

    foreach ($browser in $script:SBX_browsers) {
        if ($browser.Path) {
            $lines += "[OK]  $($browser.Name): $($browser.Path)"
        } else {
            $lines += "[--]  $($browser.Name): not detected"
        }
    }

    $script:SBX_prereqText.Text = $lines -join "`n"

    if (-not $script:SBX_sandboxieExe) {
        foreach ($btn in $script:SBX_buttonMap.Values) { $btn.IsEnabled = $false }
        $script:SBX_prereqText.Foreground = $Global:PTS_Brush["Danger"]
    } else {
        foreach ($browser in $script:SBX_browsers) {
            if (-not $browser.Path) {
                $script:SBX_buttonMap[$browser.Id].IsEnabled = $false
            }
        }
    }

    # ===========================================================================
    # EVENT HANDLERS
    # ===========================================================================
    $script:SBX_chromeBtn.Add_Click({    SBX-Launch -BrowserId "chrome"    })
    $script:SBX_firefoxBtn.Add_Click({   SBX-Launch -BrowserId "firefox"   })
    $script:SBX_braveBtn.Add_Click({     SBX-Launch -BrowserId "brave"     })
    $script:SBX_chromiumBtn.Add_Click({  SBX-Launch -BrowserId "chromium"  })
    $script:SBX_vivaldiBtn.Add_Click({   SBX-Launch -BrowserId "vivaldi"   })
    $script:SBX_librewolfBtn.Add_Click({ SBX-Launch -BrowserId "librewolf" })

    $script:SBX_clearLog.Add_Click({
        $script:SBX_logBox.Text = ""
        SBX-AddLog "Log cleared." "INFO"
    })

    return $view
}