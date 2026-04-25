#Requires -Version 7.0
<#
.SYNOPSIS
    PowerTools Suite - Unified launcher for system utility modules.
.DESCRIPTION
    Main entry point. Loads modules from .\modules\*.ps1 and hosts them in a
    single WPF shell window. Requires PowerShell 7+ and runs elevated.
.NOTES
    Author  : ReAlNoMo
    Version : 1.1
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

$script:RootPath    = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ModulesPath = Join-Path $script:RootPath "modules"

# ===========================================================================
# CATEGORY DISPLAY NAME MAP
# Maps internal category strings (from module files) to sidebar display names
# ===========================================================================
$script:CategoryDisplayNames = @{
    "Diagnostics"    = "Diagnostics"
    "Downloads"      = "Downloader"
    "Performance"    = "Gaming Performance"
    "Security"       = "Security"
    "Windows Tweaks" = "Windows Tools"
}

# Sidebar order: alphabetical by display name
$script:CategoryOrder = @(
    "Diagnostics",
    "Downloader",
    "Gaming Performance",
    "Security",
    "Windows Tools"
)

# ===========================================================================
# SHARED THEME / BRUSH CACHE
# ===========================================================================
$script:Theme = @{
    Primary           = "#3B5BDB"
    PrimaryDark       = "#2F4AC2"
    SidebarBg         = "#1A2254"
    SidebarDivider    = "#232D6B"
    SidebarHover      = "#2A3470"
    SidebarActive     = "#3B5BDB"
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

function New-Brush {
    param([string]$Hex)
    [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    )
}

$script:Brush = @{}
foreach ($k in $script:Theme.Keys) { $script:Brush[$k] = New-Brush $script:Theme[$k] }

$Global:PTS_Brush = $script:Brush

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
    Width="1060" Height="720"
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

    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="4"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Top accent bar -->
        <Rectangle Grid.Row="0" Fill="#3B5BDB"/>

        <!-- Main layout: sidebar + content -->
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="200"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- ═══ LEFT SIDEBAR ═══ -->
            <Grid Grid.Column="0" Background="#1A2254">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Sidebar title -->
                <Border Grid.Row="0" Padding="20,20,20,16">
                    <StackPanel>
                        <TextBlock Text="POWERTOOLS"
                                   Foreground="#3B5BDB" FontSize="10" FontWeight="Bold"
                                   Margin="0,0,0,2"/>
                        <TextBlock Text="Suite"
                                   Foreground="#FFFFFF" FontSize="18" FontWeight="SemiBold"/>
                    </StackPanel>
                </Border>

                <!-- Sidebar top divider -->
                <Border Grid.Row="1" Height="1" Background="#232D6B"/>

                <!-- Nav items -->
                <StackPanel x:Name="SidebarPanel" Grid.Row="2" Margin="0,8,0,0"/>
            </Grid>

            <!-- ═══ RIGHT CONTENT ═══ -->
            <Grid Grid.Column="1">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Content header -->
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

                <!-- Scrollable tile area -->
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
                           Text="v1.1  |  Administrator"
                           Foreground="#A8B4E8" FontSize="11" FontWeight="SemiBold"
                           VerticalAlignment="Center" Margin="20,10,0,10"
                           Background="#1A2254"/>

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

$reader        = New-Object System.Xml.XmlNodeReader $xaml
$script:Window = [Windows.Markup.XamlReader]::Load($reader)
$Global:PTS_Window = $script:Window

$script:UI = @{
    ContentHost     = $script:Window.FindName("ContentHost")
    ContentScroller = $script:Window.FindName("ContentScroller")
    SidebarPanel    = $script:Window.FindName("SidebarPanel")
    HeaderEyebrow   = $script:Window.FindName("HeaderEyebrow")
    HeaderTitle     = $script:Window.FindName("HeaderTitle")
    HeaderSubtitle  = $script:Window.FindName("HeaderSubtitle")
    BackBtn         = $script:Window.FindName("BackBtn")
    FooterStatus    = $script:Window.FindName("FooterStatus")
}

# Track active sidebar button
$script:ActiveSidebarBtn      = $null
$script:ActiveSidebarLabel    = $null

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
if (Test-Path $script:ModulesPath) {
    Get-ChildItem -Path $script:ModulesPath -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
        try   { . $_.FullName }
        catch { Write-Warning "Failed to load module $($_.Name): $_" }
    }
}

# ===========================================================================
# HELPERS
# ===========================================================================
function Set-Header {
    param([string]$Eyebrow, [string]$Title, [string]$Subtitle)
    $script:UI.HeaderEyebrow.Text  = $Eyebrow
    $script:UI.HeaderTitle.Text    = $Title
    $script:UI.HeaderSubtitle.Text = $Subtitle
}

function Set-FooterStatus {
    param([string]$Text)
    $script:UI.FooterStatus.Text = $Text
}

function Set-SidebarActive {
    param($Btn, $Label)
    # Reset previous
    if ($script:ActiveSidebarBtn -ne $null) {
        $script:ActiveSidebarBtn.Background   = $Global:PTS_Brush["SidebarBg"]
        $script:ActiveSidebarLabel.Foreground = $Global:PTS_Brush["SidebarText"]
        $script:ActiveSidebarLabel.FontWeight = "Normal"
    }
    # Set new
    $script:ActiveSidebarBtn   = $Btn
    $script:ActiveSidebarLabel = $Label
    $Btn.Background   = $Global:PTS_Brush["SidebarActive"]
    $Label.Foreground = $Global:PTS_Brush["SidebarTextActive"]
    $Label.FontWeight = "SemiBold"
}

# ===========================================================================
# SIDEBAR BUILDER
# ===========================================================================
function Build-Sidebar {
    $script:UI.SidebarPanel.Children.Clear()

    # Collect display names present in loaded modules
    $presentDisplayNames = $Global:PTS_Modules | ForEach-Object {
        $raw = $_.Category
        if ($script:CategoryDisplayNames.ContainsKey($raw)) { $script:CategoryDisplayNames[$raw] }
        else { $raw }
    } | Select-Object -Unique

    $orderedCategories = $script:CategoryOrder | Where-Object { $presentDisplayNames -contains $_ }

    foreach ($displayName in $orderedCategories) {
        # Module count for this category
        $internalKey = $script:CategoryDisplayNames.GetEnumerator() |
            Where-Object { $_.Value -eq $displayName } |
            Select-Object -ExpandProperty Key -First 1
        if (-not $internalKey) { $internalKey = $displayName }
        $modCount = ($Global:PTS_Modules | Where-Object { $_.Category -eq $internalKey }).Count

        # Sidebar button (manual control template for full color control)
        $btn = New-Object System.Windows.Controls.Button
        $btn.Height              = 52
        $btn.BorderThickness     = "0"
        $btn.Background          = $Global:PTS_Brush["SidebarBg"]
        $btn.HorizontalContentAlignment = "Stretch"
        $btn.VerticalContentAlignment   = "Stretch"
        $btn.Cursor              = "Hand"
        $btn.Tag                 = $displayName

        # Button content: label + count badge in a horizontal row
        $rowPanel = New-Object System.Windows.Controls.Grid
        $rowPanel.Margin = "20,0,16,0"
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = "*"
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = "Auto"
        $rowPanel.ColumnDefinitions.Add($c1)
        $rowPanel.ColumnDefinitions.Add($c2)

        $label = New-Object System.Windows.Controls.TextBlock
        $label.Text              = $displayName
        $label.Foreground        = $Global:PTS_Brush["SidebarText"]
        $label.FontSize          = 13
        $label.FontWeight        = "Normal"
        $label.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($label, 0)
        $rowPanel.Children.Add($label) | Out-Null

        $countBadge = New-Object System.Windows.Controls.Border
        $countBadge.Background   = New-Brush "#232D6B"
        $countBadge.CornerRadius = New-Object System.Windows.CornerRadius(10,10,10,10)
        $countBadge.Padding      = "7,2,7,2"
        $countBadge.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($countBadge, 1)

        $countText = New-Object System.Windows.Controls.TextBlock
        $countText.Text      = "$modCount"
        $countText.Foreground = $Global:PTS_Brush["SidebarText"]
        $countText.FontSize  = 10
        $countText.FontWeight = "SemiBold"
        $countBadge.Child    = $countText
        $rowPanel.Children.Add($countBadge) | Out-Null

        # Wrap content in a border that fills the button area
        $outerBorder = New-Object System.Windows.Controls.Border
        $outerBorder.Height = 52
        $outerBorder.Child  = $rowPanel
        $btn.Content        = $outerBorder

        # Apply inline XAML template so Background binding works correctly
        $templateXml = [xml]@"
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                 TargetType="Button">
    <Border Background="{TemplateBinding Background}" Height="52">
        <ContentPresenter VerticalAlignment="Center"/>
    </Border>
</ControlTemplate>
"@
        $templateReader = New-Object System.Xml.XmlNodeReader $templateXml
        $btn.Template = [Windows.Markup.XamlReader]::Load($templateReader)

        # Capture brush values before closure — $script:Brush null in event scope
        $capturedBtn        = $btn
        $capturedLabel      = $label
        $capturedCount      = $countText
        $capturedBadge      = $countBadge
        $capturedName       = $displayName
        $brushHover         = $Global:PTS_Brush["SidebarHover"]
        $brushBg            = $Global:PTS_Brush["SidebarBg"]
        $brushActiveText    = $Global:PTS_Brush["SidebarTextActive"]
        $brushActiveBadge   = New-Brush "#2F4AC2"

        $btn.Add_MouseEnter({
            if ($script:ActiveSidebarBtn -ne $capturedBtn) {
                $capturedBtn.Background = $brushHover
            }
        }.GetNewClosure())

        $btn.Add_MouseLeave({
            if ($script:ActiveSidebarBtn -ne $capturedBtn) {
                $capturedBtn.Background = $brushBg
            }
        }.GetNewClosure())

        $btn.Add_Click({
            Set-SidebarActive -Btn $capturedBtn -Label $capturedLabel
            $capturedBadge.Background = $brushActiveBadge
            $capturedCount.Foreground = $brushActiveText
            Show-CategoryView -DisplayName $capturedName
        }.GetNewClosure())

        $script:UI.SidebarPanel.Children.Add($btn) | Out-Null

        # Divider between items
        $div            = New-Object System.Windows.Controls.Border
        $div.Height     = 1
        $div.Background = $Global:PTS_Brush["SidebarDivider"]
        $script:UI.SidebarPanel.Children.Add($div) | Out-Null
    }
}

# ===========================================================================
# NAVIGATION
# ===========================================================================
function Show-ModuleView {
    param([Parameter(Mandatory)]$Module)

    $displayName = if ($script:CategoryDisplayNames.ContainsKey($Module.Category)) {
        $script:CategoryDisplayNames[$Module.Category]
    } else { $Module.Category }

    Set-Header -Eyebrow $displayName.ToUpper() -Title $Module.Name -Subtitle $Module.Description
    $script:UI.BackBtn.Visibility = "Visible"
    Set-FooterStatus "Module: $($Module.Id)"

    try {
        $view = & $Module.Show
        $script:UI.ContentHost.Content = $view
        $script:UI.ContentScroller.ScrollToTop()
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Failed to load module:`n`n$_",
            "Module Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        if ($script:ActiveSidebarBtn -ne $null) {
            Show-CategoryView -DisplayName ($script:ActiveSidebarBtn.Tag)
        }
    }
}

$script:NavShowModuleView = Get-Item -Path "function:Show-ModuleView"

function Show-CategoryView {
    param([string]$DisplayName)

    $internalKey = $script:CategoryDisplayNames.GetEnumerator() |
        Where-Object { $_.Value -eq $DisplayName } |
        Select-Object -ExpandProperty Key -First 1
    if (-not $internalKey) { $internalKey = $DisplayName }

    $modules = $Global:PTS_Modules | Where-Object { $_.Category -eq $internalKey } | Sort-Object Name

    Set-Header -Eyebrow $DisplayName.ToUpper() `
               -Title $DisplayName `
               -Subtitle "$($modules.Count) tool(s) in this category"
    $script:UI.BackBtn.Visibility = "Collapsed"
    Set-FooterStatus "Category: $DisplayName"

    $wrap             = New-Object System.Windows.Controls.WrapPanel
    $wrap.Orientation = "Horizontal"

    foreach ($mod in $modules) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style  = $script:Window.FindResource("TileButton")
        $btn.Width  = 280
        $btn.Height = 150
        $btn.Margin = "0,0,16,16"
        $btn.HorizontalContentAlignment = "Stretch"
        $btn.VerticalContentAlignment   = "Stretch"

        $stack = New-Object System.Windows.Controls.StackPanel

        # Category badge
        $catBadge               = New-Object System.Windows.Controls.Border
        $catBadge.Background    = $Global:PTS_Brush["Primary"]
        $catBadge.CornerRadius  = New-Object System.Windows.CornerRadius(4,4,4,4)
        $catBadge.Padding       = "8,3,8,3"
        $catBadge.Margin        = "0,0,0,8"
        $catBadge.HorizontalAlignment = "Left"

        $badgeText          = New-Object System.Windows.Controls.TextBlock
        $badgeText.Text     = $DisplayName.ToUpper()
        $badgeText.Foreground = $Global:PTS_Brush["Surface"]
        $badgeText.FontSize = 9
        $badgeText.FontWeight = "Bold"
        $catBadge.Child     = $badgeText
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

        $capturedMod = $mod
        $capturedNav = $script:NavShowModuleView
        $btn.Add_Click({
            & $capturedNav -Module $capturedMod
        }.GetNewClosure())

        $wrap.Children.Add($btn) | Out-Null
    }

    $script:UI.ContentHost.Content = $wrap
    $script:UI.ContentScroller.ScrollToTop()
}

# Back = return to active category view
$script:UI.BackBtn.Add_Click({
    if ($script:ActiveSidebarBtn -ne $null) {
        Show-CategoryView -DisplayName ($script:ActiveSidebarBtn.Tag)
    }
    $script:UI.BackBtn.Visibility = "Collapsed"
})

# ===========================================================================
# LAUNCH
# ===========================================================================
if ($Global:PTS_Modules.Count -eq 0) {
    [System.Windows.MessageBox]::Show(
        "No modules found in:`n$script:ModulesPath`n`nEnsure the 'modules' folder exists next to this script.",
        "PowerTools Suite",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}

Build-Sidebar

# Auto-select first sidebar category on launch
$firstBtn = $script:UI.SidebarPanel.Children |
    Where-Object { $_ -is [System.Windows.Controls.Button] } |
    Select-Object -First 1

if ($firstBtn) {
    $firstBtn.RaiseEvent(
        [System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)
    )
}

$script:Window.ShowDialog() | Out-Null
