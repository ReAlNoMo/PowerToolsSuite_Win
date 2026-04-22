# Module: Sandboxie Browser Launcher
# Launches Chrome or Firefox inside a Sandboxie-Plus sandbox.

Register-PowerToolsModule `
    -Id          "sandboxie-launcher" `
    -Name        "Sandboxie Browser Launcher" `
    -Description "Start Chrome or Firefox in Sandboxie-Plus with private/incognito mode." `
    -Category    "Security" `
    -Show        {

    $script:SBX_sandboxieExe = "C:\Program Files\Sandboxie-Plus\Start.exe"
    $script:SBX_chromePath   = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    $script:SBX_firefoxPath  = "C:\Program Files\Mozilla Firefox\firefox.exe"

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

    <Border Grid.Row="0" Background="#FFFFFF" BorderBrush="#D0D6F0"
            BorderThickness="1.5" CornerRadius="10" Padding="18,16" Margin="0,0,0,14">
        <StackPanel>
            <TextBlock Text="PREREQUISITE CHECK" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock x:Name="PrereqText" Foreground="#4A5280" FontSize="13"
                       TextWrapping="Wrap" LineHeight="20"/>
        </StackPanel>
    </Border>

    <StackPanel Grid.Row="1" Margin="0,0,0,14">
        <TextBlock Text="SANDBOX NAME" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,6"/>
        <TextBox x:Name="SandboxBox" Text="DefaultBox" Height="40" FontSize="13"
                 Padding="12,10" Background="#FFFFFF" Foreground="#111827"
                 BorderBrush="#D0D6F0" BorderThickness="1.5"
                 VerticalContentAlignment="Center"/>
    </StackPanel>

    <Grid Grid.Row="2" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ChromeBtn" Content="Launch Chrome (Incognito)"
                Style="{DynamicResource PrimaryButton}" Height="50" FontSize="13"/>
        <Button Grid.Column="2" x:Name="FirefoxBtn" Content="Launch Firefox (Private)"
                Style="{DynamicResource PrimaryButton}" Height="50" FontSize="13"/>
    </Grid>

    <Border Grid.Row="3" Background="#FAFBFF" BorderBrush="#D8DEFA"
            BorderThickness="1.5" CornerRadius="10" Padding="16,12" Margin="0,0,0,14">
        <TextBlock x:Name="StatusText" Foreground="#8890B8" FontSize="12" Text="Ready."/>
    </Border>

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

    $script:SBX_prereqText  = $view.FindName("PrereqText")
    $script:SBX_sandboxBox  = $view.FindName("SandboxBox")
    $script:SBX_chromeBtn   = $view.FindName("ChromeBtn")
    $script:SBX_firefoxBtn  = $view.FindName("FirefoxBtn")
    $script:SBX_statusText  = $view.FindName("StatusText")
    $script:SBX_clearLog    = $view.FindName("ClearLogBtn")
    $script:SBX_logBox      = $view.FindName("LogBox")
    $script:SBX_logScroller = $view.FindName("LogScroller")
    $script:SBX_initText    = "Ready."

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
        param([string]$BrowserPath, [string]$PrivateArg, [string]$BrowserName)
        $sandbox = $script:SBX_sandboxBox.Text.Trim()
        if ([string]::IsNullOrEmpty($sandbox)) {
            [System.Windows.MessageBox]::Show("Please enter a sandbox name.", "Input Required",
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
        if (-not (Test-Path $BrowserPath)) {
            SBX-AddLog "$BrowserName not found: $BrowserPath" "FAIL"; return
        }
        try {
            Start-Process -FilePath $script:SBX_sandboxieExe -ArgumentList "/box:$sandbox", $BrowserPath, $PrivateArg
            $script:SBX_statusText.Text       = "$BrowserName started in [$sandbox]"
            $script:SBX_statusText.Foreground = Get-PowerToolsBrush "Success"
            SBX-AddLog "$BrowserName launched in sandbox [$sandbox]" "OK"
        } catch {
            SBX-AddLog "Launch failed: $_" "FAIL"
        }
    }

    # Prerequisite check
    $hasSandboxie = Test-Path $script:SBX_sandboxieExe
    $hasChrome    = Test-Path $script:SBX_chromePath
    $hasFirefox   = Test-Path $script:SBX_firefoxPath

    $lines = @()
    $lines += if ($hasSandboxie) {"[OK]  Sandboxie-Plus detected"} else {"[--]  Sandboxie-Plus NOT found: $($script:SBX_sandboxieExe)"}
    $lines += if ($hasChrome)    {"[OK]  Google Chrome detected"}   else {"[--]  Google Chrome not found"}
    $lines += if ($hasFirefox)   {"[OK]  Mozilla Firefox detected"} else {"[--]  Mozilla Firefox not found"}
    $script:SBX_prereqText.Text = $lines -join "`n"

    if (-not $hasSandboxie) {
        $script:SBX_chromeBtn.IsEnabled  = $false
        $script:SBX_firefoxBtn.IsEnabled = $false
        $script:SBX_prereqText.Foreground = Get-PowerToolsBrush "Danger"
    } else {
        if (-not $hasChrome)  { $script:SBX_chromeBtn.IsEnabled  = $false }
        if (-not $hasFirefox) { $script:SBX_firefoxBtn.IsEnabled = $false }
    }

    $script:SBX_chromeBtn.Add_Click({
        SBX-Launch -BrowserPath $script:SBX_chromePath -PrivateArg "--incognito" -BrowserName "Google Chrome"
    })

    $script:SBX_firefoxBtn.Add_Click({
        SBX-Launch -BrowserPath $script:SBX_firefoxPath -PrivateArg "-private-window" -BrowserName "Mozilla Firefox"
    })

    $script:SBX_clearLog.Add_Click({
        $script:SBX_logBox.Text = ""
        SBX-AddLog "Log cleared." "INFO"
    })

    return $view
}
