# Module: Windows 11 Gaming Optimizer v2.0
# Comprehensive gaming tweaks with profile support, backup, and detailed info.

Register-PowerToolsModule `
    -Id            "gaming-optimizer" `
    -Name          "Windows 11 Gaming Optimizer" `
    -Description   "Apply curated gaming and performance tweaks. Profile save/load, backup, and detailed info included." `
    -Category      "Performance" `
    -RequiresAdmin $true `
    -Show          {

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
        <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- ROW 0: Hardware Info -->
    <Border Grid.Row="0" x:Name="HWInfoBorder"
            BorderThickness="1.5" CornerRadius="8" Padding="12,8" Margin="0,0,0,6">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="DETECTED HARDWARE" Foreground="#8890B8" FontSize="9"
                           FontWeight="Bold" Margin="0,0,0,2"/>
                <TextBlock x:Name="HardwareText" FontSize="11" TextWrapping="Wrap" Text="Detecting..."/>
            </StackPanel>
            <Button Grid.Column="1" x:Name="SoftwareInfoBtn" Content="Recommended Tools"
                    Style="{DynamicResource SecondaryButton}" Padding="12,6"
                    FontSize="11" VerticalAlignment="Center" Margin="10,0,0,0"/>
        </Grid>
    </Border>

    <!-- ROW 1: Backup Options (intentional warning colors) -->
    <Border Grid.Row="1" Background="#FFF4E5" BorderBrush="#D9822B"
            BorderThickness="1.5" CornerRadius="8" Padding="12,6" Margin="0,0,0,6">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="BACKUP:" Foreground="#8F4F0A" FontSize="10"
                       FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,12,0"/>
            <CheckBox Grid.Column="1" x:Name="CbRestorePoint"
                      Content="Create Restore Point" IsChecked="True"
                      FontSize="11" Foreground="#1A1F3A" VerticalAlignment="Center"/>
            <CheckBox Grid.Column="2" x:Name="CbRegBackup"
                      Content="Export Registry (.reg)" IsChecked="True"
                      FontSize="11" Foreground="#1A1F3A" VerticalAlignment="Center"/>
            <CheckBox Grid.Column="3" x:Name="CbAutoReboot"
                      Content="Prompt for Reboot" IsChecked="True"
                      FontSize="11" Foreground="#1A1F3A" VerticalAlignment="Center"/>
        </Grid>
    </Border>

    <!-- ROW 2: Selection toolbar -->
    <Grid Grid.Row="2" Margin="0,0,0,6">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="SELECT:" Foreground="#8890B8"
                   FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,8,0"/>
        <Button Grid.Column="1" x:Name="SelectAllBtn" Content="All"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="2" x:Name="SelectMissingBtn" Content="Missing Only"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="3" x:Name="SelectSafeBtn" Content="Safe Only"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="4" x:Name="SelectNoneBtn" Content="None"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11"/>
        <TextBlock Grid.Column="5"/>
        <Button Grid.Column="6" x:Name="LoadProfileBtn" Content="Load Profile"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="7" x:Name="SaveProfileBtn" Content="Save Profile"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11"/>
    </Grid>

    <!-- ROW 3: TWEAK LIST -->
    <Border Grid.Row="3" x:Name="TweakListBorder"
            BorderThickness="1.5" CornerRadius="8" Margin="0,0,0,6">
        <ItemsControl x:Name="TweakList" Margin="6,6,6,6"/>
    </Border>

    <!-- ROW 4: Estimate bar -->
    <Border Grid.Row="4" x:Name="EstimateBar"
            BorderThickness="1" CornerRadius="6" Padding="12,6" Margin="0,6,0,6">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" x:Name="EstimateText" FontSize="11"
                       Text="No tweaks selected. All estimates without warranty."/>
            <TextBlock Grid.Column="1" Text="Hover = short info  |  Click name = full details"
                       Foreground="#8890B8" FontSize="10" FontStyle="Italic" VerticalAlignment="Center"/>
        </Grid>
    </Border>

    <!-- ROW 5: Action buttons -->
    <Grid Grid.Row="5" Margin="0,0,0,6">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="140"/>
            <ColumnDefinition Width="180"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ApplyBtn" Content="Apply Selected"
                Style="{DynamicResource PrimaryButton}" Height="40" FontSize="13"
                Margin="0,0,6,0" IsEnabled="False"/>
        <Button Grid.Column="1" x:Name="RecheckBtn" Content="Recheck All"
                Style="{DynamicResource SecondaryButton}" Height="40" FontSize="11" Margin="0,0,6,0"/>
        <Button Grid.Column="2" x:Name="RevertBtn" Content="Revert to Windows Defaults"
                Style="{DynamicResource SecondaryButton}" Height="40" FontSize="11"/>
    </Grid>

    <!-- ROW 6: Activity Log (fixed height) -->
    <Border Grid.Row="6" x:Name="LogAreaBorder"
            BorderThickness="1.5" CornerRadius="8" Height="140">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0" Margin="12,6,12,2">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="9"
                           FontWeight="Bold" VerticalAlignment="Center"/>
                <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear"
                        Style="{DynamicResource SecondaryButton}" Padding="8,3" FontSize="10"/>
            </Grid>
            <ScrollViewer Grid.Row="1" x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogBox"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="10" Padding="12,2,12,8" TextWrapping="Wrap"
                           LineHeight="16" Text="Ready. Detecting hardware and checking current status..."/>
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

    $script:GO_hwText          = $view.FindName("HardwareText")
    $script:GO_hwInfoBorder    = $view.FindName("HWInfoBorder")
    $script:GO_cbRestore       = $view.FindName("CbRestorePoint")
    $script:GO_cbRegBkp        = $view.FindName("CbRegBackup")
    $script:GO_cbAutoReb       = $view.FindName("CbAutoReboot")
    $script:GO_tweakList       = $view.FindName("TweakList")
    $script:GO_tweakListBorder = $view.FindName("TweakListBorder")
    $script:GO_estimateBar     = $view.FindName("EstimateBar")
    $script:GO_estimate        = $view.FindName("EstimateText")
    $script:GO_logAreaBorder   = $view.FindName("LogAreaBorder")
    $script:GO_applyBtn        = $view.FindName("ApplyBtn")
    $script:GO_recheckBtn      = $view.FindName("RecheckBtn")
    $script:GO_revertBtn       = $view.FindName("RevertBtn")
    $script:GO_selAll          = $view.FindName("SelectAllBtn")
    $script:GO_selMissing      = $view.FindName("SelectMissingBtn")
    $script:GO_selSafe         = $view.FindName("SelectSafeBtn")
    $script:GO_selNone         = $view.FindName("SelectNoneBtn")
    $script:GO_loadProfBtn     = $view.FindName("LoadProfileBtn")
    $script:GO_saveProfBtn     = $view.FindName("SaveProfileBtn")
    $script:GO_softInfoBtn     = $view.FindName("SoftwareInfoBtn")
    $script:GO_clearLog        = $view.FindName("ClearLogBtn")
    $script:GO_logBox          = $view.FindName("LogBox")
    $script:GO_logScroller     = $view.FindName("LogScroller")
    $script:GO_initText        = "Ready. Detecting hardware and checking current status..."
    $script:GO_checkboxes      = @{}
    $script:GO_detailWindows   = @{}
    $script:GO_profilePath     = Join-Path $env:LOCALAPPDATA "PowerToolsSuite\GamingOptimizer"
    if (-not (Test-Path $script:GO_profilePath)) { New-Item -ItemType Directory -Path $script:GO_profilePath -Force | Out-Null }

    # Apply theme-aware colors
    $script:GO_hwInfoBorder.Background     = $Global:PTS_Brush["Surface"]
    $script:GO_hwInfoBorder.BorderBrush    = $Global:PTS_Brush["Border"]
    $script:GO_hwText.Foreground           = $Global:PTS_Brush["TextDark"]
    $script:GO_tweakListBorder.Background  = $Global:PTS_Brush["Surface"]
    $script:GO_tweakListBorder.BorderBrush = $Global:PTS_Brush["Border"]
    $script:GO_estimateBar.Background      = $Global:PTS_Brush["LogBg"]
    $script:GO_estimateBar.BorderBrush     = $Global:PTS_Brush["LogBorder"]
    $script:GO_estimate.Foreground         = $Global:PTS_Brush["TextDark"]
    $script:GO_logAreaBorder.Background    = $Global:PTS_Brush["LogBg"]
    $script:GO_logAreaBorder.BorderBrush   = $Global:PTS_Brush["LogBorder"]
    $script:GO_logBox.Foreground           = $Global:PTS_Brush["TextMuted"]

    function Global:GO-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:GO_logBox.Text -eq $script:GO_initText) { $script:GO_logBox.Text = $entry }
        else { $script:GO_logBox.Text += $entry }
        $script:GO_logScroller.Dispatcher.Invoke([action]{ $script:GO_logScroller.ScrollToEnd() })
    }

    function Global:GO-GetReg  { param($p,$n) try { (Get-ItemProperty -Path $p -Name $n -EA Stop).$n } catch { $null } }
    function Global:GO-SetDW   { param($p,$n,$v) if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name $n -Value $v -Type DWord -Force }
    function Global:GO-SetStr  { param($p,$n,$v) if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name $n -Value $v -Type String -Force }
    function Global:GO-DelReg  { param($p,$n) try { Remove-ItemProperty -Path $p -Name $n -Force -EA Stop } catch {} }

    function Global:GO-DetectHardware {
        $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
        $gpu = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Basic|Virtual" } | Select-Object -First 1).Name
        $ramGB = [math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB), 0)
        $build = [System.Environment]::OSVersion.Version.Build
        $isX3D = $cpu -match "X3D"

        $text = "CPU: $cpu`nGPU: $gpu`nRAM: $ramGB GB | Windows Build: $build"
        if ($isX3D)           { $text += "`n[!] AMD X3D detected - Xbox Game Bar and Game Mode must stay ACTIVE" }
        if ($build -ge 26100) { $text += "`n[i] Windows 11 24H2+ - Native NVMe Stack available" }

        $script:GO_hwText.Text = $text
        return @{
            CPU=$cpu; GPU=$gpu; RAMGB=$ramGB; Build=$build; IsX3D=$isX3D
            IsIntel12Plus=($cpu -match "1[2-9]\d{3}|2\d{4}")
            IsAMDRyzen5000Plus=($cpu -match "Ryzen.*[5-9]\d{3}|Ryzen.*X3D")
        }
    }

    $script:GO_hw = GO-DetectHardware

    function Global:GO-IsRecommended {
        param($TweakId)
        $alwaysRecommended = @(1,2,3,4,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,25,26,27,28)
        if ($alwaysRecommended -contains $TweakId) { return $true }
        if ($script:GO_hw.IsX3D -and $TweakId -eq 5) { return $false }
        if ($TweakId -eq 24 -and $script:GO_hw.Build -lt 26100) { return $false }
        if ($TweakId -eq 24 -and $script:GO_hw.Build -ge 26100) { return $true }
        return $false
    }

    $script:GO_tweaks = @(
        @{ Id=1; Group="Security - High Impact"; Risk=1; NeedsReboot=$true;
           Label="Memory Integrity / HVCI (OFF)";
           ShortDesc="Disables Hypervisor-Protected Code Integrity. Biggest FPS gainer.";
           LongDesc="Hypervisor-Protected Code Integrity (HVCI) validates every kernel driver access via hypervisor. Disabling yields 3-25% FPS gain, more stable 1% lows, significantly less microstutter in CPU-limited games. Risk: Kernel exploits through manipulated drivers become possible. Acceptable for dedicated gaming PC without sensitive data.";
           FPSGain="3-25% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
                   GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 1
                    GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 1 } }
        @{ Id=2; Group="Security - High Impact"; Risk=1; NeedsReboot=$true;
           Label="Disable VBS / Virtual Machine Platform";
           ShortDesc="Disables Virtualization-Based Security. Prerequisite for HVCI disable. Big FPS unlock.";
           LongDesc="Virtualization-Based Security creates an isolated hypervisor environment. Prerequisite for HVCI. Disabling yields additional 2-8% FPS. Risk: Same as HVCI - reduced kernel protection. Acceptable for gaming-only machines.";
           FPSGain="2-8% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 1 } }
        @{ Id=3; Group="Security - High Impact"; Risk=0; NeedsReboot=$true;
           Label="GameDVR / Xbox Recording (OFF)";
           ShortDesc="Disables Xbox Game Bar DVR recording. Frees GPU/CPU resources during gameplay.";
           LongDesc="Xbox Game Bar DVR captures gameplay in background consuming GPU and CPU resources. Disabling yields 2-5% FPS in GPU-limited scenarios. No risk - only removes screen recording. Manual screenshots still work.";
           FPSGain="2-5% FPS";
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_Enabled") -eq 0 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
                   GO-SetDW "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 };
           Revert={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1
                    GO-DelReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" } }
        @{ Id=4; Group="Security - High Impact"; Risk=2; NeedsReboot=$true;
           Label="Spectre/Meltdown Mitigations (OFF) - HIGH RISK";
           ShortDesc="Disables CPU vulnerability mitigations. +5-15% FPS on older CPUs. SECURITY RISK.";
           LongDesc="Spectre and Meltdown mitigations protect against CPU-level attacks. Disabling yields 5-15% FPS on older CPUs (Intel 6-9th gen). HIGH RISK: Only on isolated gaming PCs without browser or sensitive data access. Not recommended.";
           FPSGain="5-15% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride") -eq 3 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride" 3
                   GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" 3 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride"
                    GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" } }
        @{ Id=5; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Ultimate Performance Power Plan";
           ShortDesc="Activates hidden Ultimate Performance plan. Disables core parking. Sets min CPU clock to 100%.";
           LongDesc="Hidden power plan that disables core parking and sets minimum CPU clock to 100%. Eliminates CPU wake latencies, instant response to load spikes. Yields 5-15% FPS. Risk: Higher idle power consumption and heat.";
           FPSGain="5-15% FPS";
           Check={ (powercfg -list | Select-String "Ultimate Performance") -ne $null -and (powercfg -getactivescheme | Select-String "Ultimate") -ne $null };
           Apply={ powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
                   $g = (powercfg -list | Select-String "Ultimate Performance" | ForEach-Object { ($_ -split "\s+")[3] } | Select-Object -First 1)
                   if ($g) { powercfg -setactive $g | Out-Null } };
           Revert={ powercfg -setactive SCHEME_BALANCED | Out-Null } }
        @{ Id=6; Group="Power / CPU"; Risk=1; NeedsReboot=$true;
           Label="Disable Power Throttling";
           ShortDesc="Prevents Windows from throttling CPU for background processes.";
           LongDesc="Windows automatically throttles CPU resources for background processes. Disabling gives all processes full resources - less frame variance. Risk: Background processes can consume more CPU.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" } }
        @{ Id=7; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="System Responsiveness = 10";
           ShortDesc="Controls CPU share for multimedia/foreground apps. More CPU cycles for active applications.";
           LongDesc="Controls CPU share for multimedia and foreground applications. Default is 20. Value 10 is moderate and recommended for stability.";
           FPSGain="1-2% FPS";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness") -eq 10 };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 10 };
           Revert={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 20 } }
        @{ Id=8; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Network Throttling Disabled";
           ShortDesc="Removes network throughput limit. Better network latency and throughput.";
           LongDesc="Windows limits network throughput to save CPU. Disabling improves network latency and throughput.";
           FPSGain="Latency";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex") -eq 0xFFFFFFFF };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF };
           Revert={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10 } }
        @{ Id=9; Group="Power / CPU"; Risk=0; NeedsReboot=$false; Mutex="PrioritySep";
           Label="Win32PrioritySeparation = 36 (Competitive)";
           ShortDesc="Short variable quanta without focus boost. Minimal scheduling latency.";
           LongDesc="Controls CPU time quanta per process before context switch. Value 36 (0x24) uses short variable quanta without focus boost - minimal scheduling latency. Best for competitive shooters.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x24 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x24 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x26 } }
        @{ Id=10; Group="Power / CPU"; Risk=0; NeedsReboot=$false; Mutex="PrioritySep";
           Label="Win32PrioritySeparation = 24 (AAA Games)";
           ShortDesc="Long fixed quanta (server mode). Maximum consistency for games with many background threads.";
           LongDesc="Value 24 (0x18) uses long fixed quanta in server mode - maximum consistency for AAA games with many background threads.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x18 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x18 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x26 } }
        @{ Id=11; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Startup Delay Disabled";
           ShortDesc="Removes artificial startup delay for autostart apps. Faster desktop after login.";
           LongDesc="Windows artificially delays autostart apps after login. Disabling gives a faster desktop after login.";
           FPSGain="Boot speed";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 };
           Revert={ GO-DelReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" } }
        @{ Id=12; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$true;
           Label="Hardware-Accelerated GPU Scheduling (ON)";
           ShortDesc="GPU manages its own memory and tasks instead of CPU. Required for DLSS 3 Frame Generation.";
           LongDesc="GPU takes over own memory and task management instead of CPU. Reduces system latency by ~2ms, more stable frametimes. Mandatory for DLSS 3 Frame Generation.";
           FPSGain="1-5% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode") -eq 2 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1 } }
        @{ Id=13; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Windows Game Mode (ON)";
           ShortDesc="Prioritizes game threads. Pauses Windows updates during gaming. REQUIRED for AMD X3D CPUs.";
           LongDesc="Prioritizes game threads and pauses Windows Update downloads during gaming. CRITICAL: Must stay ON for AMD X3D chips.";
           FPSGain="1-5% FPS";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled") -eq 1 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0 } }
        @{ Id=14; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Windowed Game Optimizations (Flip Model)";
           ShortDesc="Modern flip presentation for DirectX 10/11 windowed games. Fullscreen latency in windowed mode.";
           LongDesc="Modern flip presentation system for all DirectX 10/11 windowed games. Latency at fullscreen level, enables VRR/Auto-HDR in windowed mode.";
           FPSGain="Latency";
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode") -eq 2 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
                   GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1 };
           Revert={ GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode"
                    GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" } }
        @{ Id=15; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Games Task Scheduling = High";
           ShortDesc="Sets Multimedia scheduler priority for games to High.";
           LongDesc="Sets Multimedia scheduler priority for games to High. More CPU cycles for gaming threads.";
           FPSGain="1% FPS";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category") -eq "High" };
           Apply={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" };
           Revert={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "Medium" } }
        @{ Id=16; Group="Network"; Risk=1; NeedsReboot=$false;
           Label="Disable Nagle Algorithm";
           ShortDesc="Bundles small TCP packets - artificially raises ping. Disabling reduces ping 10-30ms.";
           LongDesc="Nagle algorithm bundles small TCP packets, artificially raising ping in real-time games. Disabling yields immediate packet sending - 10-30ms ping reduction.";
           FPSGain="-10-30ms ping";
           Check={
               $nics = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceType -eq 6}
               foreach ($n in $nics) {
                   $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.InterfaceGuid)"
                   if ((GO-GetReg $p "TcpAckFrequency") -ne 1 -or (GO-GetReg $p "TCPNoDelay") -ne 1) { return $false }
               }
               return $true
           };
           Apply={
               $nics = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceType -eq 6}
               foreach ($n in $nics) {
                   $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.InterfaceGuid)"
                   GO-SetDW $p "TcpAckFrequency" 1; GO-SetDW $p "TCPNoDelay" 1; GO-SetDW $p "TcpDelAckTicks" 0
               }
           };
           Revert={
               $nics = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceType -eq 6}
               foreach ($n in $nics) {
                   $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.InterfaceGuid)"
                   GO-DelReg $p "TcpAckFrequency"; GO-DelReg $p "TCPNoDelay"; GO-DelReg $p "TcpDelAckTicks"
               }
           } }
        @{ Id=17; Group="Network"; Risk=0; NeedsReboot=$false;
           Label="Advanced TCP Optimizations";
           ShortDesc="Enables RSS, disables RSC/ECN/timestamps. Better network throughput and latency.";
           LongDesc="Multiple netsh optimizations: autotuning=normal, RSS=enabled, RSC=disabled, ECN=disabled, timestamps=disabled.";
           FPSGain="Latency";
           Check={ (netsh int tcp show global | Select-String "Receive Segment Coalescing.*disabled") -ne $null };
           Apply={ netsh int tcp set global autotuninglevel=normal|Out-Null; netsh int tcp set global rss=enabled|Out-Null
                   netsh int tcp set global rsc=disabled|Out-Null; netsh int tcp set global ecncapability=disabled|Out-Null
                   netsh int tcp set global timestamps=disabled|Out-Null };
           Revert={ netsh int tcp set global autotuninglevel=normal|Out-Null; netsh int tcp set global rss=default|Out-Null
                    netsh int tcp set global rsc=default|Out-Null; netsh int tcp set global ecncapability=default|Out-Null
                    netsh int tcp set global timestamps=default|Out-Null } }
        @{ Id=18; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Transparency Effects (OFF)";
           ShortDesc="Disables Windows transparency effects. Less GPU overhead for UI.";
           LongDesc="Windows transparency effects consume GPU resources. Disabling yields minimal FPS gain but reduces UI overhead.";
           FPSGain="0-1% FPS";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 1 } }
        @{ Id=19; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Window Animations (OFF)";
           ShortDesc="Disables window minimize/maximize animations. Snappier UI response.";
           LongDesc="Disables window animations for minimize/maximize. Snappier UI response.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" };
           Revert={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "1" } }
        @{ Id=20; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Menu Show Delay = 0";
           ShortDesc="Removes menu open delay. Instant menu response.";
           LongDesc="Windows has a default 400ms menu show delay. Setting to 0 gives instant menu response.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop" "MenuShowDelay") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" };
           Revert={ GO-SetStr "HKCU:\Control Panel\Desktop" "MenuShowDelay" "400" } }
        @{ Id=21; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Taskbar Animations (OFF)";
           ShortDesc="Disables taskbar animations. Snappier taskbar response.";
           LongDesc="Disables taskbar animations. Snappier response when hovering or clicking taskbar.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 1 } }
        @{ Id=22; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$false;
           Label="NTFS Disable Last Access Time";
           ShortDesc="Windows writes timestamp on every read. Reduces SSD writes. Extends SSD lifespan.";
           LongDesc="Disabling reduces I/O operations and extends SSD lifespan. No negative side effects.";
           FPSGain="SSD life";
           Check={ (fsutil behavior query disablelastaccess) -match "= 1" };
           Apply={ fsutil behavior set disablelastaccess 1 | Out-Null };
           Revert={ fsutil behavior set disablelastaccess 0 | Out-Null } }
        @{ Id=23; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$false;
           Label="NTFS Disable 8.3 Filenames";
           ShortDesc="Disables DOS-compatible short names. Faster directory listing of large game folders.";
           LongDesc="Disabling gives faster listing of large game folders.";
           FPSGain="Dir listing";
           Check={ (fsutil behavior query disable8dot3) -match "= 1" };
           Apply={ fsutil behavior set disable8dot3 1 | Out-Null };
           Revert={ fsutil behavior set disable8dot3 0 | Out-Null } }
        @{ Id=24; Group="Filesystem / Storage"; Risk=1; NeedsReboot=$true;
           Label="Native NVMe Stack (Win11 24H2+)";
           ShortDesc="Bypasses SCSI translation. Up to 45% less CPU per I/O. EXPERIMENTAL. Only Win11 24H2+.";
           LongDesc="Bypasses SCSI translation layer for direct native NVMe driver. EXPERIMENTAL. Only on Build 26100+.";
           FPSGain="SSD speed";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950" 1 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950" } }
        @{ Id=25; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$true;
           Label="Disable Paging Executive";
           ShortDesc="Prevents kernel/driver code paging to disk. Uses ~32MB more RAM but faster kernel.";
           LongDesc="Prevents paging of kernel and driver code to disk. Minimal risk (~32MB more RAM usage). Faster kernel operations.";
           FPSGain="Kernel speed";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 1 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 0 } }
        @{ Id=26; Group="Privacy / Telemetry"; Risk=1; NeedsReboot=$false;
           Label="Disable Telemetry";
           ShortDesc="Disables Windows telemetry. Stops data collection to Microsoft.";
           LongDesc="Disables Windows telemetry and DiagTrack service. Risk: Not officially supported.";
           FPSGain="Privacy";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
                   try { Set-Service -Name "DiagTrack" -StartupType Disabled -EA SilentlyContinue
                         Stop-Service -Name "DiagTrack" -Force -EA SilentlyContinue } catch {} };
           Revert={ GO-DelReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry"
                    try { Set-Service -Name "DiagTrack" -StartupType Automatic -EA SilentlyContinue } catch {} } }
        @{ Id=27; Group="Privacy / Telemetry"; Risk=0; NeedsReboot=$false;
           Label="Search History (OFF)";
           ShortDesc="Disables device search history tracking. Privacy improvement.";
           LongDesc="Disables device search history tracking by Windows Search.";
           FPSGain="Privacy";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 1 } }
        @{ Id=28; Group="Privacy / Telemetry"; Risk=0; NeedsReboot=$false;
           Label="Share Across Devices (OFF)";
           ShortDesc="Disables cross-device sharing. Reduces background network activity.";
           LongDesc="Disables Windows cross-device sharing feature (CDP). Reduces background network activity and telemetry.";
           FPSGain="Privacy";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 1 } }
        @{ Id=29; Group="Dynamic Lighting"; Risk=0; NeedsReboot=$false;
           Label="Dynamic Lighting (OFF)";
           ShortDesc="Disables Windows 11 Dynamic Lighting for RGB peripherals. Use vendor software instead.";
           LongDesc="Disables Windows 11 Dynamic Lighting for RGB peripherals. Allows vendor software to control RGB without conflicts.";
           FPSGain="Compatibility";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 0
                   GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 1
                    GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 1 } }
    )

    function Global:GO-GetRiskColor {
        param($Risk)
        switch ($Risk) { 0{return Get-PowerToolsBrush "Success"} 1{return Get-PowerToolsBrush "Warning"} 2{return Get-PowerToolsBrush "Danger"} }
    }
    function Global:GO-GetRiskLabel { param($Risk) switch ($Risk) { 0{"SAFE"} 1{"MODERATE"} 2{"HIGH RISK"} } }

    function Global:GO-UpdateApplyState {
        $any = $false; $totalGain = 0.0; $latencyGain = $false
        foreach ($id in $script:GO_checkboxes.Keys) {
            if ($script:GO_checkboxes[$id].IsChecked -eq $true) {
                $any = $true
                $tweak = $script:GO_tweaks | Where-Object { $_.Id -eq $id } | Select-Object -First 1
                if ($tweak -and $tweak.FPSGain -match "(\d+)(?:-(\d+))?% FPS") {
                    $low = [double]$Matches[1]; $high = if ($Matches[2]) { [double]$Matches[2] } else { $low }
                    $totalGain += ($low + $high) / 2.0
                }
                if ($tweak -and $tweak.FPSGain -match "Latency|ping") { $latencyGain = $true }
            }
        }
        $script:GO_applyBtn.IsEnabled = $any
        if ($any) {
            $text = "Estimated FPS gain: ~$([math]::Round($totalGain,1))%"
            if ($latencyGain) { $text += " | Plus latency/ping improvements" }
            $script:GO_estimate.Text = "$text | All estimates without warranty"
        } else { $script:GO_estimate.Text = "No tweaks selected. All estimates without warranty." }
    }

    function Global:GO-HandleMutex {
        param($ChangedId, $IsChecked)
        if (-not $IsChecked) { return }
        $tweak = $script:GO_tweaks | Where-Object { $_.Id -eq $ChangedId } | Select-Object -First 1
        if (-not $tweak -or -not $tweak.Mutex) { return }
        foreach ($t in $script:GO_tweaks) {
            if ($t.Id -ne $ChangedId -and $t.Mutex -eq $tweak.Mutex -and $script:GO_checkboxes.ContainsKey($t.Id)) {
                $script:GO_checkboxes[$t.Id].IsChecked = $false
            }
        }
    }

    function Global:GO-ShowDetailWindow {
        param($Tweak)
        if ($script:GO_detailWindows.ContainsKey($Tweak.Id) -and $script:GO_detailWindows[$Tweak.Id].IsVisible) {
            $script:GO_detailWindows[$Tweak.Id].Activate(); return
        }
        [xml]$dXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tweak Details" Width="560" Height="440"
        WindowStartupLocation="CenterOwner" FontFamily="Segoe UI"
        ResizeMode="CanResize" MinWidth="420" MinHeight="320">
    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" x:Name="DC" Foreground="#3B5BDB" FontSize="10" FontWeight="Bold" Margin="0,0,0,4"/>
        <TextBlock Grid.Row="1" x:Name="DT" FontSize="18" FontWeight="SemiBold" TextWrapping="Wrap" Margin="0,0,0,14"/>
        <Border Grid.Row="2" x:Name="DMB" BorderThickness="1.5" CornerRadius="8" Padding="14,10" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="RISK LEVEL" Foreground="#8890B8" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DR" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <TextBlock Text="PERFORMANCE GAIN" Foreground="#8890B8" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DG" Foreground="#2A9D5C" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
                <StackPanel Grid.Column="2">
                    <TextBlock Text="REBOOT REQUIRED" Foreground="#8890B8" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DRB" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
            </Grid>
        </Border>
        <Border Grid.Row="3" x:Name="DDB" BorderThickness="1.5" CornerRadius="8" Padding="16,14">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="DLD" FontSize="13" TextWrapping="Wrap" LineHeight="20"/>
            </ScrollViewer>
        </Border>
        <Button Grid.Row="4" x:Name="DCB" Content="Close" Height="38" Padding="20,6" HorizontalAlignment="Right" Margin="0,14,0,0"/>
    </Grid>
</Window>
"@
        $r = New-Object System.Xml.XmlNodeReader $dXaml
        $dw = [Windows.Markup.XamlReader]::Load($r)
        $dw.Resources.Add("SecondaryButton", (Get-PowerToolsWindow).FindResource("SecondaryButton"))
        $dw.Resources.Add("PrimaryButton",   (Get-PowerToolsWindow).FindResource("PrimaryButton"))
        $dw.Owner = Get-PowerToolsWindow
        $dw.Background = $Global:PTS_Brush["Background"]
        $dw.FindName("DT").Foreground  = $Global:PTS_Brush["TextDark"]
        $dw.FindName("DMB").Background = $Global:PTS_Brush["Surface"]; $dw.FindName("DMB").BorderBrush = $Global:PTS_Brush["Border"]
        $dw.FindName("DDB").Background = $Global:PTS_Brush["Surface"]; $dw.FindName("DDB").BorderBrush = $Global:PTS_Brush["Border"]
        $dw.FindName("DLD").Foreground = $Global:PTS_Brush["TextDark"]
        $dw.FindName("DRB").Foreground = $Global:PTS_Brush["TextDark"]
        $dw.FindName("DC").Text  = $Tweak.Group.ToUpper()
        $dw.FindName("DT").Text  = $Tweak.Label
        $dw.FindName("DR").Text  = GO-GetRiskLabel $Tweak.Risk
        $dw.FindName("DR").Foreground = GO-GetRiskColor $Tweak.Risk
        $dw.FindName("DG").Text  = $Tweak.FPSGain
        $dw.FindName("DRB").Text = if ($Tweak.NeedsReboot) { "Yes" } else { "No" }
        $dw.FindName("DLD").Text = $Tweak.LongDesc
        $dcb = $dw.FindName("DCB")
        if ($dcb) { $dcb.Style = $dw.FindResource("SecondaryButton"); $capturedDw = $dw; $dcb.Add_Click({ $capturedDw.Close() }.GetNewClosure()) }
        $script:GO_detailWindows[$Tweak.Id] = $dw
        $dw.Show()
    }

    function Global:GO-RenderList {
        $script:GO_tweakList.Items.Clear(); $script:GO_checkboxes.Clear(); $lastGroup = ""
        foreach ($t in $script:GO_tweaks) {
            if ($t.Group -ne $lastGroup) {
                if ($lastGroup -ne "") {
                    $sep = New-Object System.Windows.Controls.Separator
                    $sep.Margin = "8,4,8,0"; $sep.Background = Get-PowerToolsBrush "Divider"
                    $script:GO_tweakList.Items.Add($sep) | Out-Null
                }
                $hdr = New-Object System.Windows.Controls.TextBlock
                $hdr.Text = $t.Group.ToUpper(); $hdr.Foreground = Get-PowerToolsBrush "Primary"
                $hdr.FontSize = 9; $hdr.FontWeight = "Bold"; $hdr.Margin = "8,10,8,2"
                $script:GO_tweakList.Items.Add($hdr) | Out-Null
                $lastGroup = $t.Group
            }
            $isOk = & $t.Check
            $row = New-Object System.Windows.Controls.Grid; $row.Margin = "8,2,8,2"; $row.MinHeight = 28
            foreach ($w in @("*","60","72","56","Auto")) {
                $col = New-Object System.Windows.Controls.ColumnDefinition; $col.Width = $w
                $row.ColumnDefinitions.Add($col) | Out-Null
            }
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.FontSize = 12; $cb.VerticalContentAlignment = "Center"; $cb.VerticalAlignment = "Center"
            $cb.Tag = $t.Id; $cb.ToolTip = $t.ShortDesc
            $cbText = New-Object System.Windows.Controls.TextBlock
            $cbText.Text = $t.Label; $cbText.TextWrapping = "NoWrap"; $cbText.TextTrimming = "CharacterEllipsis"
            $cbText.FontSize = 12; $cbText.Cursor = [System.Windows.Input.Cursors]::Hand
            $cbText.Foreground = if ($isOk) { Get-PowerToolsBrush "TextMuted" } else { Get-PowerToolsBrush "TextDark" }
            $cbText.TextDecorations = [System.Windows.TextDecorations]::Underline
            $capturedTweak = $t
            $cbText.Add_MouseLeftButtonUp({ param($s,$e) GO-ShowDetailWindow -Tweak $capturedTweak; $e.Handled=$true }.GetNewClosure())
            $cb.Content = $cbText
            if ($isOk) { $cb.IsEnabled = $false }
            else {
                $capturedId = $t.Id
                $cb.Add_Checked({ param($s,$e) GO-HandleMutex -ChangedId $capturedId -IsChecked $true; GO-UpdateApplyState }.GetNewClosure())
                $cb.Add_Unchecked({ GO-UpdateApplyState })
            }
            [System.Windows.Controls.Grid]::SetColumn($cb, 0); $row.Children.Add($cb) | Out-Null
            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text = if ($isOk){"APPLIED"}else{"MISSING"}
            $lbl.Foreground = if ($isOk){Get-PowerToolsBrush "Success"}else{Get-PowerToolsBrush "Warning"}
            $lbl.FontSize = 9; $lbl.FontWeight = "Bold"; $lbl.VerticalAlignment = "Center"; $lbl.Margin = "8,0,4,0"
            [System.Windows.Controls.Grid]::SetColumn($lbl, 1); $row.Children.Add($lbl) | Out-Null
            $riskLbl = New-Object System.Windows.Controls.TextBlock
            $riskLbl.Text = GO-GetRiskLabel $t.Risk; $riskLbl.Foreground = GO-GetRiskColor $t.Risk
            $riskLbl.FontSize = 9; $riskLbl.FontWeight = "Bold"; $riskLbl.VerticalAlignment = "Center"; $riskLbl.Margin = "4,0,4,0"
            [System.Windows.Controls.Grid]::SetColumn($riskLbl, 2); $row.Children.Add($riskLbl) | Out-Null
            $detailBtn = New-Object System.Windows.Controls.Button
            $detailBtn.Content = "Details"; $detailBtn.Style = (Get-PowerToolsWindow).FindResource("SecondaryButton")
            $detailBtn.Padding = "10,3"; $detailBtn.FontSize = 10; $detailBtn.Margin = "4,0,4,0"; $detailBtn.VerticalAlignment = "Center"
            $capturedTweak2 = $t; $detailBtn.Add_Click({ GO-ShowDetailWindow -Tweak $capturedTweak2 }.GetNewClosure())
            [System.Windows.Controls.Grid]::SetColumn($detailBtn, 3); $row.Children.Add($detailBtn) | Out-Null
            if ($isOk) {
                $resetBtn = New-Object System.Windows.Controls.Button
                $resetBtn.Content = "Reset"; $resetBtn.Style = (Get-PowerToolsWindow).FindResource("SecondaryButton")
                $resetBtn.Padding = "4,2"; $resetBtn.FontSize = 9; $resetBtn.Width = 42; $resetBtn.Height = 20
                $resetBtn.Foreground = Get-PowerToolsBrush "Warning"; $resetBtn.Margin = "0,0,4,0"
                $resetBtn.VerticalAlignment = "Center"; $resetBtn.HorizontalAlignment = "Center"
                $capturedTweak3 = $t
                $resetBtn.Add_Click({
                    $r = [System.Windows.MessageBox]::Show("Reset '$($capturedTweak3.Label)' to Windows default?`nThis reverts only this single tweak.","Confirm Reset",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
                    if ($r -eq [System.Windows.MessageBoxResult]::Yes) {
                        try { & $capturedTweak3.Revert; GO-AddLog "Reset to default: $($capturedTweak3.Label)" "OK" }
                        catch { GO-AddLog "Reset failed: $($capturedTweak3.Label) - $_" "FAIL" }
                        GO-RenderList
                    }
                }.GetNewClosure())
                [System.Windows.Controls.Grid]::SetColumn($resetBtn, 4); $row.Children.Add($resetBtn) | Out-Null
            }
            $script:GO_tweakList.Items.Add($row) | Out-Null
            $script:GO_checkboxes[$t.Id] = $cb
        }
        GO-UpdateApplyState
    }

    function Global:GO-ApplyRecommendedPreselection {
        foreach ($t in $script:GO_tweaks) {
            if ($script:GO_checkboxes.ContainsKey($t.Id) -and $script:GO_checkboxes[$t.Id].IsEnabled) {
                if (GO-IsRecommended -TweakId $t.Id) { $script:GO_checkboxes[$t.Id].IsChecked = $true }
            }
        }
        GO-UpdateApplyState
    }

    function Global:GO-CreateBackup {
        param([string]$BackupDir)
        if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
        $ts = Get-Date -Format "yyyyMMdd_HHmmss"
        if ($script:GO_cbRestore.IsChecked) {
            try { GO-AddLog "Creating System Restore Point..." "INFO"
                  Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
                  Checkpoint-Computer -Description "PowerToolsSuite_GameOptimizer_$ts" -RestorePointType "MODIFY_SETTINGS" -EA Stop
                  GO-AddLog "Restore point created." "OK" } catch { GO-AddLog "Restore point failed: $_" "WARN" }
        }
        if ($script:GO_cbRegBkp.IsChecked) {
            try { GO-AddLog "Exporting Registry backup..." "INFO"
                  reg export HKLM (Join-Path $BackupDir "HKLM_$ts.reg") /y | Out-Null
                  reg export HKCU (Join-Path $BackupDir "HKCU_$ts.reg") /y | Out-Null
                  GO-AddLog "Registry exported to: $BackupDir" "OK" } catch { GO-AddLog "Registry backup failed: $_" "WARN" }
        }
    }

    function Global:GO-SaveProfile {
        $sfd = New-Object Microsoft.Win32.SaveFileDialog
        $sfd.Title = "Save Gaming Optimizer Profile"; $sfd.Filter = "JSON Profile (*.json)|*.json"
        $sfd.FileName = "GamingProfile_$(Get-Date -Format 'yyyyMMdd').json"; $sfd.InitialDirectory = $script:GO_profilePath
        if ($sfd.ShowDialog() -ne $true) { return }
        $selected = @()
        foreach ($id in $script:GO_checkboxes.Keys) { if ($script:GO_checkboxes[$id].IsChecked -eq $true) { $selected += $id } }
        try {
            @{ Version="2.0"; Created=(Get-Date).ToString("o")
               Hardware=@{CPU=$script:GO_hw.CPU;GPU=$script:GO_hw.GPU;RAMGB=$script:GO_hw.RAMGB;Build=$script:GO_hw.Build}
               SelectedTweakIds=$selected
               Settings=@{CreateRestorePoint=$script:GO_cbRestore.IsChecked;ExportRegistry=$script:GO_cbRegBkp.IsChecked;PromptReboot=$script:GO_cbAutoReb.IsChecked}
            } | ConvertTo-Json -Depth 5 | Out-File -FilePath $sfd.FileName -Encoding UTF8
            GO-AddLog "Profile saved: $($sfd.FileName)" "OK"
        } catch { GO-AddLog "Save failed: $_" "FAIL" }
    }

    function Global:GO-LoadProfile {
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Title = "Load Gaming Optimizer Profile"; $ofd.Filter = "JSON Profile (*.json)|*.json"; $ofd.InitialDirectory = $script:GO_profilePath
        if ($ofd.ShowDialog() -ne $true) { return }
        try {
            $pd = Get-Content -Path $ofd.FileName -Raw | ConvertFrom-Json
            foreach ($id in $script:GO_checkboxes.Keys) { $script:GO_checkboxes[$id].IsChecked = $false }
            $loaded = 0; $skipped = 0
            foreach ($id in $pd.SelectedTweakIds) {
                if ($script:GO_checkboxes.ContainsKey($id) -and $script:GO_checkboxes[$id].IsEnabled) { $script:GO_checkboxes[$id].IsChecked = $true; $loaded++ } else { $skipped++ }
            }
            if ($pd.Settings) { $script:GO_cbRestore.IsChecked=$pd.Settings.CreateRestorePoint; $script:GO_cbRegBkp.IsChecked=$pd.Settings.ExportRegistry; $script:GO_cbAutoReb.IsChecked=$pd.Settings.PromptReboot }
            GO-UpdateApplyState; GO-AddLog "Profile loaded. Applied: $loaded  Skipped: $skipped" "OK"
            if ($pd.Hardware) { GO-AddLog "Profile from: $($pd.Hardware.CPU) / $($pd.Hardware.GPU)" "INFO" }
        } catch { GO-AddLog "Load failed: $_" "FAIL" }
    }

    function Global:GO-ShowSoftwareInfo {
        [xml]$sXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Recommended Third-Party Tools" Width="720" Height="620"
        WindowStartupLocation="CenterOwner" FontFamily="Segoe UI" ResizeMode="CanResize" MinWidth="520" MinHeight="480">
    <Grid Margin="22">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="THIRD-PARTY TOOLS" Foreground="#3B5BDB" FontSize="10" FontWeight="Bold" Margin="0,0,0,4"/>
        <TextBlock Grid.Row="1" x:Name="ST" FontSize="18" FontWeight="SemiBold" Margin="0,0,0,14" Text="Recommended tools that complement Windows optimizations"/>
        <Border Grid.Row="2" x:Name="SLB" BorderThickness="1.5" CornerRadius="8">
            <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="18,14"><StackPanel x:Name="SS"/></ScrollViewer>
        </Border>
        <Button Grid.Row="3" x:Name="SCB" Content="Close" Height="38" Padding="20,6" HorizontalAlignment="Right" Margin="0,14,0,0"/>
    </Grid>
</Window>
"@
        $r = New-Object System.Xml.XmlNodeReader $sXaml
        $sw = [Windows.Markup.XamlReader]::Load($r)
        $sw.Resources.Add("SecondaryButton",(Get-PowerToolsWindow).FindResource("SecondaryButton"))
        $sw.Resources.Add("PrimaryButton",(Get-PowerToolsWindow).FindResource("PrimaryButton"))
        $sw.Owner = Get-PowerToolsWindow
        $sw.Background = $Global:PTS_Brush["Background"]
        $sw.FindName("ST").Foreground  = $Global:PTS_Brush["TextDark"]
        $sw.FindName("SLB").Background = $Global:PTS_Brush["Surface"]; $sw.FindName("SLB").BorderBrush = $Global:PTS_Brush["Border"]
        $scb = $sw.FindName("SCB"); if ($scb) { $scb.Style = $sw.FindResource("SecondaryButton"); $csw=$sw; $scb.Add_Click({$csw.Close()}.GetNewClosure()) }
        $stack = $sw.FindName("SS")
        @(
            @{Name="ISLC - Intelligent Standby List Cleaner";Rec="Very High";What="Clears Windows Standby Memory List. Prevents RAM stutter from cached data.";Why="One of the most effective tools overall. Stabilizes frametimes, reduces stutter spikes especially with 16-32GB RAM.";URL="https://www.wagnardsoft.com/";Cost="Free"}
            @{Name="Process Lasso";Rec="High (Intel 12+ / AMD X3D)";What="CPU prioritization and core affinity per process. Automatic and persistent.";Why="Moves background processes to E-cores (Intel) or second CCD (AMD), reserves P-cores for game.";URL="https://bitsum.com/";Cost="Free / Pro available"}
            @{Name="NVCleanstall";Rec="High (NVIDIA users)";What="Installs NVIDIA drivers without bloatware (GeForce Experience, telemetry, NVIDIA Container).";Why="Fewer background processes, less RAM usage, cleaner driver stack.";URL="https://www.techpowerup.com/nvcleanstall/";Cost="Free"}
            @{Name="TimerResolution / TimerTool";Rec="High (Competitive)";What="Increases Windows timer resolution from default 15.6ms to 0.5ms.";Why="More precise process scheduling, more stable frametimes especially in competitive shooters.";URL="https://www.lucashale.com/timer-resolution/";Cost="Free"}
            @{Name="DDU - Display Driver Uninstaller";Rec="High";What="Complete driver removal without residue. Use before every driver update.";Why="Prevents driver conflicts, stuttering from old driver remnants, micro-crashes.";URL="https://www.wagnardsoft.com/";Cost="Free"}
            @{Name="MSI Afterburner + RTSS";Rec="High (Competitive)";What="GPU monitoring and FPS limiter.";Why="FPS limit to refresh rate -3 FPS reduces input lag significantly.";URL="https://www.msi.com/Landing/afterburner/";Cost="Free"}
            @{Name="O&O ShutUp10++";Rec="Medium";What="GUI tool for telemetry, privacy, and background processes.";Why="Quick disabling of 50+ tracking/telemetry functions.";URL="https://www.oo-software.com/en/shutup10";Cost="Free"}
            @{Name="InSpectre (Gibson Research)";Rec="Medium";What="Shows status of all CPU security mitigations (Spectre, Meltdown, Downfall).";Why="Visual control whether mitigations are active. Enables one-click deactivation if needed.";URL="https://www.grc.com/inspectre.htm";Cost="Free"}
        ) | ForEach-Object {
            $tool = $_
            $card = New-Object System.Windows.Controls.Border
            $card.Background=$Global:PTS_Brush["LogBg"]; $card.BorderBrush=$Global:PTS_Brush["LogBorder"]
            $card.BorderThickness=1; $card.CornerRadius=[System.Windows.CornerRadius]::new(8); $card.Padding="14,10"; $card.Margin="0,0,0,10"
            $cs = New-Object System.Windows.Controls.StackPanel
            $t1=New-Object System.Windows.Controls.TextBlock; $t1.Text=$tool.Name; $t1.FontSize=14; $t1.FontWeight="SemiBold"; $t1.Foreground=$Global:PTS_Brush["TextDark"]; $t1.Margin="0,0,0,6"; $cs.Children.Add($t1)|Out-Null
            $t2=New-Object System.Windows.Controls.TextBlock; $t2.Text="Recommended: $($tool.Rec)  |  Cost: $($tool.Cost)"; $t2.FontSize=10; $t2.FontWeight="Bold"; $t2.Foreground=$Global:PTS_Brush["Primary"]; $t2.Margin="0,0,0,8"; $cs.Children.Add($t2)|Out-Null
            foreach ($pair in @(@{L="WHAT IT DOES";T=$tool.What},@{L="WHY USE IT";T=$tool.Why})) {
                $lbl=New-Object System.Windows.Controls.TextBlock; $lbl.Text=$pair.L; $lbl.FontSize=9; $lbl.FontWeight="Bold"; $lbl.Foreground=$Global:PTS_Brush["TextMuted"]; $lbl.Margin="0,0,0,2"; $cs.Children.Add($lbl)|Out-Null
                $txt=New-Object System.Windows.Controls.TextBlock; $txt.Text=$pair.T; $txt.FontSize=12; $txt.TextWrapping="Wrap"; $txt.Foreground=$Global:PTS_Brush["TextDark"]; $txt.Margin="0,0,0,8"; $cs.Children.Add($txt)|Out-Null
            }
            $url=New-Object System.Windows.Controls.TextBlock; $url.Text=$tool.URL; $url.FontSize=11; $url.FontFamily="Cascadia Code, Consolas"
            $url.Foreground=$Global:PTS_Brush["Primary"]; $url.Cursor=[System.Windows.Input.Cursors]::Hand; $url.TextDecorations=[System.Windows.TextDecorations]::Underline
            $cu=$tool.URL; $url.Add_MouseLeftButtonUp({Start-Process $cu}.GetNewClosure()); $cs.Children.Add($url)|Out-Null
            $card.Child=$cs; $stack.Children.Add($card)|Out-Null
        }
        $sw.Show()
    }

    function Global:GO-RevertAll {
        $res = [System.Windows.MessageBox]::Show("Revert all tweaks to Windows default values?`n`nThis will reset ALL managed settings to Windows defaults.`n`nContinue?","Confirm Revert",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }
        GO-AddLog "Reverting all tweaks to Windows defaults..." "INFO"
        $ok=0; $fail=0; $reboot=$false
        foreach ($t in $script:GO_tweaks) {
            try { & $t.Revert; GO-AddLog "Reverted: $($t.Label)" "OK"; $ok++; if ($t.NeedsReboot) { $reboot=$true } }
            catch { GO-AddLog "Revert failed: $($t.Label) - $_" "FAIL"; $fail++ }
        }
        GO-AddLog "Revert complete. Success: $ok  Failed: $fail" "INFO"
        if ($reboot -and $script:GO_cbAutoReb.IsChecked) {
            $r=[System.Windows.MessageBox]::Show("Some reverted settings require a reboot. Restart now?","Reboot Required",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
            if ($r -eq [System.Windows.MessageBoxResult]::Yes) { Start-Sleep -Seconds 3; Restart-Computer -Force }
        }
        GO-RenderList
    }

    GO-RenderList
    GO-ApplyRecommendedPreselection
    GO-AddLog "Status check complete. Pre-selection applied based on detected hardware - please verify before applying." "INFO"

    $script:GO_selAll.Add_Click({ foreach ($id in $script:GO_checkboxes.Keys) { if ($script:GO_checkboxes[$id].IsEnabled) { $script:GO_checkboxes[$id].IsChecked=$true } }; GO-UpdateApplyState })
    $script:GO_selMissing.Add_Click({ foreach ($id in $script:GO_checkboxes.Keys) { if ($script:GO_checkboxes[$id].IsEnabled) { $script:GO_checkboxes[$id].IsChecked=$true } }; GO-UpdateApplyState })
    $script:GO_selSafe.Add_Click({
        foreach ($id in $script:GO_checkboxes.Keys) {
            $tw = $script:GO_tweaks | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            $script:GO_checkboxes[$id].IsChecked = ($script:GO_checkboxes[$id].IsEnabled -and $tw.Risk -eq 0)
        }
        GO-UpdateApplyState
    })
    $script:GO_selNone.Add_Click({ foreach ($id in $script:GO_checkboxes.Keys) { $script:GO_checkboxes[$id].IsChecked=$false }; GO-UpdateApplyState })
    $script:GO_recheckBtn.Add_Click({ GO-RenderList; GO-AddLog "Rechecked all tweaks." "INFO" })
    $script:GO_loadProfBtn.Add_Click({ GO-LoadProfile })
    $script:GO_saveProfBtn.Add_Click({ GO-SaveProfile })
    $script:GO_softInfoBtn.Add_Click({ GO-ShowSoftwareInfo })
    $script:GO_revertBtn.Add_Click({ GO-RevertAll })

    $script:GO_applyBtn.Add_Click({
        $selected = $script:GO_tweaks | Where-Object { $cb=$script:GO_checkboxes[$_.Id]; $cb -and $cb.IsChecked -eq $true -and $cb.IsEnabled }
        if (-not $selected) { GO-AddLog "Nothing selected." "WARN"; return }
        $highRisk = $selected | Where-Object { $_.Risk -eq 2 }
        if ($highRisk) {
            $names = ($highRisk | ForEach-Object { $_.Label }) -join "`n- "
            $r=[System.Windows.MessageBox]::Show("You selected HIGH RISK tweaks:`n`n- $names`n`nThese can compromise system security. Continue?","High Risk Warning",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if ($r -ne [System.Windows.MessageBoxResult]::Yes) { GO-AddLog "Cancelled by user." "WARN"; return }
        }
        if ($script:GO_cbRestore.IsChecked -or $script:GO_cbRegBkp.IsChecked) {
            GO-CreateBackup -BackupDir (Join-Path $env:USERPROFILE "Desktop\PowerToolsSuite_Backup")
        }
        GO-AddLog "Applying $($selected.Count) tweak(s)..." "INFO"
        $ok=0; $fail=0; $needsReboot=$false
        foreach ($t in $selected) {
            try { & $t.Apply; GO-AddLog "[$($t.Id.ToString().PadLeft(2))] $($t.Label)" "OK"; $ok++; if ($t.NeedsReboot) { $needsReboot=$true } }
            catch { GO-AddLog "[$($t.Id.ToString().PadLeft(2))] $($t.Label) - $_" "FAIL"; $fail++ }
        }
        GO-AddLog "Applied: $ok  Failed: $fail" "INFO"
        if ($needsReboot -and $script:GO_cbAutoReb.IsChecked) {
            GO-AddLog "Reboot required for some tweaks." "WARN"
            $res=[System.Windows.MessageBox]::Show("Some settings require a reboot.`n`nRestart now?","Reboot Required",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
            if ($res -eq [System.Windows.MessageBoxResult]::Yes) { GO-AddLog "Restarting in 5 seconds..." "WARN"; Start-Sleep -Seconds 5; Restart-Computer -Force }
        }
        GO-RenderList
    })

    $script:GO_clearLog.Add_Click({ $script:GO_logBox.Text=""; GO-AddLog "Log cleared." "INFO" })
    return $view
}
