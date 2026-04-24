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
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="160"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" Background="#FFFFFF" BorderBrush="#D0D6F0"
            BorderThickness="1.5" CornerRadius="10" Padding="16,12" Margin="0,0,0,10">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="DETECTED HARDWARE" Foreground="#8890B8" FontSize="10"
                           FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBlock x:Name="HardwareText" Foreground="#1A1F3A" FontSize="12"
                           TextWrapping="Wrap" Text="Detecting..."/>
            </StackPanel>
            <Button Grid.Column="1" x:Name="SoftwareInfoBtn" Content="Recommended Tools"
                    Style="{DynamicResource SecondaryButton}" Padding="14,8"
                    FontSize="12" VerticalAlignment="Center" Margin="12,0,0,0"/>
        </Grid>
    </Border>

    <Border Grid.Row="1" Background="#FFF4E5" BorderBrush="#D9822B"
            BorderThickness="1.5" CornerRadius="10" Padding="14,10" Margin="0,0,0,10">
        <StackPanel>
            <TextBlock Text="BACKUP OPTIONS" Foreground="#8F4F0A" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,6"/>
            <WrapPanel>
                <CheckBox x:Name="CbRestorePoint" Content="Create System Restore Point before applying"
                          IsChecked="True" Margin="0,0,18,4" FontSize="12" Foreground="#1A1F3A"/>
                <CheckBox x:Name="CbRegBackup" Content="Export Registry backup (.reg files)"
                          IsChecked="True" Margin="0,0,18,4" FontSize="12" Foreground="#1A1F3A"/>
                <CheckBox x:Name="CbAutoReboot" Content="Prompt for reboot when needed"
                          IsChecked="True" Margin="0,0,0,4" FontSize="12" Foreground="#1A1F3A"/>
            </WrapPanel>
        </StackPanel>
    </Border>

    <Grid Grid.Row="2" Margin="0,0,0,10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="SELECT TWEAKS TO APPLY"
                   Foreground="#8890B8" FontSize="10" FontWeight="Bold" VerticalAlignment="Center"/>
        <Button Grid.Column="1" x:Name="SelectAllBtn" Content="All"
                Style="{DynamicResource SecondaryButton}" Padding="10,6" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="2" x:Name="SelectMissingBtn" Content="Missing Only"
                Style="{DynamicResource SecondaryButton}" Padding="10,6" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="3" x:Name="SelectSafeBtn" Content="Safe Only"
                Style="{DynamicResource SecondaryButton}" Padding="10,6" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="4" x:Name="SelectNoneBtn" Content="None"
                Style="{DynamicResource SecondaryButton}" Padding="10,6" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="5" x:Name="LoadProfileBtn" Content="Load Profile"
                Style="{DynamicResource SecondaryButton}" Padding="10,6" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="6" x:Name="SaveProfileBtn" Content="Save Profile"
                Style="{DynamicResource SecondaryButton}" Padding="10,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="3" Background="#FFFFFF" BorderBrush="#D0D6F0"
            BorderThickness="1.5" CornerRadius="10">
        <ScrollViewer VerticalScrollBarVisibility="Auto">
            <ItemsControl x:Name="TweakList" Margin="4,4,4,4"/>
        </ScrollViewer>
    </Border>

    <Border Grid.Row="4" Background="#EEF1FC" BorderBrush="#B5C0E8"
            BorderThickness="1" CornerRadius="8" Padding="14,10" Margin="0,12,0,10">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="ESTIMATED PERFORMANCE GAIN (selected tweaks)" Foreground="#8890B8"
                           FontSize="10" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBlock x:Name="EstimateText" Foreground="#1A1F3A" FontSize="12"
                           Text="No tweaks selected. All estimates without warranty."/>
            </StackPanel>
            <TextBlock Grid.Column="1" Text="Click any tweak name for full details"
                       Foreground="#8890B8" FontSize="10" FontStyle="Italic"
                       VerticalAlignment="Center"/>
        </Grid>
    </Border>

    <Grid Grid.Row="5" Margin="0,0,0,10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="160"/>
            <ColumnDefinition Width="200"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ApplyBtn" Content="Apply Selected"
                Style="{DynamicResource PrimaryButton}" Height="44" FontSize="13"
                Margin="0,0,6,0" IsEnabled="False"/>
        <Button Grid.Column="1" x:Name="RecheckBtn" Content="Recheck All"
                Style="{DynamicResource SecondaryButton}" Height="44" FontSize="12" Margin="0,0,6,0"/>
        <Button Grid.Column="2" x:Name="RevertBtn" Content="Revert to Windows Defaults"
                Style="{DynamicResource SecondaryButton}" Height="44" FontSize="12"/>
    </Grid>

    <Border Grid.Row="6" Background="#FAFBFF" BorderBrush="#D8DEFA"
            BorderThickness="1.5" CornerRadius="10">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0" Margin="14,10,14,4">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="10"
                           FontWeight="Bold" VerticalAlignment="Center"/>
                <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                        Style="{DynamicResource SecondaryButton}" Padding="10,4" FontSize="10"/>
            </Grid>
            <ScrollViewer Grid.Row="1" x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogBox" Foreground="#8890B8"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="11" Padding="14,6,14,12" TextWrapping="Wrap"
                           LineHeight="18" Text="Ready. Detecting hardware and checking current status..."/>
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

    # Controls
    $script:GO_hwText      = $view.FindName("HardwareText")
    $script:GO_cbRestore   = $view.FindName("CbRestorePoint")
    $script:GO_cbRegBkp    = $view.FindName("CbRegBackup")
    $script:GO_cbAutoReb   = $view.FindName("CbAutoReboot")
    $script:GO_tweakList   = $view.FindName("TweakList")
    $script:GO_estimate    = $view.FindName("EstimateText")
    $script:GO_applyBtn    = $view.FindName("ApplyBtn")
    $script:GO_recheckBtn  = $view.FindName("RecheckBtn")
    $script:GO_revertBtn   = $view.FindName("RevertBtn")
    $script:GO_selAll      = $view.FindName("SelectAllBtn")
    $script:GO_selMissing  = $view.FindName("SelectMissingBtn")
    $script:GO_selSafe     = $view.FindName("SelectSafeBtn")
    $script:GO_selNone     = $view.FindName("SelectNoneBtn")
    $script:GO_loadProfBtn = $view.FindName("LoadProfileBtn")
    $script:GO_saveProfBtn = $view.FindName("SaveProfileBtn")
    $script:GO_softInfoBtn = $view.FindName("SoftwareInfoBtn")
    $script:GO_clearLog    = $view.FindName("ClearLogBtn")
    $script:GO_logBox      = $view.FindName("LogBox")
    $script:GO_logScroller = $view.FindName("LogScroller")
    $script:GO_initText    = "Ready. Detecting hardware and checking current status..."
    $script:GO_checkboxes  = @{}
    $script:GO_detailWindows = @{}
    $script:GO_profilePath = Join-Path $env:LOCALAPPDATA "PowerToolsSuite\GamingOptimizer"
    if (-not (Test-Path $script:GO_profilePath)) { New-Item -ItemType Directory -Path $script:GO_profilePath -Force | Out-Null }

    function Global:GO-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:GO_logBox.Text -eq $script:GO_initText) { $script:GO_logBox.Text = $entry }
        else { $script:GO_logBox.Text += $entry }
        $script:GO_logScroller.Dispatcher.Invoke([action]{ $script:GO_logScroller.ScrollToEnd() })
    }

    # Registry Helpers
    function Global:GO-GetReg  { param($p,$n) try { (Get-ItemProperty -Path $p -Name $n -EA Stop).$n } catch { $null } }
    function Global:GO-SetDW   { param($p,$n,$v) if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name $n -Value $v -Type DWord -Force }
    function Global:GO-SetStr  { param($p,$n,$v) if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name $n -Value $v -Type String -Force }
    function Global:GO-DelReg  { param($p,$n) try { Remove-ItemProperty -Path $p -Name $n -Force -EA Stop } catch {} }

    # Hardware Detection
    function Global:GO-DetectHardware {
        $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
        $gpu = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Basic|Virtual" } | Select-Object -First 1).Name
        $ramGB = [math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB), 0)
        $build = [System.Environment]::OSVersion.Version.Build
        $isX3D = $cpu -match "X3D"
        $isIntel12Plus = $cpu -match "1[2-9]\d{3}|2\d{4}"
        $isAMDRyzen5000Plus = $cpu -match "Ryzen.*[5-9]\d{3}|Ryzen.*X3D"

        $text = "CPU: $cpu`nGPU: $gpu`nRAM: $ramGB GB | Windows Build: $build"
        if ($isX3D)            { $text += "`n[!] AMD X3D detected - Xbox Game Bar and Game Mode must stay ACTIVE" }
        if ($build -ge 26100)  { $text += "`n[i] Windows 11 24H2+ - Native NVMe Stack available" }

        $script:GO_hwText.Text = $text

        return @{
            CPU=$cpu; GPU=$gpu; RAMGB=$ramGB; Build=$build
            IsX3D=$isX3D; IsIntel12Plus=$isIntel12Plus; IsAMDRyzen5000Plus=$isAMDRyzen5000Plus
        }
    }

    $script:GO_hw = GO-DetectHardware

    # Profile detection logic - what gets pre-selected based on hardware
    function Global:GO-IsRecommended {
        param($TweakId)
        # High-impact, safe tweaks always recommended
        $alwaysRecommended = @(1,2,3,4,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,25,26,27,28)
        if ($alwaysRecommended -contains $TweakId) { return $true }
        # X3D-specific: keep Xbox services active
        if ($script:GO_hw.IsX3D -and $TweakId -eq 5) { return $false }
        # NVMe stack only on Win11 24H2+
        if ($TweakId -eq 24 -and $script:GO_hw.Build -lt 26100) { return $false }
        if ($TweakId -eq 24 -and $script:GO_hw.Build -ge 26100) { return $true }
        return $false
    }

    # TWEAKS DEFINITION
    # Risk: 0=Safe 1=Moderate 2=High
    # NeedsReboot, Group, Label, ShortDesc, LongDesc, FPSGain, Category (for mutex groups)
    $script:GO_tweaks = @(
        # ==================== BLOCK 1: SECURITY / HIGH IMPACT ====================
        @{ Id=1; Group="Security - High Impact"; Risk=1; NeedsReboot=$true;
           Label="Memory Integrity / HVCI (OFF)";
           ShortDesc="Disables Hypervisor-Protected Code Integrity. Biggest FPS gainer. Validates kernel drivers via hypervisor.";
           LongDesc="Hypervisor-Protected Code Integrity (HVCI) validates every kernel driver access via hypervisor. Disabling yields 3-25% FPS gain, more stable 1% lows, significantly less microstutter in CPU-limited games. Risk: Kernel exploits through manipulated drivers become possible. Acceptable for dedicated gaming PC without sensitive data.";
           FPSGain="3-25% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
                   GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 1
                    GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 1 } }

        @{ Id=2; Group="Security - High Impact"; Risk=1; NeedsReboot=$true;
           Label="Disable VBS / Virtual Machine Platform";
           ShortDesc="Disables Hyper-V hypervisor base. Uses CPU cycles even without active VMs. Eliminates VBS overhead.";
           LongDesc="Virtual Machine Platform is the Hyper-V hypervisor base. It consumes CPU cycles even without active VMs. Disabling yields 2-5% additional CPU performance and fully eliminates VBS overhead. Risk: WSL2, Hyper-V, Docker will not work. Ideal for pure gaming PC without VM needs.";
           FPSGain="2-5% FPS";
           Check={ (bcdedit /enum "{current}" | Select-String "hypervisorlaunchtype\s+Off") -ne $null };
           Apply={ bcdedit /set hypervisorlaunchtype off | Out-Null
                   try { Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -EA SilentlyContinue | Out-Null } catch {} };
           Revert={ bcdedit /set hypervisorlaunchtype auto | Out-Null } }

        @{ Id=3; Group="Security - High Impact"; Risk=0; NeedsReboot=$false;
           Label="GameDVR / Xbox Recording (OFF)";
           ShortDesc="Disables Xbox Game Bar background recording. Runs even when not actively used. Reduces GPU/CPU overhead.";
           LongDesc="Xbox Game Bar runs background recording even when not actively used. Disabling reduces GPU/CPU overhead and prevents uncontrolled FPS drops. Note: Clip function is lost - irrelevant for gaming PC without streaming.";
           FPSGain="1-2% FPS";
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_Enabled") -eq 0 -and (GO-GetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR") -eq 0 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
                   GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2
                   GO-SetDW "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 };
           Revert={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1
                    GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior"
                    GO-DelReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" } }

        @{ Id=4; Group="Security - High Impact"; Risk=2; NeedsReboot=$true;
           Label="Spectre/Meltdown Mitigations (OFF) - HIGH RISK";
           ShortDesc="HIGH RISK. Disables CPU security patches. Only for isolated gaming PC without sensitive data. Yields 5-10% FPS.";
           LongDesc="CRITICAL WARNING: Disables CPU security patches for Spectre/Meltdown vulnerabilities. These patches cause 5-10% performance loss (especially Intel pre-10th Gen). Yields 5-10% FPS gain, noticeable in syscall-heavy systems. Extreme Risk: Side-channel attacks become possible. Only use on isolated gaming PC without sensitive browsing or banking.";
           FPSGain="5-10% FPS (old CPUs)";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride") -eq 3 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride" 3
                   GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" 3 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride"
                    GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" } }

        # ==================== BLOCK 2: POWER / CPU ====================
        @{ Id=5; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Ultimate Performance Power Plan";
           ShortDesc="Activates hidden Ultimate Performance plan. Disables core parking. Sets min CPU clock to 100%.";
           LongDesc="Hidden power plan that disables core parking and sets minimum CPU clock to 100%. Eliminates CPU wake latencies, instant response to load spikes. Yields 5-15% FPS. Risk: Higher idle power consumption and heat. Unproblematic for desktop.";
           FPSGain="5-15% FPS";
           Check={ (powercfg -list | Select-String "Ultimate Performance") -ne $null -and (powercfg -getactivescheme | Select-String "Ultimate") -ne $null };
           Apply={ powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
                   $g = (powercfg -list | Select-String "Ultimate Performance" | ForEach-Object { ($_ -split "\s+")[3] } | Select-Object -First 1)
                   if ($g) { powercfg -setactive $g | Out-Null } };
           Revert={ powercfg -setactive SCHEME_BALANCED | Out-Null } }

        @{ Id=6; Group="Power / CPU"; Risk=1; NeedsReboot=$true;
           Label="Disable Power Throttling";
           ShortDesc="Prevents Windows from throttling CPU for background processes. All processes get full resources.";
           LongDesc="Windows automatically throttles CPU resources for background processes. Disabling gives all processes full resources - less frame variance. Risk: Background processes can consume more CPU. Acceptable for gaming PC.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" } }

        @{ Id=7; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="System Responsiveness = 10";
           ShortDesc="Controls CPU share for multimedia/foreground apps. More CPU cycles for active applications.";
           LongDesc="Controls CPU share for multimedia and foreground applications. Default is 20. Value 10 is moderate and recommended for stability. Value 0 is maximally aggressive but can severely impair background services.";
           FPSGain="1-2% FPS";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness") -eq 10 };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 10 };
           Revert={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 20 } }

        @{ Id=8; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Network Throttling Disabled";
           ShortDesc="Removes network throughput limit. Better network latency and throughput.";
           LongDesc="Windows limits network throughput to save CPU. Disabling improves network latency and throughput. Risk: On weak connections possible jitter. On Gigabit no problem.";
           FPSGain="Latency";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex") -eq 0xFFFFFFFF };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF };
           Revert={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10 } }

        @{ Id=9; Group="Power / CPU"; Risk=0; NeedsReboot=$false; Mutex="PrioritySep";
           Label="Win32PrioritySeparation = 36 (Competitive)";
           ShortDesc="Short variable quanta without focus boost. Minimal scheduling latency. Best for competitive shooters.";
           LongDesc="Controls CPU time quanta per process before context switch. Value 36 (0x24) uses short variable quanta without focus boost - minimal scheduling latency. Best for competitive shooters. Background tasks much slower. Conflicts with value 24 option.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x24 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x24 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x26 } }

        @{ Id=10; Group="Power / CPU"; Risk=0; NeedsReboot=$false; Mutex="PrioritySep";
           Label="Win32PrioritySeparation = 24 (AAA Games)";
           ShortDesc="Long fixed quanta (server mode). Maximum consistency for games with many background threads.";
           LongDesc="Value 24 (0x18) uses long fixed quanta in server mode - maximum consistency for AAA games with many background threads. Better for open-world and simulation titles. Conflicts with value 36 option.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x18 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x18 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x26 } }

        @{ Id=11; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Startup Delay Disabled";
           ShortDesc="Removes artificial startup delay for autostart apps. Faster desktop after login.";
           LongDesc="Windows artificially delays autostart apps after login. Disabling gives a faster desktop after login. Minimal risk.";
           FPSGain="Boot speed";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 };
           Revert={ GO-DelReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" } }

        # ==================== BLOCK 3: GRAPHICS / GAMING ====================
        @{ Id=12; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$true;
           Label="Hardware-Accelerated GPU Scheduling (ON)";
           ShortDesc="GPU manages its own memory and tasks instead of CPU. Required for DLSS 3 Frame Generation.";
           LongDesc="GPU takes over own memory and task management instead of CPU. Reduces system latency by ~2ms, more stable frametimes. Mandatory for DLSS 3 Frame Generation. Requires Nvidia 451.48+ or AMD 20.5.1+. On very old GPUs/drivers can cause stuttering.";
           FPSGain="1-5% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode") -eq 2 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1 } }

        @{ Id=13; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Windows Game Mode (ON)";
           ShortDesc="Prioritizes game threads. Pauses Windows updates during gaming. REQUIRED for AMD X3D CPUs.";
           LongDesc="Prioritizes game threads and pauses Windows Update downloads during gaming. More stable FPS, fewer interruptions. CRITICAL: Must stay ON for AMD X3D chips (7800X3D, 7950X3D etc.). Communicates with AMD chipset driver for cache allocation. Disabling costs up to -15% FPS on X3D.";
           FPSGain="1-5% FPS";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled") -eq 1 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0 } }

        @{ Id=14; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Windowed Game Optimizations (Flip Model)";
           ShortDesc="Modern flip presentation for DirectX 10/11 windowed games. Fullscreen latency in windowed mode.";
           LongDesc="Modern flip presentation system for all DirectX 10/11 windowed games. Latency at fullscreen level, enables VRR/Auto-HDR in windowed mode. Rarely incompatibilities with older overlays.";
           FPSGain="Latency";
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode") -eq 2 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
                   GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1 };
           Revert={ GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode"
                    GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" } }

        @{ Id=15; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Games Task Scheduling = High";
           ShortDesc="Sets Multimedia scheduler priority for games to High. More CPU cycles for gaming threads.";
           LongDesc="Sets Multimedia scheduler priority for games to High. More CPU cycles for gaming threads. No negative side effects.";
           FPSGain="1% FPS";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category") -eq "High" };
           Apply={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" };
           Revert={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "Medium" } }

        # ==================== BLOCK 4: NETWORK ====================
        @{ Id=16; Group="Network"; Risk=1; NeedsReboot=$false;
           Label="Disable Nagle Algorithm";
           ShortDesc="Bundles small TCP packets - artificially raises ping in real-time games. Disabling reduces ping 10-30ms.";
           LongDesc="Nagle algorithm bundles small TCP packets, artificially raising ping in real-time games. Disabling yields immediate packet sending - 10-30ms ping reduction in online games. Risk: More packets, on weak connections possible overhead.";
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
                   GO-SetDW $p "TcpAckFrequency" 1
                   GO-SetDW $p "TCPNoDelay" 1
                   GO-SetDW $p "TcpDelAckTicks" 0
               }
           };
           Revert={
               $nics = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceType -eq 6}
               foreach ($n in $nics) {
                   $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.InterfaceGuid)"
                   GO-DelReg $p "TcpAckFrequency"
                   GO-DelReg $p "TCPNoDelay"
                   GO-DelReg $p "TcpDelAckTicks"
               }
           } }

        @{ Id=17; Group="Network"; Risk=0; NeedsReboot=$false;
           Label="Advanced TCP Optimizations";
           ShortDesc="Enables RSS, disables RSC/ECN/timestamps. Better network throughput and latency.";
           LongDesc="Multiple netsh optimizations: autotuning=normal (optimal throughput), RSS=enabled (multi-core network distribution), RSC=disabled (less latency), ECN=disabled (more stable ping), timestamps=disabled (less header overhead).";
           FPSGain="Latency";
           Check={ (netsh int tcp show global | Select-String "Receive Segment Coalescing.*disabled") -ne $null };
           Apply={
               netsh int tcp set global autotuninglevel=normal | Out-Null
               netsh int tcp set global rss=enabled | Out-Null
               netsh int tcp set global rsc=disabled | Out-Null
               netsh int tcp set global ecncapability=disabled | Out-Null
               netsh int tcp set global timestamps=disabled | Out-Null
           };
           Revert={
               netsh int tcp set global autotuninglevel=normal | Out-Null
               netsh int tcp set global rss=default | Out-Null
               netsh int tcp set global rsc=default | Out-Null
               netsh int tcp set global ecncapability=default | Out-Null
               netsh int tcp set global timestamps=default | Out-Null
           } }

        # ==================== BLOCK 5: UI / VISUAL ====================
        @{ Id=18; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Transparency Effects (OFF)";
           ShortDesc="Disables Windows transparency effects. Less GPU overhead for UI.";
           LongDesc="Windows transparency effects (Acrylic, Mica) consume GPU resources. Disabling yields minimal FPS gain but reduces UI overhead. No functional loss.";
           FPSGain="0-1% FPS";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 1 } }

        @{ Id=19; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Window Animations (OFF)";
           ShortDesc="Disables window minimize/maximize animations. Snappier UI response.";
           LongDesc="Disables window animations for minimize/maximize. Snappier UI response. Zero impact on games, purely desktop.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" };
           Revert={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "1" } }

        @{ Id=20; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Menu Show Delay = 0";
           ShortDesc="Removes menu open delay. Instant menu response.";
           LongDesc="Windows has a default 400ms menu show delay. Setting to 0 gives instant menu response. Zero risk.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop" "MenuShowDelay") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" };
           Revert={ GO-SetStr "HKCU:\Control Panel\Desktop" "MenuShowDelay" "400" } }

        @{ Id=21; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Taskbar Animations (OFF)";
           ShortDesc="Disables taskbar animations. Snappier taskbar response.";
           LongDesc="Disables taskbar animations. Snappier response when hovering or clicking taskbar. Zero impact on games.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 1 } }

        # ==================== BLOCK 6: FILESYSTEM ====================
        @{ Id=22; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$false;
           Label="NTFS Disable Last Access Time";
           ShortDesc="Windows writes timestamp on every read. Reduces SSD writes. Extends SSD lifespan.";
           LongDesc="Windows writes a timestamp on every read access. Disabling reduces I/O operations and extends SSD lifespan. No negative side effects.";
           FPSGain="SSD life";
           Check={ (fsutil behavior query disablelastaccess) -match "= 1" };
           Apply={ fsutil behavior set disablelastaccess 1 | Out-Null };
           Revert={ fsutil behavior set disablelastaccess 0 | Out-Null } }

        @{ Id=23; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$false;
           Label="NTFS Disable 8.3 Filenames";
           ShortDesc="Disables DOS-compatible short names. Faster directory listing of large game folders.";
           LongDesc="Windows creates DOS-compatible short filenames for every file - slows directory listing. Disabling gives faster listing of large game folders (thousands of files). Very old DOS programs might fail - irrelevant for gaming PC.";
           FPSGain="Dir listing";
           Check={ (fsutil behavior query disable8dot3) -match "= 1" };
           Apply={ fsutil behavior set disable8dot3 1 | Out-Null };
           Revert={ fsutil behavior set disable8dot3 0 | Out-Null } }

        @{ Id=24; Group="Filesystem / Storage"; Risk=1; NeedsReboot=$true;
           Label="Native NVMe Stack (Win11 24H2+)";
           ShortDesc="Bypasses SCSI translation. Up to 45% less CPU per I/O. EXPERIMENTAL. Only Win11 24H2+.";
           LongDesc="Bypasses SCSI translation layer for direct native NVMe driver. Yields up to 45% less CPU per I/O operation, up to 80% more IOPS. EXPERIMENTAL. Only on Build 26100+ (24H2). SSD management tools may detect drive twice.";
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

        # ==================== BLOCK 7: PRIVACY / TELEMETRY ====================
        @{ Id=26; Group="Privacy / Telemetry"; Risk=1; NeedsReboot=$false;
           Label="Disable Telemetry";
           ShortDesc="Disables Windows telemetry. Stops data collection to Microsoft.";
           LongDesc="Disables Windows telemetry and DiagTrack service. Stops data collection to Microsoft. Risk: Not officially supported. Find My Device and Insider features limited.";
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
           LongDesc="Disables device search history tracking by Windows Search. Privacy improvement. No negative effects on search functionality.";
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

        # ==================== BLOCK 8: LIGHTING ====================
        @{ Id=29; Group="Dynamic Lighting"; Risk=0; NeedsReboot=$false;
           Label="Dynamic Lighting (OFF)";
           ShortDesc="Disables Windows 11 Dynamic Lighting for RGB peripherals. Use vendor software instead.";
           LongDesc="Disables Windows 11 Dynamic Lighting for RGB peripherals. Allows vendor software (Razer Synapse, Logitech G Hub, Corsair iCUE) to control RGB without conflicts.";
           FPSGain="Compatibility";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 0
                   GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 1
                    GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 1 } }
    )

    function Global:GO-GetRiskColor {
        param($Risk)
        switch ($Risk) {
            0 { return Get-PowerToolsBrush "Success" }
            1 { return Get-PowerToolsBrush "Warning" }
            2 { return Get-PowerToolsBrush "Danger" }
        }
    }

    function Global:GO-GetRiskLabel {
        param($Risk)
        switch ($Risk) { 0 {"SAFE"} 1 {"MODERATE"} 2 {"HIGH RISK"} }
    }

    function Global:GO-UpdateApplyState {
        $any = $false
        $totalGain = 0.0
        $latencyGain = $false
        foreach ($id in $script:GO_checkboxes.Keys) {
            if ($script:GO_checkboxes[$id].IsChecked -eq $true) {
                $any = $true
                $tweak = $script:GO_tweaks | Where-Object { $_.Id -eq $id } | Select-Object -First 1
                if ($tweak -and $tweak.FPSGain -match "(\d+)(?:-(\d+))?% FPS") {
                    $low = [double]$Matches[1]
                    $high = if ($Matches[2]) { [double]$Matches[2] } else { $low }
                    $totalGain += ($low + $high) / 2.0
                }
                if ($tweak -and $tweak.FPSGain -match "Latency|ping") { $latencyGain = $true }
            }
        }
        $script:GO_applyBtn.IsEnabled = $any
        if ($any) {
            $text = "Estimated FPS gain: ~$([math]::Round($totalGain,1))%"
            if ($latencyGain) { $text += " | Plus latency/ping improvements" }
            $text += " | All estimates without warranty"
            $script:GO_estimate.Text = $text
        } else {
            $script:GO_estimate.Text = "No tweaks selected. All estimates without warranty."
        }
    }

    function Global:GO-HandleMutex {
        param($ChangedId, $IsChecked)
        if (-not $IsChecked) { return }
        $tweak = $script:GO_tweaks | Where-Object { $_.Id -eq $ChangedId } | Select-Object -First 1
        if (-not $tweak -or -not $tweak.Mutex) { return }
        foreach ($t in $script:GO_tweaks) {
            if ($t.Id -ne $ChangedId -and $t.Mutex -eq $tweak.Mutex) {
                if ($script:GO_checkboxes.ContainsKey($t.Id)) {
                    $script:GO_checkboxes[$t.Id].IsChecked = $false
                }
            }
        }
    }

    function Global:GO-ShowDetailWindow {
        param($Tweak)
        if ($script:GO_detailWindows.ContainsKey($Tweak.Id) -and $script:GO_detailWindows[$Tweak.Id].IsVisible) {
            $script:GO_detailWindows[$Tweak.Id].Activate()
            return
        }

        [xml]$detailXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tweak Details"
        Width="560" Height="440"
        WindowStartupLocation="CenterOwner"
        Background="#F4F6FB" FontFamily="Segoe UI"
        ResizeMode="CanResize" MinWidth="420" MinHeight="320">
    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" x:Name="DetailCategory" Foreground="#3B5BDB" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,4"/>
        <TextBlock Grid.Row="1" x:Name="DetailTitle" Foreground="#1A1F3A" FontSize="18"
                   FontWeight="SemiBold" TextWrapping="Wrap" Margin="0,0,0,14"/>
        <Border Grid.Row="2" Background="#FFFFFF" BorderBrush="#D0D6F0"
                BorderThickness="1.5" CornerRadius="8" Padding="14,10" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="RISK LEVEL" Foreground="#8890B8" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DetailRisk" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <TextBlock Text="PERFORMANCE GAIN" Foreground="#8890B8" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DetailGain" Foreground="#2A9D5C" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
                <StackPanel Grid.Column="2">
                    <TextBlock Text="REBOOT REQUIRED" Foreground="#8890B8" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DetailReboot" Foreground="#1A1F3A" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
            </Grid>
        </Border>
        <Border Grid.Row="3" Background="#FFFFFF" BorderBrush="#D0D6F0"
                BorderThickness="1.5" CornerRadius="8" Padding="16,14">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="DetailLongDesc" Foreground="#1A1F3A" FontSize="13"
                           TextWrapping="Wrap" LineHeight="20"/>
            </ScrollViewer>
        </Border>
        <Button Grid.Row="4" x:Name="DetailCloseBtn" Content="Close"
                Style="{DynamicResource SecondaryButton}" Height="38"
                Padding="20,6" HorizontalAlignment="Right" Margin="0,14,0,0"/>
    </Grid>
</Window>
"@
        $r = New-Object System.Xml.XmlNodeReader $detailXaml
        $dw = [Windows.Markup.XamlReader]::Load($r)
        $dw.Resources.Add("SecondaryButton", (Get-PowerToolsWindow).FindResource("SecondaryButton"))
        $dw.Owner = Get-PowerToolsWindow

        $dw.FindName("DetailCategory").Text = $Tweak.Group.ToUpper()
        $dw.FindName("DetailTitle").Text    = $Tweak.Label
        $dw.FindName("DetailRisk").Text     = GO-GetRiskLabel $Tweak.Risk
        $dw.FindName("DetailRisk").Foreground = GO-GetRiskColor $Tweak.Risk
        $dw.FindName("DetailGain").Text     = $Tweak.FPSGain
        $dw.FindName("DetailReboot").Text   = if ($Tweak.NeedsReboot) { "Yes" } else { "No" }
        $dw.FindName("DetailLongDesc").Text = $Tweak.LongDesc
        $dw.FindName("DetailCloseBtn").Add_Click({ $dw.Close() })

        $script:GO_detailWindows[$Tweak.Id] = $dw
        $dw.Show()
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
            $c3 = New-Object System.Windows.Controls.ColumnDefinition; $c3.Width = "Auto"
            $c4 = New-Object System.Windows.Controls.ColumnDefinition; $c4.Width = "Auto"
            $row.ColumnDefinitions.Add($c1); $row.ColumnDefinitions.Add($c2)
            $row.ColumnDefinitions.Add($c3); $row.ColumnDefinitions.Add($c4)

            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.FontSize    = 13
            $cb.VerticalContentAlignment = "Center"
            $cb.Tag         = $t.Id
            $cb.ToolTip     = $t.ShortDesc

            # Make checkbox content a clickable textblock for detail view
            $cbText = New-Object System.Windows.Controls.TextBlock
            $cbText.Text       = $t.Label
            $cbText.TextWrapping = "Wrap"
            $cbText.Cursor     = [System.Windows.Input.Cursors]::Hand
            $cbText.Foreground = if ($isOk) { Get-PowerToolsBrush "TextMuted" } else { Get-PowerToolsBrush "TextDark" }
            $cbText.TextDecorations = [System.Windows.TextDecorations]::Underline
            $capturedTweak = $t
            $cbText.Add_MouseLeftButtonUp({
                param($sender, $e)
                GO-ShowDetailWindow -Tweak $capturedTweak
                $e.Handled = $true
            }.GetNewClosure())
            $cb.Content = $cbText

            if ($isOk) {
                $cb.IsEnabled = $false
            } else {
                $capturedId = $t.Id
                $cb.Add_Checked({
                    param($sender, $e)
                    GO-HandleMutex -ChangedId $capturedId -IsChecked $true
                    GO-UpdateApplyState
                }.GetNewClosure())
                $cb.Add_Unchecked({ GO-UpdateApplyState })
            }
            [System.Windows.Controls.Grid]::SetColumn($cb, 0)
            $row.Children.Add($cb) | Out-Null

            # Status badge
            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text       = if ($isOk) { "APPLIED" } else { "MISSING" }
            $lbl.Foreground = if ($isOk) { Get-PowerToolsBrush "Success" } else { Get-PowerToolsBrush "Warning" }
            $lbl.FontSize   = 9
            $lbl.FontWeight = "Bold"
            $lbl.VerticalAlignment = "Center"
            $lbl.Margin = "8,0,4,0"
            [System.Windows.Controls.Grid]::SetColumn($lbl, 1)
            $row.Children.Add($lbl) | Out-Null

            # Risk badge
            $riskLbl = New-Object System.Windows.Controls.TextBlock
            $riskLbl.Text       = GO-GetRiskLabel $t.Risk
            $riskLbl.Foreground = GO-GetRiskColor $t.Risk
            $riskLbl.FontSize   = 9
            $riskLbl.FontWeight = "Bold"
            $riskLbl.VerticalAlignment = "Center"
            $riskLbl.Margin = "4,0,4,0"
            [System.Windows.Controls.Grid]::SetColumn($riskLbl, 2)
            $row.Children.Add($riskLbl) | Out-Null

            # Details button
            $detailBtn = New-Object System.Windows.Controls.Button
            $detailBtn.Content = "Details"
            $detailBtn.Style   = (Get-PowerToolsWindow).FindResource("SecondaryButton")
            $detailBtn.Padding = "10,3"
            $detailBtn.FontSize = 10
            $detailBtn.Margin  = "4,0,6,0"
            $detailBtn.VerticalAlignment = "Center"
            $capturedTweak2 = $t
            $detailBtn.Add_Click({
                GO-ShowDetailWindow -Tweak $capturedTweak2
            }.GetNewClosure())
            [System.Windows.Controls.Grid]::SetColumn($detailBtn, 3)
            $row.Children.Add($detailBtn) | Out-Null

            $script:GO_tweakList.Items.Add($row) | Out-Null
            $script:GO_checkboxes[$t.Id] = $cb
        }
        GO-UpdateApplyState
    }

    # Pre-selection based on hardware
    function Global:GO-ApplyRecommendedPreselection {
        foreach ($t in $script:GO_tweaks) {
            if ($script:GO_checkboxes.ContainsKey($t.Id) -and $script:GO_checkboxes[$t.Id].IsEnabled) {
                if (GO-IsRecommended -TweakId $t.Id) {
                    $script:GO_checkboxes[$t.Id].IsChecked = $true
                }
            }
        }
        GO-UpdateApplyState
    }

    # Backup Functions
    function Global:GO-CreateBackup {
        param([string]$BackupDir)
        if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
        $ts = Get-Date -Format "yyyyMMdd_HHmmss"

        if ($script:GO_cbRestore.IsChecked) {
            try {
                GO-AddLog "Creating System Restore Point..." "INFO"
                Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
                Checkpoint-Computer -Description "PowerToolsSuite_GameOptimizer_$ts" -RestorePointType "MODIFY_SETTINGS" -EA Stop
                GO-AddLog "Restore point created." "OK"
            } catch {
                GO-AddLog "Restore point failed: $_" "WARN"
            }
        }

        if ($script:GO_cbRegBkp.IsChecked) {
            try {
                GO-AddLog "Exporting Registry backup..." "INFO"
                $hklmPath = Join-Path $BackupDir "HKLM_$ts.reg"
                $hkcuPath = Join-Path $BackupDir "HKCU_$ts.reg"
                reg export HKLM $hklmPath /y | Out-Null
                reg export HKCU $hkcuPath /y | Out-Null
                GO-AddLog "Registry exported to: $BackupDir" "OK"
            } catch {
                GO-AddLog "Registry backup failed: $_" "WARN"
            }
        }
    }

    # Profile Save/Load
    function Global:GO-SaveProfile {
        $sfd = New-Object Microsoft.Win32.SaveFileDialog
        $sfd.Title = "Save Gaming Optimizer Profile"
        $sfd.Filter = "JSON Profile (*.json)|*.json"
        $sfd.FileName = "GamingProfile_$(Get-Date -Format 'yyyyMMdd').json"
        $sfd.InitialDirectory = $script:GO_profilePath
        if ($sfd.ShowDialog() -ne $true) { return }

        $selected = @()
        foreach ($id in $script:GO_checkboxes.Keys) {
            if ($script:GO_checkboxes[$id].IsChecked -eq $true) { $selected += $id }
        }
        $profile = @{
            Version = "2.0"
            Created = (Get-Date).ToString("o")
            Hardware = @{
                CPU = $script:GO_hw.CPU
                GPU = $script:GO_hw.GPU
                RAMGB = $script:GO_hw.RAMGB
                Build = $script:GO_hw.Build
            }
            SelectedTweakIds = $selected
            Settings = @{
                CreateRestorePoint = $script:GO_cbRestore.IsChecked
                ExportRegistry     = $script:GO_cbRegBkp.IsChecked
                PromptReboot       = $script:GO_cbAutoReb.IsChecked
            }
        }
        try {
            $profile | ConvertTo-Json -Depth 5 | Out-File -FilePath $sfd.FileName -Encoding UTF8
            GO-AddLog "Profile saved: $($sfd.FileName)" "OK"
        } catch { GO-AddLog "Save failed: $_" "FAIL" }
    }

    function Global:GO-LoadProfile {
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Title = "Load Gaming Optimizer Profile"
        $ofd.Filter = "JSON Profile (*.json)|*.json"
        $ofd.InitialDirectory = $script:GO_profilePath
        if ($ofd.ShowDialog() -ne $true) { return }

        try {
            $profile = Get-Content -Path $ofd.FileName -Raw | ConvertFrom-Json
            foreach ($id in $script:GO_checkboxes.Keys) { $script:GO_checkboxes[$id].IsChecked = $false }
            $loaded = 0; $skipped = 0
            foreach ($id in $profile.SelectedTweakIds) {
                if ($script:GO_checkboxes.ContainsKey($id) -and $script:GO_checkboxes[$id].IsEnabled) {
                    $script:GO_checkboxes[$id].IsChecked = $true
                    $loaded++
                } else { $skipped++ }
            }
            if ($profile.Settings) {
                $script:GO_cbRestore.IsChecked = $profile.Settings.CreateRestorePoint
                $script:GO_cbRegBkp.IsChecked  = $profile.Settings.ExportRegistry
                $script:GO_cbAutoReb.IsChecked = $profile.Settings.PromptReboot
            }
            GO-UpdateApplyState
            GO-AddLog "Profile loaded. Applied: $loaded  Skipped (already set or N/A): $skipped" "OK"
            if ($profile.Hardware) {
                GO-AddLog "Profile was created on: $($profile.Hardware.CPU) / $($profile.Hardware.GPU)" "INFO"
            }
        } catch { GO-AddLog "Load failed: $_" "FAIL" }
    }

    # Software Info Window
    function Global:GO-ShowSoftwareInfo {
        [xml]$softXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Recommended Third-Party Tools"
        Width="720" Height="620"
        WindowStartupLocation="CenterOwner"
        Background="#F4F6FB" FontFamily="Segoe UI"
        ResizeMode="CanResize" MinWidth="520" MinHeight="480">
    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="THIRD-PARTY TOOLS" Foreground="#3B5BDB" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,4"/>
        <TextBlock Grid.Row="1" Text="Recommended tools that complement Windows optimizations"
                   Foreground="#1A1F3A" FontSize="18" FontWeight="SemiBold" Margin="0,0,0,14"/>
        <Border Grid.Row="2" Background="#FFFFFF" BorderBrush="#D0D6F0"
                BorderThickness="1.5" CornerRadius="8">
            <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="18,14">
                <StackPanel x:Name="SoftwareStack"/>
            </ScrollViewer>
        </Border>
        <Button Grid.Row="3" x:Name="SoftCloseBtn" Content="Close"
                Style="{DynamicResource SecondaryButton}" Height="38"
                Padding="20,6" HorizontalAlignment="Right" Margin="0,14,0,0"/>
    </Grid>
</Window>
"@
        $r = New-Object System.Xml.XmlNodeReader $softXaml
        $sw = [Windows.Markup.XamlReader]::Load($r)
        $sw.Resources.Add("SecondaryButton", (Get-PowerToolsWindow).FindResource("SecondaryButton"))
        $sw.Owner = Get-PowerToolsWindow

        $stack = $sw.FindName("SoftwareStack")

        $tools = @(
            @{ Name="ISLC - Intelligent Standby List Cleaner"; Rec="Very High";
               What="Clears Windows Standby Memory List. Prevents RAM stutter from cached data.";
               Why="One of the most effective tools overall. Stabilizes frametimes, reduces stutter spikes especially with 16-32GB RAM.";
               URL="https://www.wagnardsoft.com/"; Cost="Free" }
            @{ Name="Process Lasso"; Rec="High (Intel 12+ / AMD X3D)";
               What="CPU prioritization and core affinity per process. Automatic and persistent.";
               Why="Moves background processes to E-cores (Intel) or second CCD (AMD), reserves P-cores for game. Free version sufficient.";
               URL="https://bitsum.com/"; Cost="Free / Pro available" }
            @{ Name="NVCleanstall"; Rec="High (NVIDIA users)";
               What="Installs NVIDIA drivers without bloatware (GeForce Experience, telemetry, NVIDIA Container).";
               Why="Fewer background processes, less RAM usage, cleaner driver stack. Use on every driver update.";
               URL="https://www.techpowerup.com/nvcleanstall/"; Cost="Free" }
            @{ Name="TimerResolution / TimerTool"; Rec="High (Competitive)";
               What="Increases Windows timer resolution from default 15.6ms to 0.5ms.";
               Why="More precise process scheduling, more stable frametimes especially in competitive shooters (CS2, Valorant, Apex).";
               URL="https://www.lucashale.com/timer-resolution/"; Cost="Free" }
            @{ Name="DDU - Display Driver Uninstaller"; Rec="High";
               What="Complete driver removal without residue. Use before every driver update.";
               Why="Prevents driver conflicts, stuttering from old driver remnants, micro-crashes. Run in Safe Mode.";
               URL="https://www.wagnardsoft.com/"; Cost="Free" }
            @{ Name="MSI Afterburner + RTSS"; Rec="High (Competitive)";
               What="GPU monitoring and FPS limiter.";
               Why="FPS limit to refresh rate -3 FPS reduces input lag significantly (144Hz -> limit 141 FPS). More stable than in-game VSync.";
               URL="https://www.msi.com/Landing/afterburner/"; Cost="Free" }
            @{ Name="O&O ShutUp10++"; Rec="Medium";
               What="GUI tool for telemetry, privacy, and background processes - without registry knowledge.";
               Why="Quick disabling of 50+ tracking/telemetry functions. Good for users without registry experience.";
               URL="https://www.oo-software.com/en/shutup10"; Cost="Free" }
            @{ Name="InSpectre (Gibson Research)"; Rec="Medium";
               What="Shows status of all CPU security mitigations (Spectre, Meltdown, Downfall).";
               Why="Visual control whether mitigations are active. Enables one-click deactivation if needed.";
               URL="https://www.grc.com/inspectre.htm"; Cost="Free" }
        )

        foreach ($tool in $tools) {
            $card = New-Object System.Windows.Controls.Border
            $card.Background = Get-PowerToolsBrush "LogBg"
            $card.BorderBrush = Get-PowerToolsBrush "LogBorder"
            $card.BorderThickness = 1
            $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
            $card.Padding = "14,10"
            $card.Margin = "0,0,0,10"

            $cardStack = New-Object System.Windows.Controls.StackPanel

            $title = New-Object System.Windows.Controls.TextBlock
            $title.Text = $tool.Name
            $title.FontSize = 14
            $title.FontWeight = "SemiBold"
            $title.Foreground = Get-PowerToolsBrush "TextDark"
            $title.Margin = "0,0,0,6"
            $cardStack.Children.Add($title) | Out-Null

            $meta = New-Object System.Windows.Controls.TextBlock
            $meta.Text = "Recommended: $($tool.Rec)  |  Cost: $($tool.Cost)"
            $meta.FontSize = 10
            $meta.FontWeight = "Bold"
            $meta.Foreground = Get-PowerToolsBrush "Primary"
            $meta.Margin = "0,0,0,8"
            $cardStack.Children.Add($meta) | Out-Null

            $whatLbl = New-Object System.Windows.Controls.TextBlock
            $whatLbl.Text = "WHAT IT DOES"
            $whatLbl.FontSize = 9
            $whatLbl.FontWeight = "Bold"
            $whatLbl.Foreground = Get-PowerToolsBrush "TextMuted"
            $whatLbl.Margin = "0,0,0,2"
            $cardStack.Children.Add($whatLbl) | Out-Null

            $whatTxt = New-Object System.Windows.Controls.TextBlock
            $whatTxt.Text = $tool.What
            $whatTxt.FontSize = 12
            $whatTxt.TextWrapping = "Wrap"
            $whatTxt.Foreground = Get-PowerToolsBrush "TextDark"
            $whatTxt.Margin = "0,0,0,8"
            $cardStack.Children.Add($whatTxt) | Out-Null

            $whyLbl = New-Object System.Windows.Controls.TextBlock
            $whyLbl.Text = "WHY USE IT"
            $whyLbl.FontSize = 9
            $whyLbl.FontWeight = "Bold"
            $whyLbl.Foreground = Get-PowerToolsBrush "TextMuted"
            $whyLbl.Margin = "0,0,0,2"
            $cardStack.Children.Add($whyLbl) | Out-Null

            $whyTxt = New-Object System.Windows.Controls.TextBlock
            $whyTxt.Text = $tool.Why
            $whyTxt.FontSize = 12
            $whyTxt.TextWrapping = "Wrap"
            $whyTxt.Foreground = Get-PowerToolsBrush "TextDark"
            $whyTxt.Margin = "0,0,0,8"
            $cardStack.Children.Add($whyTxt) | Out-Null

            $urlTxt = New-Object System.Windows.Controls.TextBlock
            $urlTxt.Text = $tool.URL
            $urlTxt.FontSize = 11
            $urlTxt.FontFamily = "Cascadia Code, Consolas"
            $urlTxt.Foreground = Get-PowerToolsBrush "Primary"
            $urlTxt.Cursor = [System.Windows.Input.Cursors]::Hand
            $urlTxt.TextDecorations = [System.Windows.TextDecorations]::Underline
            $capturedUrl = $tool.URL
            $urlTxt.Add_MouseLeftButtonUp({ Start-Process $capturedUrl }.GetNewClosure())
            $cardStack.Children.Add($urlTxt) | Out-Null

            $card.Child = $cardStack
            $stack.Children.Add($card) | Out-Null
        }

        $sw.FindName("SoftCloseBtn").Add_Click({ $sw.Close() })
        $sw.Show()
    }

    # Revert functionality
    function Global:GO-RevertAll {
        $res = [System.Windows.MessageBox]::Show(
            "Revert all tweaks to Windows default values?`n`nThis will reset ALL managed settings (applied or not) to Windows defaults.`n`nContinue?",
            "Confirm Revert",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

        GO-AddLog "Reverting all tweaks to Windows defaults..." "INFO"
        $ok = 0; $fail = 0; $reboot = $false
        foreach ($t in $script:GO_tweaks) {
            try {
                & $t.Revert
                GO-AddLog "Reverted: $($t.Label)" "OK"
                $ok++
                if ($t.NeedsReboot) { $reboot = $true }
            } catch {
                GO-AddLog "Revert failed: $($t.Label) - $_" "FAIL"
                $fail++
            }
        }
        GO-AddLog "Revert complete. Success: $ok  Failed: $fail" "INFO"
        if ($reboot -and $script:GO_cbAutoReb.IsChecked) {
            $r = [System.Windows.MessageBox]::Show(
                "Some reverted settings require a reboot. Restart now?",
                "Reboot Required",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question)
            if ($r -eq [System.Windows.MessageBoxResult]::Yes) {
                Start-Sleep -Seconds 3
                Restart-Computer -Force
            }
        }
        GO-RenderList
    }

    # Render on load
    GO-RenderList
    GO-ApplyRecommendedPreselection
    GO-AddLog "Status check complete. Pre-selection applied based on detected hardware - please verify before applying." "INFO"

    # Event handlers
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

    $script:GO_selSafe.Add_Click({
        foreach ($id in $script:GO_checkboxes.Keys) {
            $tweak = $script:GO_tweaks | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($script:GO_checkboxes[$id].IsEnabled -and $tweak.Risk -eq 0) {
                $script:GO_checkboxes[$id].IsChecked = $true
            } else {
                $script:GO_checkboxes[$id].IsChecked = $false
            }
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

    $script:GO_loadProfBtn.Add_Click({ GO-LoadProfile })
    $script:GO_saveProfBtn.Add_Click({ GO-SaveProfile })
    $script:GO_softInfoBtn.Add_Click({ GO-ShowSoftwareInfo })
    $script:GO_revertBtn.Add_Click({ GO-RevertAll })

    $script:GO_applyBtn.Add_Click({
        $selected = $script:GO_tweaks | Where-Object {
            $cb = $script:GO_checkboxes[$_.Id]
            $cb -and $cb.IsChecked -eq $true -and $cb.IsEnabled
        }
        if (-not $selected) { GO-AddLog "Nothing selected." "WARN"; return }

        # High-risk warning
        $highRisk = $selected | Where-Object { $_.Risk -eq 2 }
        if ($highRisk) {
            $names = ($highRisk | ForEach-Object { $_.Label }) -join "`n- "
            $r = [System.Windows.MessageBox]::Show(
                "You selected HIGH RISK tweaks:`n`n- $names`n`nThese can compromise system security. Continue?",
                "High Risk Warning",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning)
            if ($r -ne [System.Windows.MessageBoxResult]::Yes) { GO-AddLog "Cancelled by user." "WARN"; return }
        }

        # Backup
        if ($script:GO_cbRestore.IsChecked -or $script:GO_cbRegBkp.IsChecked) {
            $backupDir = Join-Path $env:USERPROFILE "Desktop\PowerToolsSuite_Backup"
            GO-CreateBackup -BackupDir $backupDir
        }

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

        if ($needsReboot -and $script:GO_cbAutoReb.IsChecked) {
            GO-AddLog "Reboot required for some tweaks." "WARN"
            $res = [System.Windows.MessageBox]::Show(
                "Some settings require a reboot.`n`nRestart now?",
                "Reboot Required",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question)
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
