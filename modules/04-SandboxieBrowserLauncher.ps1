# Module: Sandboxie Browser Launcher
# Launches browsers inside a Sandboxie-Plus sandbox in private/incognito mode.
# Browser detection via Windows Registry + WHERE command fallback (path-independent).

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
    # REGISTRY-BASED DETECTION — always returns [string] or $null, never [Object[]]
    # Uses labeled break + explicit [string] cast to prevent pipeline array buildup
    # ===========================================================================
    function Global:SBX-FindExe {
        param([string]$ExeName, [string[]]$RegistryNames)
        [string]$found = $null

        # Method 1: App Paths registry (HKLM + HKCU)
        foreach ($hive in @("HKLM","HKCU")) {
            $key = "${hive}:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExeName"
            try {
                $raw = [string](Get-ItemProperty -Path $key -Name "(default)" -EA Stop)."(default)"
                $raw = $raw.Trim().Trim('"')
                if ($raw -and (Test-Path $raw)) { $found = $raw; break }
            } catch {}
        }
        if ($found) { return $found }

        # Method 2: Uninstall registry (HKLM 64/32 + HKCU 64/32)
        $roots = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
            "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        :outer foreach ($root in $roots) {
            if (-not (Test-Path $root)) { continue }
            foreach ($subkey in (Get-ChildItem -Path $root -EA SilentlyContinue)) {
                try {
                    $props = Get-ItemProperty -Path $subkey.PSPath -EA Stop
                    $nameMatch = $false
                    foreach ($n in $RegistryNames) {
                        if ([string]$props.DisplayName -like "*$n*") { $nameMatch = $true; break }
                    }
                    if (-not $nameMatch) { continue }

                    # Try InstallLocation + exe
                    if ($props.InstallLocation) {
                        $c = [string](Join-Path ([string]$props.InstallLocation).Trim() $ExeName)
                        if (Test-Path $c) { $found = $c; break outer }
                    }
                    # Try DisplayIcon (usually full exe path)
                    if ($props.DisplayIcon) {
                        $icon = [string]([string]$props.DisplayIcon -split "," | Select-Object -First 1)
                        $icon = $icon.Trim().Trim('"')
                        if ($icon -like "*$ExeName*" -and (Test-Path $icon)) { $found = $icon; break outer }
                    }
                } catch {}
            }
        }
        if ($found) { return $found }

        # Method 3: Get-Command (searches $env:PATH)
        try {
            $cmd = Get-Command $ExeName -EA Stop
            $p   = [string]$cmd.Source
            if ($p -and (Test-Path $p)) { return $p }
        } catch {}

        return $null
    }

    function Global:SBX-FindSandboxie {
        [string]$found = $null

        # Method 1: Uninstall registry
        $roots = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        :outer foreach ($root in $roots) {
            if (-not (Test-Path $root)) { continue }
            foreach ($subkey in (Get-ChildItem -Path $root -EA SilentlyContinue)) {
                try {
                    $props = Get-ItemProperty -Path $subkey.PSPath -EA Stop
                    if ([string]$props.DisplayName -notlike "*Sandboxie*") { continue }

                    if ($props.InstallLocation) {
                        $c = [string](Join-Path ([string]$props.InstallLocation).Trim() "Start.exe")
                        if (Test-Path $c) { $found = $c; break outer }
                    }
                    if ($props.DisplayIcon) {
                        $icon = [string]([string]$props.DisplayIcon -split "," | Select-Object -First 1)
                        $icon = $icon.Trim().Trim('"')
                        if ($icon -like "*Start.exe*" -and (Test-Path $icon)) { $found = $icon; break outer }
                    }
                } catch {}
            }
        }
        if ($found) { return $found }

        # Method 2: Well-known install paths
        foreach ($c in @(
            "$env:ProgramFiles\Sandboxie-Plus\Start.exe"
            "$env:ProgramFiles\Sandboxie\Start.exe"
            "${env:ProgramFiles(x86)}\Sandboxie-Plus\Start.exe"
            "${env:ProgramFiles(x86)}\Sandboxie\Start.exe"
        )) {
            if (Test-Path $c) { return [string]$c }
        }

        return $null
    }

    # ===========================================================================
    # RESOLVE PATHS AT LOAD TIME — all values explicitly cast to [string]
    # ===========================================================================
    $script:SBX_sandboxieExe = [string](SBX-FindSandboxie)

    $script:SBX_browsers = @(
        @{ Id="chrome";    Name="Google Chrome";   Arg="--incognito";    Path=[string](SBX-FindExe "chrome.exe"     @("Google Chrome"))             }
        @{ Id="firefox";   Name="Mozilla Firefox"; Arg="-private-window"; Path=[string](SBX-FindExe "firefox.exe"   @("Firefox","Mozilla Firefox")) }
        @{ Id="brave";     Name="Brave";           Arg="--incognito";    Path=[string](SBX-FindExe "brave.exe"      @("Brave","Brave Browser"))      }
        @{ Id="chromium";  Name="Chromium";        Arg="--incognito";    Path=[string](SBX-FindExe "chromium.exe"   @("Chromium"))                   }
        @{ Id="vivaldi";   Name="Vivaldi";         Arg="--private";      Path=[string](SBX-FindExe "vivaldi.exe"    @("Vivaldi"))                    }
        @{ Id="librewolf"; Name="LibreWolf";       Arg="-private-window"; Path=[string](SBX-FindExe "librewolf.exe" @("LibreWolf"))                  }
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
        $browser  = $script:SBX_browsers | Where-Object { $_.Id -eq $BrowserId } | Select-Object -First 1
        $sandbox  = [string]$script:SBX_sandboxBox.Text.Trim()
        $exePath  = [string]$browser.Path
        $sbxExe   = [string]$script:SBX_sandboxieExe
        $arg      = [string]$browser.Arg

        if ([string]::IsNullOrEmpty($sandbox)) {
            [System.Windows.MessageBox]::Show("Please enter a sandbox name.", "Input Required",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
        if ([string]::IsNullOrEmpty($exePath) -or -not (Test-Path $exePath)) {
            SBX-AddLog "$($browser.Name) not found on this system." "FAIL"; return
        }
        if ([string]::IsNullOrEmpty($sbxExe) -or -not (Test-Path $sbxExe)) {
            SBX-AddLog "Sandboxie-Plus not found." "FAIL"; return
        }
        try {
            Start-Process -FilePath $sbxExe -ArgumentList "/box:$sandbox", $exePath, $arg
            $script:SBX_statusText.Text       = "$($browser.Name) started in [$sandbox]"
            $script:SBX_statusText.Foreground = $Global:PTS_Brush["Success"]
            SBX-AddLog "$($browser.Name) launched in sandbox [$sandbox]" "OK"
            SBX-AddLog "Path: $exePath" "INFO"
        } catch {
            SBX-AddLog "Launch failed: $_" "FAIL"
        }
    }

    # ===========================================================================
    # PREREQUISITE CHECK
    # ===========================================================================
    $lines = @()
    if ($script:SBX_sandboxieExe -and (Test-Path $script:SBX_sandboxieExe)) {
        $lines += "[OK]  Sandboxie-Plus: $script:SBX_sandboxieExe"
    } else {
        $lines += "[--]  Sandboxie-Plus: NOT found"
    }
    foreach ($browser in $script:SBX_browsers) {
        if ($browser.Path -and (Test-Path $browser.Path)) {
            $lines += "[OK]  $($browser.Name): $($browser.Path)"
        } else {
            $lines += "[--]  $($browser.Name): not detected"
        }
    }
    $script:SBX_prereqText.Text = $lines -join "`n"

    $hasSandboxie = ($script:SBX_sandboxieExe -and (Test-Path $script:SBX_sandboxieExe))
    if (-not $hasSandboxie) {
        foreach ($btn in $script:SBX_buttonMap.Values) { $btn.IsEnabled = $false }
        $script:SBX_prereqText.Foreground = $Global:PTS_Brush["Danger"]
    } else {
        foreach ($browser in $script:SBX_browsers) {
            if (-not ($browser.Path -and (Test-Path $browser.Path))) {
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