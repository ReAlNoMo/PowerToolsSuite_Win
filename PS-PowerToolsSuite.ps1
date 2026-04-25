#Requires -Version 7.0
<#
.SYNOPSIS
    PowerTools Suite - Unified launcher for system utility modules.
.DESCRIPTION
    Main entry point. Loads modules from .\modules\*.ps1 and hosts them in a
    single WPF shell window. Requires PowerShell 7+ and runs elevated.
.NOTES
    Author  : ReAlNoMo
    Version : 1.2
#>

# ===========================================================================
# POWERSHELL 7 CHECK  (before WPF loads)
# ===========================================================================
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    $msg  = "PowerTools Suite requires PowerShell 7 or higher.`n`n"
    $msg += "Installed: $($PSVersionTable.PSVersion)`n`n"
    $msg += "Download: https://aka.ms/powershell"
    [System.Windows.Forms.MessageBox]::Show(
        $msg, "PowerShell 7 Required",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# ===========================================================================
# ADMIN SELF-ELEVATION
# ===========================================================================
function Test-IsAdmin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $pr.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    $self    = $MyInvocation.MyCommand.Path
    $argList = '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', "`"$self`""
    Start-Process -FilePath "pwsh.exe" -ArgumentList $argList -Verb RunAs
    exit 0
}

# ===========================================================================
# ASSEMBLIES
# ===========================================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$Global:PTS_RootPath    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:PTS_ModulesPath = Join-Path $Global:PTS_RootPath "modules"

# ===========================================================================
# CATEGORY DISPLAY NAME MAP
# ===========================================================================
$Global:PTS_CategoryDisplayNames = @{
    "Diagnostics"    = "Diagnostics"
    "Downloads"      = "Downloader"
    "Performance"    = "Gaming Performance"
    "Security"       = "Security"
    "Windows Tweaks" = "Windows Tools"
}

# Sidebar order: alphabetical by display name
$Global:PTS_CategoryOrder = @(
    "Diagnostics",
    "Downloader",
    "Gaming Performance",
    "Security",
    "Windows Tools"
)

# ===========================================================================
# THEME (all stored as Global to avoid scope issues in event handlers)
# ===========================================================================
$Global:PTS_Theme = @{
    Primary           = "#3B5BDB"
    PrimaryDark       = "#2F4AC2"
    SidebarBg         = "#1A2254"
    SidebarDivider    = "#232D6B"
    SidebarHover      = "#2A3470"
    SidebarActive     = "#3B5BDB"
    SidebarBadgeBg    = "#232D6B"
    SidebarBadgeBgActive = "#2F4AC2"
    SidebarText       = "#A8B4E8"
    SidebarTextActive = "#FFFFFF"
    Background        = "#F4F6FB"
    Surface           = "#FFFFFF"
    Border            = "#D0D6F0"
    TextDark          = "#1A1F3A"
    TextMid           = "#4A5280"
    TextMuted         = "#8890B8"
    TextFaint         = "#B0B8D8"
    Success           = "#2A9D5C"
    Danger            = "#C0392B"
    Warning           = "#D9822B"
    LogBg             = "#FAFBFF"
    LogBorder         = "#D8DEFA"
    Divider           = "#E0E5F5"
}

$Global:PTS_ThemeDark = @{
    Primary           = "#5B7FFF"
    PrimaryDark       = "#4A68E8"
    SidebarBg         = "#0F1429"
    SidebarDivider    = "#1A1F3A"
    SidebarHover      = "#1F2847"
    SidebarActive     = "#5B7FFF"
    SidebarBadgeBg    = "#1A1F3A"
    SidebarBadgeBgActive = "#4A68E8"
    SidebarText       = "#8890B8"
    SidebarTextActive = "#FFFFFF"
    Background        = "#0F1429"
    Surface           = "#1A1F3A"
    Border            = "#2A3050"
    TextDark          = "#E0E6FF"
    TextMid           = "#B0B8D8"
    TextMuted         = "#8890B8"
    TextFaint         = "#6A72A0"
    Success           = "#4AB876"
    Danger            = "#E85555"
    Warning           = "#FFB950"
    LogBg             = "#141A2E"
    LogBorder         = "#2A3050"
    Divider           = "#1F2847"
}

$Global:PTS_DarkModeEnabled = $false

function Global:New-PTSBrush {
    param([string]$Hex)
    [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    )
}

function Global:Apply-PTSTheme {
    param([bool]$DarkMode = $false)
    
    $Global:PTS_DarkModeEnabled = $DarkMode
    $themeSource = if ($DarkMode) { $Global:PTS_ThemeDark } else { $Global:PTS_Theme }
    
    # Rebuild all brushes
    $Global:PTS_Brush = @{}
    foreach ($k in $themeSource.Keys) {
        $Global:PTS_Brush[$k] = New-PTSBrush $themeSource[$k]
    }
    
    # Apply to window
    $Global:PTS_Window.Background = $Global:PTS_Brush["Background"]
    
    # Rebuild UI components with new colors
    if ($Global:PTS_UI) {
        $Global:PTS_UI.SidebarPanel.Background = $Global:PTS_Brush["SidebarBg"]
        $Global:PTS_UI.ContentHost.Background = $Global:PTS_Brush["Background"]
        $Global:PTS_UI.HeaderEyebrow.Foreground = $Global:PTS_Brush["TextMuted"]
        $Global:PTS_UI.HeaderTitle.Foreground = $Global:PTS_Brush["TextDark"]
        $Global:PTS_UI.HeaderSubtitle.Foreground = $Global:PTS_Brush["TextMid"]
        $Global:PTS_UI.HeaderBorder.BorderBrush = $Global:PTS_Brush["Divider"]
        $Global:PTS_UI.FooterBorder.BorderBrush = $Global:PTS_Brush["Divider"]
        $Global:PTS_UI.FooterStatus.Foreground = $Global:PTS_Brush["TextMuted"]
    }
}

# Pre-build all brushes as Global hashtable
$Global:PTS_Brush = @{}
foreach ($k in $Global:PTS_Theme.Keys) {
    $Global:PTS_Brush[$k] = New-PTSBrush $Global:PTS_Theme[$k]
}

# Public accessors for modules
function Global:Get-PowerToolsBrush { param([string]$Name) return $Global:PTS_Brush[$Name] }
function Global:Get-PowerToolsWindow { return $Global:PTS_Window }

# ===========================================================================
# MAIN WINDOW XAML
# ===========================================================================
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="PowerTools Suite"
    Width="1060" Height="792"
    MinWidth="900" MinHeight="600"
    WindowStartupLocation="CenterScreen"
    Background="#F4F6FB"
    FontFamily="Segoe UI">

    <Window.Resources>

        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="#3B5BDB"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#2F4AC2"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#2540A8"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="#C8D0E8"/>
                                <Setter Property="Foreground" Value="#8890B0"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="Foreground" Value="#4A5280"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="BorderBrush" Value="#D0D6F0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#EEF1FC"/>
                                <Setter Property="BorderBrush" Value="#3B5BDB"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <ControlTemplate x:Key="DarkModeToggleTemplate" TargetType="ToggleButton">
            <Grid Background="#FFFFFF" CornerRadius="12" BorderBrush="#D0D6F0" BorderThickness="1.5">
                <Border x:Name="ToggleTrack" Background="#E8EEF8" CornerRadius="12"/>
                <Border x:Name="ToggleThumb" Background="#3B5BDB" CornerRadius="10" Width="20" Height="20" HorizontalAlignment="Left" Margin="2,2,0,2"/>
            </Grid>
            <ControlTemplate.Triggers>
                <Trigger Property="IsChecked" Value="True">
                    <Setter TargetName="ToggleTrack" Property="Background" Value="#1A1F3A"/>
                    <Setter TargetName="ToggleThumb" Property="HorizontalAlignment" Value="Right"/>
                    <Setter TargetName="ToggleThumb" Property="Margin" Value="0,2,2,2"/>
                    <Setter TargetName="ToggleThumb" Property="Background" Value="#5B7FFF"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <Style x:Key="TileButton" TargetType="Button">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#D0D6F0"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="TileBorder"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="12" Padding="22,20">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Top"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="TileBorder" Property="BorderBrush" Value="#3B5BDB"/>
                                <Setter TargetName="TileBorder" Property="Background" Value="#FAFBFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SidebarButton" TargetType="Button">
            <Setter Property="Background" Value="#1A2254"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="SidebarBorder"
                                Background="{TemplateBinding Background}"
                                Height="52">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="4"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Rectangle Grid.Row="0" Fill="#3B5BDB"/>

        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="200"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- LEFT SIDEBAR -->
            <Grid Grid.Column="0" Background="#1A2254">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Border Grid.Row="0" Padding="20,20,20,12">
                    <StackPanel>
                        <TextBlock Foreground="#3B5BDB" FontSize="28" FontWeight="Bold" Margin="0,0,0,0" Letter Spacing="0.08em">PowerTools</TextBlock>
                        <TextBlock Foreground="#FFFFFF" FontSize="28" FontWeight="Bold" Margin="0,0,0,0" Letter Spacing="0.15em">Suite</TextBlock>
                    </StackPanel>
                </Border>

                <Border Grid.Row="1" Height="1" Background="#232D6B"/>

                <StackPanel x:Name="SidebarPanel" Grid.Row="2" Margin="0,8,0,0"/>

                <Border Grid.Row="3" Height="1" Background="#232D6B" Margin="0,8,0,8"/>

                <Grid Grid.Row="4" Margin="12,0,12,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="Light / Dark Mode" Foreground="#A8B4E8" FontSize="11" VerticalAlignment="Center"/>
                    <ToggleButton x:Name="DarkModeToggle" Grid.Column="1" Width="50" Height="24" Background="#FFFFFF" BorderBrush="#D0D6F0" BorderThickness="1.5" Cursor="Hand" Template="{StaticResource DarkModeToggleTemplate}" Margin="8,0,0,0"/>
                </Grid>
            </Grid>

            <!-- RIGHT CONTENT -->
            <Grid Grid.Column="1">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Border Grid.Row="0" Background="#FFFFFF" BorderBrush="#E0E5F5"
                        BorderThickness="0,0,0,1" Padding="28,16,28,14">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <Button x:Name="BackBtn"
                                Grid.Column="0"
                                Content="Back"
                                Style="{StaticResource SecondaryButton}"
                                Padding="12,8" FontSize="12"
                                Visibility="Collapsed" Margin="0,0,16,0"/>

                        <StackPanel Grid.Column="1" VerticalAlignment="Center">
                            <TextBlock x:Name="HeaderEyebrow"
                                       Text="POWERTOOLS SUITE"
                                       Foreground="#3B5BDB" FontSize="10" FontWeight="Bold"
                                       Margin="0,0,0,3"/>
                            <TextBlock x:Name="HeaderTitle"
                                       Text="Select a category"
                                       Foreground="#1A1F3A" FontSize="20" FontWeight="SemiBold"/>
                            <TextBlock x:Name="HeaderSubtitle"
                                       Text="Choose a tool to get started"
                                       Foreground="#8890B8" FontSize="12" Margin="0,3,0,0"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <ScrollViewer Grid.Row="1"
                              x:Name="ContentScroller"
                              VerticalScrollBarVisibility="Auto"
                              HorizontalScrollBarVisibility="Disabled"
                              Background="#F4F6FB">
                    <ContentControl x:Name="ContentHost" Margin="28,24,28,24"/>
                </ScrollViewer>
            </Grid>
        </Grid>

        <!-- Footer -->
        <Border Grid.Row="2" Background="#FFFFFF" BorderBrush="#E0E5F5" BorderThickness="0,1,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="200"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Column="0"
                           Text="v1.2  |  Administrator"
                           Foreground="#A8B4E8" FontSize="11" FontWeight="SemiBold"
                           VerticalAlignment="Center" Margin="20,10,0,10"/>

                <TextBlock Grid.Column="1"
                           Text="PowerTools Suite  |  ReAlNoMo"
                           Foreground="#B0B8D8" FontSize="11"
                           VerticalAlignment="Center" Margin="20,10,0,10"/>

                <TextBlock x:Name="FooterStatus"
                           Grid.Column="2"
                           Text="Ready"
                           Foreground="#8890B8" FontSize="11"
                           VerticalAlignment="Center" Margin="0,10,20,10"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader            = New-Object System.Xml.XmlNodeReader $xaml
$Global:PTS_Window = [Windows.Markup.XamlReader]::Load($reader)

# Cache UI element references in Global hashtable (accessible from event handlers)
$Global:PTS_UI = @{
    ContentHost      = $Global:PTS_Window.FindName("ContentHost")
    ContentScroller  = $Global:PTS_Window.FindName("ContentScroller")
    SidebarPanel     = $Global:PTS_Window.FindName("SidebarPanel")
    HeaderEyebrow    = $Global:PTS_Window.FindName("HeaderEyebrow")
    HeaderTitle      = $Global:PTS_Window.FindName("HeaderTitle")
    HeaderSubtitle   = $Global:PTS_Window.FindName("HeaderSubtitle")
    BackBtn          = $Global:PTS_Window.FindName("BackBtn")
    FooterStatus     = $Global:PTS_Window.FindName("FooterStatus")
    DarkModeToggle   = $Global:PTS_Window.FindName("DarkModeToggle")
    HeaderBorder     = $Global:PTS_Window.FindName("HeaderBorder")
    FooterBorder     = $Global:PTS_Window.FindName("FooterBorder")
}

# Dark mode toggle handler
$Global:PTS_UI.DarkModeToggle.Add_Click({
    $isDark = $Global:PTS_UI.DarkModeToggle.IsChecked
    Apply-PTSTheme -DarkMode $isDark
})

# Track active sidebar button (Global)
$Global:PTS_ActiveSidebarBtn = $null

# ===========================================================================
# MODULE REGISTRY
# ===========================================================================
$Global:PTS_Modules = [System.Collections.ArrayList]::new()

function Global:Register-PowerToolsModule {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][scriptblock]$Show,
        [bool]$RequiresAdmin = $false
    )
    [void]$Global:PTS_Modules.Add([PSCustomObject]@{
        Id            = $Id
        Name          = $Name
        Description   = $Description
        Category      = $Category
        Show          = $Show
        RequiresAdmin = $RequiresAdmin
    })
}

# Load all module files
if (Test-Path $Global:PTS_ModulesPath) {
    Get-ChildItem -Path $Global:PTS_ModulesPath -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
        try   { . $_.FullName }
        catch { Write-Warning "Failed to load module $($_.Name): $_" }
    }
}

# ===========================================================================
# HELPERS (all Global so event handlers can reach them)
# ===========================================================================
function Global:Set-PTSHeader {
    param([string]$Eyebrow, [string]$Title, [string]$Subtitle)
    $Global:PTS_UI.HeaderEyebrow.Text  = $Eyebrow
    $Global:PTS_UI.HeaderTitle.Text    = $Title
    $Global:PTS_UI.HeaderSubtitle.Text = $Subtitle
}

function Global:Set-PTSFooterStatus {
    param([string]$Text)
    $Global:PTS_UI.FooterStatus.Text = $Text
}

# ===========================================================================
# SIDEBAR EVENT HANDLERS
# Use $sender (the button) and read state from Tag - no closures needed
# ===========================================================================
function Global:Invoke-SidebarMouseEnter {
    param($SenderBtn, $EventArgs)
    if ($Global:PTS_ActiveSidebarBtn -ne $SenderBtn) {
        $SenderBtn.Background = $Global:PTS_Brush["SidebarHover"]
    }
}

function Global:Invoke-SidebarMouseLeave {
    param($SenderBtn, $EventArgs)
    if ($Global:PTS_ActiveSidebarBtn -ne $SenderBtn) {
        $SenderBtn.Background = $Global:PTS_Brush["SidebarBg"]
    }
}

function Global:Invoke-SidebarClick {
    param($SenderBtn, $EventArgs)

    # Reset previous active
    if ($Global:PTS_ActiveSidebarBtn -ne $null -and $Global:PTS_ActiveSidebarBtn -ne $SenderBtn) {
        $prevBtn = $Global:PTS_ActiveSidebarBtn
        $prevBtn.Background = $Global:PTS_Brush["SidebarBg"]
        # Reset label + badge stored in Tag
        if ($prevBtn.Tag -ne $null) {
            $prevTag = $prevBtn.Tag
            if ($prevTag.Label) {
                $prevTag.Label.Foreground = $Global:PTS_Brush["SidebarText"]
                $prevTag.Label.FontWeight = "Normal"
            }
            if ($prevTag.Badge) {
                $prevTag.Badge.Background = $Global:PTS_Brush["SidebarBadgeBg"]
            }
            if ($prevTag.CountText) {
                $prevTag.CountText.Foreground = $Global:PTS_Brush["SidebarText"]
            }
        }
    }

    # Set new active
    $Global:PTS_ActiveSidebarBtn = $SenderBtn
    $SenderBtn.Background = $Global:PTS_Brush["SidebarActive"]

    $tag = $SenderBtn.Tag
    if ($tag.Label) {
        $tag.Label.Foreground = $Global:PTS_Brush["SidebarTextActive"]
        $tag.Label.FontWeight = "SemiBold"
    }
    if ($tag.Badge) {
        $tag.Badge.Background = $Global:PTS_Brush["SidebarBadgeBgActive"]
    }
    if ($tag.CountText) {
        $tag.CountText.Foreground = $Global:PTS_Brush["SidebarTextActive"]
    }

    # Show category content
    Show-PTSCategoryView -DisplayName $tag.DisplayName
}

# ===========================================================================
# TILE CLICK HANDLER
# ===========================================================================
function Global:Invoke-TileClick {
    param($SenderBtn, $EventArgs)
    $module = $SenderBtn.Tag
    if ($module) {
        Show-PTSModuleView -Module $module
    }
}

# ===========================================================================
# SIDEBAR BUILDER
# ===========================================================================
function Global:Build-PTSSidebar {
    $Global:PTS_UI.SidebarPanel.Children.Clear()

    # Collect display names present in loaded modules
    $presentDisplayNames = $Global:PTS_Modules | ForEach-Object {
        $raw = $_.Category
        if ($Global:PTS_CategoryDisplayNames.ContainsKey($raw)) {
            $Global:PTS_CategoryDisplayNames[$raw]
        } else { $raw }
    } | Select-Object -Unique

    $orderedCategories = $Global:PTS_CategoryOrder | Where-Object { $presentDisplayNames -contains $_ }

    foreach ($displayName in $orderedCategories) {
        # Find internal key + module count
        $internalKey = $null
        foreach ($entry in $Global:PTS_CategoryDisplayNames.GetEnumerator()) {
            if ($entry.Value -eq $displayName) { $internalKey = $entry.Key; break }
        }
        if (-not $internalKey) { $internalKey = $displayName }

        $modCount = ($Global:PTS_Modules | Where-Object { $_.Category -eq $internalKey }).Count

        # Create button using XAML style
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $Global:PTS_Window.FindResource("SidebarButton")
        $btn.Background = $Global:PTS_Brush["SidebarBg"]

        # Inner row: label (left) + count badge (right)
        $rowPanel = New-Object System.Windows.Controls.Grid
        $rowPanel.Margin = "20,0,16,0"
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = "*"
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = "Auto"
        $rowPanel.ColumnDefinitions.Add($c1)
        $rowPanel.ColumnDefinitions.Add($c2)

        # Label
        $label = New-Object System.Windows.Controls.TextBlock
        $label.Text              = $displayName
        $label.Foreground        = $Global:PTS_Brush["SidebarText"]
        $label.FontSize          = 13
        $label.FontWeight        = "Normal"
        $label.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($label, 0)
        $rowPanel.Children.Add($label) | Out-Null

        # Count badge
        $countBadge = New-Object System.Windows.Controls.Border
        $countBadge.Background    = $Global:PTS_Brush["SidebarBadgeBg"]
        $countBadge.CornerRadius  = New-Object System.Windows.CornerRadius(10)
        $countBadge.Padding       = "7,2,7,2"
        $countBadge.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($countBadge, 1)

        $countText = New-Object System.Windows.Controls.TextBlock
        $countText.Text       = "$modCount"
        $countText.Foreground = $Global:PTS_Brush["SidebarText"]
        $countText.FontSize   = 10
        $countText.FontWeight = "SemiBold"
        $countBadge.Child     = $countText
        $rowPanel.Children.Add($countBadge) | Out-Null

        $btn.Content = $rowPanel

        # Store all relevant refs in Tag (PSCustomObject)
        $btn.Tag = [PSCustomObject]@{
            DisplayName = $displayName
            Label       = $label
            Badge       = $countBadge
            CountText   = $countText
        }

        # Wire up handlers. WPF passes sender as $args[0], event args as $args[1].
        $btn.Add_MouseEnter({
            Invoke-SidebarMouseEnter -SenderBtn $args[0] -EventArgs $args[1]
        })
        $btn.Add_MouseLeave({
            Invoke-SidebarMouseLeave -SenderBtn $args[0] -EventArgs $args[1]
        })
        $btn.Add_Click({
            Invoke-SidebarClick -SenderBtn $args[0] -EventArgs $args[1]
        })

        $Global:PTS_UI.SidebarPanel.Children.Add($btn) | Out-Null

        # Divider line
        $div = New-Object System.Windows.Controls.Border
        $div.Height     = 1
        $div.Background = $Global:PTS_Brush["SidebarDivider"]
        $Global:PTS_UI.SidebarPanel.Children.Add($div) | Out-Null
    }
}

# ===========================================================================
# NAVIGATION
# ===========================================================================
function Global:Show-PTSModuleView {
    param([Parameter(Mandatory)]$Module)

    $displayName = if ($Global:PTS_CategoryDisplayNames.ContainsKey($Module.Category)) {
        $Global:PTS_CategoryDisplayNames[$Module.Category]
    } else { $Module.Category }

    Set-PTSHeader -Eyebrow $displayName.ToUpper() -Title $Module.Name -Subtitle $Module.Description
    $Global:PTS_UI.BackBtn.Visibility = "Visible"
    Set-PTSFooterStatus "Module: $($Module.Id)"

    try {
        $view = & $Module.Show
        $Global:PTS_UI.ContentHost.Content = $view
        $Global:PTS_UI.ContentScroller.ScrollToTop()
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Failed to load module:`n`n$_",
            "Module Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        if ($Global:PTS_ActiveSidebarBtn -ne $null) {
            Show-PTSCategoryView -DisplayName ($Global:PTS_ActiveSidebarBtn.Tag.DisplayName)
        }
    }
}

function Global:Show-PTSCategoryView {
    param([string]$DisplayName)

    # Find internal key
    $internalKey = $null
    foreach ($entry in $Global:PTS_CategoryDisplayNames.GetEnumerator()) {
        if ($entry.Value -eq $DisplayName) { $internalKey = $entry.Key; break }
    }
    if (-not $internalKey) { $internalKey = $DisplayName }

    $modules = $Global:PTS_Modules | Where-Object { $_.Category -eq $internalKey } | Sort-Object Name

    Set-PTSHeader -Eyebrow $DisplayName.ToUpper() `
                  -Title $DisplayName `
                  -Subtitle "$($modules.Count) tool(s) in this category"
    $Global:PTS_UI.BackBtn.Visibility = "Collapsed"
    Set-PTSFooterStatus "Category: $DisplayName"

    $wrap             = New-Object System.Windows.Controls.WrapPanel
    $wrap.Orientation = "Horizontal"

    foreach ($mod in $modules) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style  = $Global:PTS_Window.FindResource("TileButton")
        $btn.Width  = 280
        $btn.Height = 150
        $btn.Margin = "0,0,16,16"
        $btn.HorizontalContentAlignment = "Stretch"
        $btn.VerticalContentAlignment   = "Stretch"
        $btn.Tag    = $mod

        $stack = New-Object System.Windows.Controls.StackPanel

        # Category badge
        $catBadge               = New-Object System.Windows.Controls.Border
        $catBadge.Background    = $Global:PTS_Brush["Primary"]
        $catBadge.CornerRadius  = New-Object System.Windows.CornerRadius(4)
        $catBadge.Padding       = "8,3,8,3"
        $catBadge.Margin        = "0,0,0,8"
        $catBadge.HorizontalAlignment = "Left"

        $badgeText            = New-Object System.Windows.Controls.TextBlock
        $badgeText.Text       = $DisplayName.ToUpper()
        $badgeText.Foreground = $Global:PTS_Brush["Surface"]
        $badgeText.FontSize   = 9
        $badgeText.FontWeight = "Bold"
        $catBadge.Child       = $badgeText
        $stack.Children.Add($catBadge) | Out-Null

        # Module name
        $tbl              = New-Object System.Windows.Controls.TextBlock
        $tbl.Text         = $mod.Name
        $tbl.Foreground   = $Global:PTS_Brush["TextDark"]
        $tbl.FontSize     = 15
        $tbl.FontWeight   = "SemiBold"
        $tbl.Margin       = "0,0,0,6"
        $tbl.TextWrapping = "Wrap"
        $stack.Children.Add($tbl) | Out-Null

        # Description
        $dbl              = New-Object System.Windows.Controls.TextBlock
        $dbl.Text         = $mod.Description
        $dbl.Foreground   = $Global:PTS_Brush["TextMuted"]
        $dbl.FontSize     = 12
        $dbl.TextWrapping = "Wrap"
        $dbl.LineHeight   = 17
        $stack.Children.Add($dbl) | Out-Null

        # Admin badge
        if ($mod.RequiresAdmin) {
            $adm            = New-Object System.Windows.Controls.TextBlock
            $adm.Text       = "REQUIRES ADMIN"
            $adm.Foreground = $Global:PTS_Brush["Warning"]
            $adm.FontSize   = 9
            $adm.FontWeight = "Bold"
            $adm.Margin     = "0,10,0,0"
            $stack.Children.Add($adm) | Out-Null
        }

        $btn.Content = $stack

        # Click handler reads module from sender's Tag - no closure needed
        $btn.Add_Click({
            Invoke-TileClick -SenderBtn $args[0] -EventArgs $args[1]
        })

        $wrap.Children.Add($btn) | Out-Null
    }

    $Global:PTS_UI.ContentHost.Content = $wrap
    $Global:PTS_UI.ContentScroller.ScrollToTop()
}

# Back button = return to active category
$Global:PTS_UI.BackBtn.Add_Click({
    if ($Global:PTS_ActiveSidebarBtn -ne $null) {
        Show-PTSCategoryView -DisplayName ($Global:PTS_ActiveSidebarBtn.Tag.DisplayName)
    }
    $Global:PTS_UI.BackBtn.Visibility = "Collapsed"
})

# ===========================================================================
# LAUNCH
# ===========================================================================
if ($Global:PTS_Modules.Count -eq 0) {
    [System.Windows.MessageBox]::Show(
        "No modules found in:`n$Global:PTS_ModulesPath`n`nEnsure the 'modules' folder exists next to this script.",
        "PowerTools Suite",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}

Build-PTSSidebar

# Auto-select first sidebar entry
$firstBtn = $Global:PTS_UI.SidebarPanel.Children |
    Where-Object { $_ -is [System.Windows.Controls.Button] } |
    Select-Object -First 1

if ($firstBtn) {
    $firstBtn.RaiseEvent(
        [System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)
    )
}

$Global:PTS_Window.ShowDialog() | Out-Null
