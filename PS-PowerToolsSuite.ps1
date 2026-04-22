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
# SHARED THEME / BRUSH CACHE
# ===========================================================================
$script:Theme = @{
    Primary   = "#3B5BDB"
    Background= "#F4F6FB"
    Surface   = "#FFFFFF"
    Border    = "#D0D6F0"
    TextDark  = "#1A1F3A"
    TextMid   = "#4A5280"
    TextMuted = "#8890B8"
    TextFaint = "#B0B8D8"
    Success   = "#2A9D5C"
    Danger    = "#C0392B"
    Warning   = "#D9822B"
    LogBg     = "#FAFBFF"
    LogBorder = "#D8DEFA"
    Divider   = "#E0E5F5"
}

function New-Brush {
    param([string]$Hex)
    [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    )
}

$script:Brush = @{}
foreach ($k in $script:Theme.Keys) { $script:Brush[$k] = New-Brush $script:Theme[$k] }

# Expose as Global vars so module-side event handlers resolve them reliably
$Global:PTS_Brush = $script:Brush

# Public accessors for modules (Global scope so module event handlers can find them)
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
    Width="980" Height="720"
    MinWidth="860" MinHeight="640"
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
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Rectangle Grid.Row="0" Fill="#3B5BDB"/>

        <Grid Grid.Row="1" Margin="36,22,36,18">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Button x:Name="BackBtn"
                    Grid.Column="0"
                    Content="Back to Menu"
                    Style="{StaticResource SecondaryButton}"
                    Padding="12,8" FontSize="12"
                    Visibility="Collapsed" Margin="0,0,16,0"/>

            <StackPanel Grid.Column="1">
                <TextBlock x:Name="HeaderEyebrow"
                           Text="POWERTOOLS SUITE"
                           Foreground="#3B5BDB" FontSize="11" FontWeight="Bold"
                           Margin="0,0,0,4"/>
                <TextBlock x:Name="HeaderTitle"
                           Text="Utility Launcher"
                           Foreground="#1A1F3A" FontSize="22" FontWeight="SemiBold"/>
                <TextBlock x:Name="HeaderSubtitle"
                           Text="Select a tool to get started"
                           Foreground="#8890B8" FontSize="13" Margin="0,4,0,0"/>
            </StackPanel>
        </Grid>

        <Border Grid.Row="2" Margin="36,0,36,14">
            <ContentControl x:Name="ContentHost"/>
        </Border>

        <Border Grid.Row="3" Background="#FFFFFF" BorderBrush="#E0E5F5" BorderThickness="0,1,0,0">
            <Grid Margin="36,10,36,10">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0"
                           Text="PowerTools Suite v1.1  |  Running as Administrator"
                           Foreground="#B0B8D8" FontSize="11" VerticalAlignment="Center"/>
                <TextBlock x:Name="FooterStatus"
                           Grid.Column="1"
                           Text="Ready"
                           Foreground="#8890B8" FontSize="11" VerticalAlignment="Center"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader        = New-Object System.Xml.XmlNodeReader $xaml
$script:Window = [Windows.Markup.XamlReader]::Load($reader)
$Global:PTS_Window = $script:Window

$script:UI = @{
    ContentHost    = $script:Window.FindName("ContentHost")
    HeaderEyebrow  = $script:Window.FindName("HeaderEyebrow")
    HeaderTitle    = $script:Window.FindName("HeaderTitle")
    HeaderSubtitle = $script:Window.FindName("HeaderSubtitle")
    BackBtn        = $script:Window.FindName("BackBtn")
    FooterStatus   = $script:Window.FindName("FooterStatus")
}

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
# NAVIGATION
#
# FIX: Show-ModuleView is defined FIRST, then stored as a script-scoped
# variable. Show-MainMenu captures that variable in each button closure
# instead of referencing the function by name. This avoids the
# "cmdlet not recognized" error that occurred when closures were created
# before the function was parsed.
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

# --- Define Show-ModuleView BEFORE Show-MainMenu ---
function Show-ModuleView {
    param([Parameter(Mandatory)]$Module)

    Set-Header -Eyebrow $Module.Category.ToUpper() -Title $Module.Name -Subtitle $Module.Description
    $script:UI.BackBtn.Visibility = "Visible"
    Set-FooterStatus "Module: $($Module.Id)"

    try {
        $view = & $Module.Show
        $script:UI.ContentHost.Content = $view
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Failed to load module:`n`n$_",
            "Module Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        Show-MainMenu
    }
}

# Store function reference AFTER definition
$script:NavShowModuleView = Get-Item -Path "function:Show-ModuleView"

# --- Now define Show-MainMenu which references the stored var ---
function Show-MainMenu {
    Set-Header -Eyebrow "POWERTOOLS SUITE" -Title "Utility Launcher" -Subtitle "Select a tool to get started"
    $script:UI.BackBtn.Visibility = "Collapsed"
    Set-FooterStatus "Ready"

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.VerticalScrollBarVisibility   = "Auto"
    $scroll.HorizontalScrollBarVisibility = "Disabled"
    $scroll.Padding = "0,4,0,4"

    $wrap = New-Object System.Windows.Controls.WrapPanel
    $wrap.Orientation = "Horizontal"

    foreach ($mod in $Global:PTS_Modules) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style  = $script:Window.FindResource("TileButton")
        $btn.Width  = 280
        $btn.Height = 140
        $btn.Margin = "0,0,16,16"
        $btn.HorizontalContentAlignment = "Stretch"
        $btn.VerticalContentAlignment   = "Stretch"

        $stack = New-Object System.Windows.Controls.StackPanel

        $cat = New-Object System.Windows.Controls.TextBlock
        $cat.Text       = $mod.Category.ToUpper()
        $cat.Foreground = $script:Brush["Primary"]
        $cat.FontSize   = 10
        $cat.FontWeight = "Bold"
        $cat.Margin     = "0,0,0,6"
        $stack.Children.Add($cat) | Out-Null

        $tbl = New-Object System.Windows.Controls.TextBlock
        $tbl.Text         = $mod.Name
        $tbl.Foreground   = $script:Brush["TextDark"]
        $tbl.FontSize     = 15
        $tbl.FontWeight   = "SemiBold"
        $tbl.Margin       = "0,0,0,6"
        $tbl.TextWrapping = "Wrap"
        $stack.Children.Add($tbl) | Out-Null

        $dbl = New-Object System.Windows.Controls.TextBlock
        $dbl.Text         = $mod.Description
        $dbl.Foreground   = $script:Brush["TextMuted"]
        $dbl.FontSize     = 12
        $dbl.TextWrapping = "Wrap"
        $dbl.LineHeight   = 17
        $stack.Children.Add($dbl) | Out-Null

        if ($mod.RequiresAdmin) {
            $adm = New-Object System.Windows.Controls.TextBlock
            $adm.Text       = "REQUIRES ADMIN"
            $adm.Foreground = $script:Brush["Warning"]
            $adm.FontSize   = 9
            $adm.FontWeight = "Bold"
            $adm.Margin     = "0,8,0,0"
            $stack.Children.Add($adm) | Out-Null
        }

        $btn.Content = $stack

        # Capture both the module and the navigation function reference.
        # The variable $capturedNav holds the FunctionInfo object so the
        # closure does not depend on the function name being in scope.
        $capturedMod = $mod
        $capturedNav = $script:NavShowModuleView
        $btn.Add_Click({
            & $capturedNav -Module $capturedMod
        }.GetNewClosure())

        $wrap.Children.Add($btn) | Out-Null
    }

    $scroll.Content = $wrap
    $script:UI.ContentHost.Content = $scroll
}

$script:UI.BackBtn.Add_Click({ Show-MainMenu })

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

Show-MainMenu
$script:Window.ShowDialog() | Out-Null