# Module: Windows 11 Gaming Optimizer
# Checkbox-driven list of gaming and performance tweaks with idempotent status checks.

Register-PowerToolsModule `
    -Id            "gaming-optimizer" `
    -Name          "Windows 11 Gaming Optimizer" `
    -Description   "Apply curated gaming and performance tweaks. Already-applied settings are skipped automatically." `
    -Category      "Performance" `
    -RequiresAdmin $true `
    -Show          {

    [xml]$viewXaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="180"/>
    </Grid.RowDefinitions>

    <Grid Grid.Row="0" Margin="0,0,0,12">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="SELECT TWEAKS TO APPLY"
                   Foreground="#8890B8" FontSize="10" FontWeight="Bold" VerticalAlignment="Center"/>
        <Button Grid.Column="1" x:Name="SelectAllBtn" Content="Select All"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11" Margin="0,0,6,0"/>
        <Button Grid.Column="2" x:Name="SelectMissingBtn" Content="Select Missing"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11" Margin="0,0,6,0"/>
        <Button Grid.Column="3" x:Name="SelectNoneBtn" Content="Select None"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="1" Background="#FFFFFF" BorderBrush="#D0D6F0"
            BorderThickness="1.5" CornerRadius="10">
        <ScrollViewer VerticalScrollBarVisibility="Auto">
            <ItemsControl x:Name="TweakList" Margin="4,4,4,4"/>
        </ScrollViewer>
    </Border>

    <Grid Grid.Row="2" Margin="0,14,0,12">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="160"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ApplyBtn" Content="Apply Selected"
                Style="{DynamicResource PrimaryButton}" Height="46" FontSize="14"
                Margin="0,0,8,0" IsEnabled="False"/>
        <Button Grid.Column="1" x:Name="RecheckBtn" Content="Recheck"
                Style="{DynamicResource SecondaryButton}" Height="46" FontSize="13"/>
    </Grid>

    <Grid Grid.Row="3" Margin="0,0,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" VerticalAlignment="Center"/>
        <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="4" Background="#FAFBFF" BorderBrush="#D8DEFA"
            BorderThickness="1.5" CornerRadius="10">
        <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
            <TextBlock x:Name="LogBox" Foreground="#8890B8"
                       FontFamily="Cascadia Code, Consolas, Courier New"
                       FontSize="12" Padding="16,12" TextWrapping="Wrap"
                       LineHeight="20" Text="Ready. Checking current status..."/>
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

    $script:GO_tweakList    = $view.FindName("TweakList")
    $script:GO_applyBtn     = $view.FindName("ApplyBtn")
    $script:GO_recheckBtn   = $view.FindName("RecheckBtn")
    $script:GO_selAll       = $view.FindName("SelectAllBtn")
    $script:GO_selMissing   = $view.FindName("SelectMissingBtn")
    $script:GO_selNone      = $view.FindName("SelectNoneBtn")
    $script:GO_clearLog     = $view.FindName("ClearLogBtn")
    $script:GO_logBox       = $view.FindName("LogBox")
    $script:GO_logScroller  = $view.FindName("LogScroller")
    $script:GO_initText     = "Ready. Checking current status..."
    $script:GO_checkboxes   = @{}

    function Global:GO-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:GO_logBox.Text -eq $script:GO_initText) { $script:GO_logBox.Text = $entry }
        else { $script:GO_logBox.Text += $entry }
        $script:GO_logScroller.Dispatcher.Invoke([action]{ $script:GO_logScroller.ScrollToEnd() })
    }

    function Global:GO-GetReg { param($p,$n) try { (Get-ItemProperty -Path $p -Name $n -EA Stop).$n } catch { $null } }
    function Global:GO-SetDW  { param($p,$n,$v) if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name $n -Value $v -Type DWord -Force }
    function Global:GO-SetStr { param($p,$n,$v) if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name $n -Value $v -Type String -Force }

    $script:GO_tweaks = @(
        @{ Id=1;  Group="Gaming";       NeedsReboot=$false; Label="Windows Game Mode (ON)";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled") -eq 1 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1 } }
        @{ Id=2;  Group="Gaming";       NeedsReboot=$false; Label="Optimizations for Windowed Games (ON)";
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode") -eq 2 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
                   GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1 } }
        @{ Id=3;  Group="Gaming";       NeedsReboot=$true;  Label="Hardware-accelerated GPU Scheduling (ON)";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode") -eq 2 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 } }
        @{ Id=4;  Group="Security";     NeedsReboot=$true;  Label="Core Isolation / Memory Integrity (OFF)";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0 } }
        @{ Id=5;  Group="Lighting";     NeedsReboot=$false; Label="Dynamic Lighting (OFF)";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 0 } }
        @{ Id=6;  Group="Lighting";     NeedsReboot=$false; Label="Apps Control Lighting (OFF)";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 0 } }
        @{ Id=7;  Group="Privacy";      NeedsReboot=$false; Label="Share Across Devices (OFF)";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 0 } }
        @{ Id=8;  Group="Visual";       NeedsReboot=$false; Label="Transparency Effects (OFF)";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 } }
        @{ Id=9;  Group="Visual";       NeedsReboot=$false; Label="Animation Effects (OFF)";
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" } }
        @{ Id=10; Group="Search";       NeedsReboot=$false; Label="Search History (OFF)";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 0 } }
        @{ Id=11; Group="Search";       NeedsReboot=$false; Label="File Search = Enhanced";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows Search" "CrawlingMode") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows Search" "CrawlingMode" 1 } }
        @{ Id=12; Group="Privacy";      NeedsReboot=$false; Label="Language List for Websites (OFF)";
           Check={ (GO-GetReg "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut") -eq 1 };
           Apply={ GO-SetDW "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" 1 } }
        @{ Id=13; Group="Registry";     NeedsReboot=$false; Label="Games Scheduling Category = High";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category") -eq "High" };
           Apply={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" } }
        @{ Id=14; Group="Registry";     NeedsReboot=$false; Label="Win32PrioritySeparation = 0x24";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x24 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x24 } }
        @{ Id=15; Group="Registry";     NeedsReboot=$false; Label="NetworkThrottlingIndex = 0xFFFFFFFF";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex") -eq 0xFFFFFFFF };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF } }
        @{ Id=16; Group="Registry";     NeedsReboot=$false; Label="SystemResponsiveness = 10";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness") -eq 10 };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 10 } }
    )

    function Global:GO-UpdateApplyState {
        $any = $false
        foreach ($id in $script:GO_checkboxes.Keys) {
            if ($script:GO_checkboxes[$id].IsChecked -eq $true) { $any = $true; break }
        }
        $script:GO_applyBtn.IsEnabled = $any
    }

    function Global:GO-RenderList {
        $script:GO_tweakList.Items.Clear()
        $script:GO_checkboxes.Clear()
        $lastGroup = ""

        foreach ($t in $script:GO_tweaks) {
            if ($t.Group -ne $lastGroup) {
                $hdr = New-Object System.Windows.Controls.TextBlock
                $hdr.Text       = $t.Group.ToUpper()
                $hdr.Foreground = Get-PowerToolsBrush "Primary"
                $hdr.FontSize   = 10
                $hdr.FontWeight = "Bold"
                $hdr.Margin     = "12,14,12,6"
                $script:GO_tweakList.Items.Add($hdr) | Out-Null
                $lastGroup = $t.Group
            }

            $isOk = & $t.Check

            $row = New-Object System.Windows.Controls.Grid
            $row.Margin = "12,4,12,4"
            $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = "*"
            $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = "Auto"
            $row.ColumnDefinitions.Add($c1); $row.ColumnDefinitions.Add($c2)

            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content     = $t.Label
            $cb.FontSize    = 13
            $cb.VerticalContentAlignment = "Center"
            $cb.Foreground  = if ($isOk) { Get-PowerToolsBrush "TextMuted" } else { Get-PowerToolsBrush "TextDark" }
            $cb.IsEnabled   = -not $isOk
            $cb.Tag         = $t.Id
            $cb.Add_Checked(   { GO-UpdateApplyState })
            $cb.Add_Unchecked( { GO-UpdateApplyState })
            [System.Windows.Controls.Grid]::SetColumn($cb, 0)
            $row.Children.Add($cb) | Out-Null

            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text       = if ($isOk) { "APPLIED" } else { "MISSING" }
            $lbl.Foreground = if ($isOk) { Get-PowerToolsBrush "Success" } else { Get-PowerToolsBrush "Warning" }
            $lbl.FontSize   = 10
            $lbl.FontWeight = "Bold"
            $lbl.VerticalAlignment = "Center"
            $lbl.Margin = "12,0,6,0"
            [System.Windows.Controls.Grid]::SetColumn($lbl, 1)
            $row.Children.Add($lbl) | Out-Null

            $script:GO_tweakList.Items.Add($row) | Out-Null
            $script:GO_checkboxes[$t.Id] = $cb
        }
        GO-UpdateApplyState
    }

    GO-RenderList
    GO-AddLog "Status check complete." "INFO"

    $script:GO_selAll.Add_Click({
        foreach ($id in $script:GO_checkboxes.Keys) {
            if ($script:GO_checkboxes[$id].IsEnabled) { $script:GO_checkboxes[$id].IsChecked = $true }
        }
        GO-UpdateApplyState
    })

    $script:GO_selMissing.Add_Click({
        foreach ($id in $script:GO_checkboxes.Keys) {
            if ($script:GO_checkboxes[$id].IsEnabled) { $script:GO_checkboxes[$id].IsChecked = $true }
        }
        GO-UpdateApplyState
    })

    $script:GO_selNone.Add_Click({
        foreach ($id in $script:GO_checkboxes.Keys) { $script:GO_checkboxes[$id].IsChecked = $false }
        GO-UpdateApplyState
    })

    $script:GO_recheckBtn.Add_Click({
        GO-RenderList
        GO-AddLog "Rechecked all tweaks." "INFO"
    })

    $script:GO_applyBtn.Add_Click({
        $selected = $script:GO_tweaks | Where-Object {
            $cb = $script:GO_checkboxes[$_.Id]
            $cb -and $cb.IsChecked -eq $true -and $cb.IsEnabled
        }
        if (-not $selected) { GO-AddLog "Nothing selected." "WARN"; return }

        GO-AddLog "Applying $($selected.Count) tweak(s)..." "INFO"
        $ok = 0; $fail = 0; $needsReboot = $false

        foreach ($t in $selected) {
            try {
                & $t.Apply
                GO-AddLog "[$($t.Id.ToString().PadLeft(2))] $($t.Label)" "OK"
                $ok++
                if ($t.NeedsReboot) { $needsReboot = $true }
            } catch {
                GO-AddLog "[$($t.Id.ToString().PadLeft(2))] $($t.Label) - $_" "FAIL"
                $fail++
            }
        }
        GO-AddLog "Applied: $ok  Failed: $fail" "INFO"

        if ($needsReboot) {
            GO-AddLog "Reboot required for HAGS / Core Isolation." "WARN"
            $res = [System.Windows.MessageBox]::Show(
                "Some settings require a reboot.`n`nRestart now?",
                "Reboot Required",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )
            if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
                GO-AddLog "Restarting in 5 seconds..." "WARN"
                Start-Sleep -Seconds 5
                Restart-Computer -Force
            }
        }
        GO-RenderList
    })

    $script:GO_clearLog.Add_Click({
        $script:GO_logBox.Text = ""
        GO-AddLog "Log cleared." "INFO"
    })

    return $view
}
