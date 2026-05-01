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
# POWERSHELL 7 CHECK
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
$Global:PTS_LogRootPath = Join-Path $Global:PTS_RootPath "logs"
$Global:PTS_LogSessionId = [guid]::NewGuid().ToString()
$Global:PTS_ErrorLogPath = Join-Path $Global:PTS_LogRootPath ("errors-{0}.jsonl" -f (Get-Date -Format "yyyy-MM-dd"))
$Global:PTS_LogLock = New-Object object

function Global:Initialize-PowerToolsLogging {
    try {
        if (-not (Test-Path -LiteralPath $Global:PTS_LogRootPath)) {
            New-Item -ItemType Directory -Path $Global:PTS_LogRootPath -Force | Out-Null
        }
    } catch {
        Write-Warning "Could not create log directory at '$($Global:PTS_LogRootPath)': $($_.Exception.Message)"
    }
}

function Global:Get-PowerToolsErrorLogPath {
    return $Global:PTS_ErrorLogPath
}

function Global:Write-PTSExceptionReport {
    param(
        [Parameter(Mandatory)][string]$Context,
        [string]$ModuleId,
        [string]$ModuleName,
        [string]$ModuleFile,
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [System.Exception]$Exception,
        [hashtable]$Extra = @{}
    )

    try {
        Initialize-PowerToolsLogging

        $ex = if ($Exception) { $Exception } elseif ($ErrorRecord) { $ErrorRecord.Exception } else { $null }
        $inv = if ($ErrorRecord) { $ErrorRecord.InvocationInfo } else { $null }

        $entry = [ordered]@{
            timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
            session_id    = $Global:PTS_LogSessionId
            context       = $Context
            module        = [ordered]@{
                id   = $ModuleId
                name = $ModuleName
                file = $ModuleFile
            }
            host = [ordered]@{
                machine_name = $env:COMPUTERNAME
                user_name    = $env:USERNAME
                os           = [System.Environment]::OSVersion.VersionString
                ps_version   = $PSVersionTable.PSVersion.ToString()
                process_id   = $PID
                is_admin     = (Test-IsAdmin)
            }
            exception = if ($ex) {
                [ordered]@{
                    type                  = $ex.GetType().FullName
                    message               = $ex.Message
                    hresult               = $ex.HResult
                    source                = $ex.Source
                    stack_trace           = $ex.StackTrace
                    inner_exception_type  = if ($ex.InnerException) { $ex.InnerException.GetType().FullName } else { $null }
                    inner_exception_msg   = if ($ex.InnerException) { $ex.InnerException.Message } else { $null }
                }
            } else { $null }
            error_record = if ($ErrorRecord) {
                [ordered]@{
                    message                = $ErrorRecord.ToString()
                    category               = $ErrorRecord.CategoryInfo.Category.ToString()
                    category_reason        = $ErrorRecord.CategoryInfo.Reason
                    category_target_name   = $ErrorRecord.CategoryInfo.TargetName
                    category_target_type   = $ErrorRecord.CategoryInfo.TargetType
                    fully_qualified_id     = $ErrorRecord.FullyQualifiedErrorId
                    script_stack_trace     = $ErrorRecord.ScriptStackTrace
                    position_message       = $ErrorRecord.InvocationInfo.PositionMessage
                    command_name           = $ErrorRecord.InvocationInfo.MyCommand?.Name
                    script_name            = $ErrorRecord.InvocationInfo.ScriptName
                    script_line_number     = $ErrorRecord.InvocationInfo.ScriptLineNumber
                    offset_in_line         = $ErrorRecord.InvocationInfo.OffsetInLine
                    line                   = $ErrorRecord.InvocationInfo.Line
                }
            } else { $null }
            extra = $Extra
        }

        $line = ($entry | ConvertTo-Json -Depth 8 -Compress)
        [System.Threading.Monitor]::Enter($Global:PTS_LogLock)
        try {
            [System.IO.File]::AppendAllText(
                $Global:PTS_ErrorLogPath,
                $line + [Environment]::NewLine,
                [System.Text.UTF8Encoding]::new($false)
            )
        } finally {
            if ([System.Threading.Monitor]::IsEntered($Global:PTS_LogLock)) {
                [System.Threading.Monitor]::Exit($Global:PTS_LogLock)
            }
        }
    } catch {
        Write-Warning "Failed to write error report: $($_.Exception.Message)"
    }
}

Initialize-PowerToolsLogging

# ===========================================================================
# CATEGORY MAP
# ===========================================================================
$Global:PTS_CategoryDisplayNames = @{
    "Diagnostics"    = "Diagnostics"
    "Downloads"      = "Downloader"
    "Performance"    = "Gaming Performance"
    "Security"       = "Security"
    "Windows Tweaks" = "Windows Tools"
}

$Global:PTS_CategoryOrder = @(
    "Diagnostics", "Downloader", "Gaming Performance", "Security", "Windows Tools"
)

# ===========================================================================
# THEMES
# ===========================================================================
$Global:PTS_Theme = @{
    Primary              = "#3B5BDB"
    PrimaryDark          = "#2F4AC2"
    PrimaryHover         = "#2540A8"
    SidebarBg            = "#101D51"
    SidebarDivider       = "#232D6B"
    SidebarHover         = "#2A3470"
    SidebarActive        = "#3B5BDB"
    SidebarBadgeBg       = "#232D6B"
    SidebarBadgeBgActive = "#2F4AC2"
    SidebarText          = "#A8B4E8"
    SidebarTextActive    = "#FFFFFF"
    Background           = "#F4F6FB"
    Surface              = "#FFFFFF"
    Border               = "#D0D6F0"
    TextDark             = "#1A1F3A"
    TextMid              = "#4A5280"
    TextMuted            = "#8890B8"
    TextFaint            = "#B0B8D8"
    Success              = "#2A9D5C"
    Danger               = "#C0392B"
    Warning              = "#D9822B"
    LogBg                = "#FAFBFF"
    LogBorder            = "#D8DEFA"
    Divider              = "#E0E5F5"
    BtnSecBg             = "#FFFFFF"
    BtnSecFg             = "#4A5280"
    BtnSecBorder         = "#D0D6F0"
    BtnSecHover          = "#EEF1FC"
    BtnSecHoverBorder    = "#3B5BDB"
    TileBg               = "#FFFFFF"
    TileBorder           = "#D0D6F0"
    TileHoverBg          = "#FAFBFF"
    TileHoverBorder      = "#3B5BDB"
    InputBg              = "#FFFFFF"
    InputFg              = "#1A1F3A"
    InputBorder          = "#D0D6F0"
    BtnDisabledBg        = "#C8D0E8"
    BtnDisabledFg        = "#8890B0"
}

$Global:PTS_ThemeDark = @{
    Primary              = "#5B7FFF"
    PrimaryDark          = "#4A68E8"
    PrimaryHover         = "#3A57D0"
    SidebarBg            = "#0F1429"
    SidebarDivider       = "#1A1F3A"
    SidebarHover         = "#1F2847"
    SidebarActive        = "#5B7FFF"
    SidebarBadgeBg       = "#1A1F3A"
    SidebarBadgeBgActive = "#4A68E8"
    SidebarText          = "#8890B8"
    SidebarTextActive    = "#FFFFFF"
    Background           = "#0F1429"
    Surface              = "#1A2254"
    Border               = "#2A3580"
    TextDark             = "#E0E6FF"
    TextMid              = "#B0B8E8"
    TextMuted             = "#7880A8"
    TextFaint            = "#505880"
    Success              = "#4AB876"
    Danger               = "#E85555"
    Warning              = "#FFB950"
    LogBg                = "#141A2E"
    LogBorder            = "#2A3580"
    Divider              = "#1F2847"
    BtnSecBg             = "#1E2A5E"
    BtnSecFg             = "#B0B8E8"
    BtnSecBorder         = "#2A3580"
    BtnSecHover          = "#263070"
    BtnSecHoverBorder    = "#5B7FFF"
    TileBg               = "#1A2254"
    TileBorder           = "#2A3580"
    TileHoverBg          = "#1E2A6A"
    TileHoverBorder      = "#5B7FFF"
    InputBg              = "#1E2545"
    InputFg              = "#C8D0F0"
    InputBorder          = "#2A3580"
    BtnDisabledBg        = "#1A2040"
    BtnDisabledFg        = "#505878"
}

$Global:PTS_DarkModeEnabled = $false

function Global:New-PTSBrush {
    param([string]$Hex)
    [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    )
}

$Global:PTS_Brush = @{}
foreach ($k in $Global:PTS_Theme.Keys) {
    $Global:PTS_Brush[$k] = New-PTSBrush $Global:PTS_Theme[$k]
}

function Global:Get-PowerToolsBrush { param([string]$Name) return $Global:PTS_Brush[$Name] }
function Global:Get-PowerToolsWindow { return $Global:PTS_Window }

function Global:Apply-PTSTheme {
    param([bool]$DarkMode = $false)
    $Global:PTS_DarkModeEnabled = $DarkMode
    $src = if ($DarkMode) { $Global:PTS_ThemeDark } else { $Global:PTS_Theme }
    $Global:PTS_Brush = @{}
    foreach ($k in $src.Keys) { $Global:PTS_Brush[$k] = New-PTSBrush $src[$k] }

    $Global:PTS_Window.Background = $Global:PTS_Brush["Background"]

    if ($Global:PTS_UI) {
        $Global:PTS_UI.SidebarGrid.Background     = $Global:PTS_Brush["SidebarBg"]
        $Global:PTS_UI.ContentScroller.Background = $Global:PTS_Brush["Background"]
        $Global:PTS_UI.HeaderEyebrow.Foreground   = $Global:PTS_Brush["Primary"]
        $Global:PTS_UI.HeaderTitle.Foreground     = $Global:PTS_Brush["TextDark"]
        $Global:PTS_UI.HeaderSubtitle.Foreground  = $Global:PTS_Brush["TextMuted"]
        $Global:PTS_UI.HeaderBorder.Background    = $Global:PTS_Brush["Surface"]
        $Global:PTS_UI.HeaderBorder.BorderBrush   = $Global:PTS_Brush["Divider"]
        $Global:PTS_UI.FooterBorder.Background    = $Global:PTS_Brush["Surface"]
        $Global:PTS_UI.FooterBorder.BorderBrush   = $Global:PTS_Brush["Divider"]
        $Global:PTS_UI.FooterStatus.Foreground    = $Global:PTS_Brush["TextMuted"]
        $Global:PTS_UI.FooterLeft.Foreground      = $Global:PTS_Brush["SidebarText"]
        $Global:PTS_UI.FooterMid.Foreground       = $Global:PTS_Brush["TextFaint"]
        $Global:PTS_UI.SidebarDivTop.Background   = $Global:PTS_Brush["SidebarDivider"]
        $Global:PTS_UI.SidebarDivBot.Background   = $Global:PTS_Brush["SidebarDivider"]
        $Global:PTS_UI.DarkModeLabel.Foreground   = $Global:PTS_Brush["SidebarText"]
        $Global:PTS_UI.LogoBorder.Background      = $Global:PTS_Brush["SidebarBg"]

        Update-PTSStyles
        Build-PTSSidebar

        if ($Global:PTS_ActiveSidebarBtn -ne $null) {
            Show-PTSCategoryView -DisplayName ($Global:PTS_ActiveSidebarBtn.Tag.DisplayName)
        }
    }
}
 
function Global:Update-PTSStyles {
    $pbStyle = $Global:PTS_Window.FindResource("PrimaryButton")
    if ($pbStyle) { $pbStyle.IsSealed | Out-Null }
    $Global:PTS_Window.Resources["DynPrimary"]           = $Global:PTS_Brush["Primary"]
    $Global:PTS_Window.Resources["DynPrimaryHover"]      = $Global:PTS_Brush["PrimaryHover"]
    $Global:PTS_Window.Resources["DynBtnSecBg"]          = $Global:PTS_Brush["BtnSecBg"]
    $Global:PTS_Window.Resources["DynBtnSecFg"]          = $Global:PTS_Brush["BtnSecFg"]
    $Global:PTS_Window.Resources["DynBtnSecBorder"]      = $Global:PTS_Brush["BtnSecBorder"]
    $Global:PTS_Window.Resources["DynBtnSecHover"]       = $Global:PTS_Brush["BtnSecHover"]
    $Global:PTS_Window.Resources["DynBtnSecHoverBorder"] = $Global:PTS_Brush["BtnSecHoverBorder"]
    $Global:PTS_Window.Resources["DynTileBg"]            = $Global:PTS_Brush["TileBg"]
    $Global:PTS_Window.Resources["DynTileBorder"]        = $Global:PTS_Brush["TileBorder"]
    $Global:PTS_Window.Resources["DynTileHoverBg"]       = $Global:PTS_Brush["TileHoverBg"]
    $Global:PTS_Window.Resources["DynTileHoverBorder"]   = $Global:PTS_Brush["TileHoverBorder"]
    $Global:PTS_Window.Resources["DynBtnDisabledBg"]     = $Global:PTS_Brush["BtnDisabledBg"]
    $Global:PTS_Window.Resources["DynBtnDisabledFg"]     = $Global:PTS_Brush["BtnDisabledFg"]
}

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
    WindowState="Maximized"
    WindowStartupLocation="CenterScreen"
    Background="#F4F6FB"
    FontFamily="Segoe UI">

    <Window.Resources>

        <SolidColorBrush x:Key="DynPrimary"            Color="#3B5BDB"/>
        <SolidColorBrush x:Key="DynPrimaryHover"       Color="#2540A8"/>
        <SolidColorBrush x:Key="DynBtnSecBg"           Color="#FFFFFF"/>
        <SolidColorBrush x:Key="DynBtnSecFg"           Color="#4A5280"/>
        <SolidColorBrush x:Key="DynBtnSecBorder"       Color="#D0D6F0"/>
        <SolidColorBrush x:Key="DynBtnSecHover"        Color="#EEF1FC"/>
        <SolidColorBrush x:Key="DynBtnSecHoverBorder"  Color="#3B5BDB"/>
        <SolidColorBrush x:Key="DynTileBg"             Color="#FFFFFF"/>
        <SolidColorBrush x:Key="DynTileBorder"         Color="#D0D6F0"/>
        <SolidColorBrush x:Key="DynTileHoverBg"        Color="#FAFBFF"/>
        <SolidColorBrush x:Key="DynTileHoverBorder"    Color="#3B5BDB"/>
        <SolidColorBrush x:Key="DynBtnDisabledBg"      Color="#C8D0E8"/>
        <SolidColorBrush x:Key="DynBtnDisabledFg"      Color="#8890B0"/>

        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background"     Value="{DynamicResource DynPrimary}"/>
            <Setter Property="Foreground"     Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding"        Value="16,10"/>
            <Setter Property="FontSize"       Value="13"/>
            <Setter Property="FontWeight"     Value="SemiBold"/>
            <Setter Property="Cursor"         Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="{DynamicResource DynPrimaryHover}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#1E3290"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="{DynamicResource DynBtnDisabledBg}"/>
                                <Setter Property="Foreground" Value="{DynamicResource DynBtnDisabledFg}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background"      Value="{DynamicResource DynBtnSecBg}"/>
            <Setter Property="Foreground"      Value="{DynamicResource DynBtnSecFg}"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="BorderBrush"     Value="{DynamicResource DynBtnSecBorder}"/>
            <Setter Property="Padding"         Value="16,10"/>
            <Setter Property="FontSize"        Value="13"/>
            <Setter Property="Cursor"          Value="Hand"/>
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
                                <Setter Property="Background"  Value="{DynamicResource DynBtnSecHover}"/>
                                <Setter Property="BorderBrush" Value="{DynamicResource DynBtnSecHoverBorder}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background"  Value="{DynamicResource DynBtnDisabledBg}"/>
                                <Setter Property="Foreground"  Value="{DynamicResource DynBtnDisabledFg}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <ControlTemplate x:Key="DarkModeToggleTemplate" TargetType="ToggleButton">
            <Border x:Name="Track" Background="#E8EEF8" CornerRadius="12" Width="50" Height="24">
                <Border x:Name="Thumb" Background="#3B5BDB" CornerRadius="10"
                        Width="20" Height="20" HorizontalAlignment="Left" Margin="2,0,0,0"/>
            </Border>
            <ControlTemplate.Triggers>
                <Trigger Property="IsChecked" Value="True">
                    <Setter TargetName="Track" Property="Background" Value="#1A1F3A"/>
                    <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
                    <Setter TargetName="Thumb" Property="Margin" Value="0,0,2,0"/>
                    <Setter TargetName="Thumb" Property="Background" Value="#5B7FFF"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <Style x:Key="TileButton" TargetType="Button">
            <Setter Property="Background"      Value="{DynamicResource DynTileBg}"/>
            <Setter Property="BorderBrush"     Value="{DynamicResource DynTileBorder}"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="Cursor"          Value="Hand"/>
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
                                <Setter TargetName="TileBorder" Property="BorderBrush" Value="{DynamicResource DynTileHoverBorder}"/>
                                <Setter TargetName="TileBorder" Property="Background"  Value="{DynamicResource DynTileHoverBg}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SidebarButton" TargetType="Button">
            <Setter Property="Background"             Value="#101D51"/>
            <Setter Property="BorderThickness"        Value="0"/>
            <Setter Property="Cursor"                 Value="Hand"/>
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

        <Grid Grid.Row="1" Grid.IsSharedSizeScope="True">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="260"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- SIDEBAR -->
            <Grid x:Name="SidebarGrid" Grid.Column="0" Grid.Row="0" Grid.RowSpan="4" Background="#101D51">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" SharedSizeGroup="HeaderRow"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- LOGO IMAGE -->
                <Border Grid.Row="0" x:Name="LogoBorder" Padding="12,10,12,10">
                    <Image Source="https://raw.githubusercontent.com/ReAlNoMo/PowerToolsSuite_Win/main/logo/PowerToolsSuite_Logo_02_cut.png"
                           Stretch="Uniform"
                           MaxHeight="70"
                           HorizontalAlignment="Stretch"/>
                </Border>

                <Border x:Name="SidebarDivTop" Grid.Row="1" Height="1" Background="#232D6B"/>

                <StackPanel x:Name="SidebarPanel" Grid.Row="2" Margin="0,8,0,0"/>

                <Border x:Name="SidebarDivBot" Grid.Row="3" Height="1" Background="#232D6B" Margin="0,8,0,8"/>

                <!-- DARK MODE TOGGLE -->
                <Grid Grid.Row="4" Margin="12,0,12,14">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock x:Name="DarkModeLabel"
                               Grid.Column="0"
                               Text="Light / Dark Mode"
                               Foreground="#A8B4E8" FontSize="11"
                               VerticalAlignment="Center"/>
                    <ToggleButton x:Name="DarkModeToggle"
                                  Grid.Column="1"
                                  Template="{StaticResource DarkModeToggleTemplate}"
                                  Cursor="Hand" Margin="8,0,0,0"/>
                </Grid>
            </Grid>

            <!-- RIGHT CONTENT -->
            <Grid Grid.Column="1" Grid.Row="0" Grid.RowSpan="4">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" SharedSizeGroup="HeaderRow"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Border x:Name="HeaderBorder" Grid.Row="0" Background="#FFFFFF" BorderBrush="#E0E5F5"
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
                              CanContentScroll="False"
                              Background="#F4F6FB">
                    <ContentControl x:Name="ContentHost" Margin="28,24,28,24"/>
                </ScrollViewer>
            </Grid>
        </Grid>

        <!-- Footer -->
        <Border x:Name="FooterBorder" Grid.Row="2" Background="#FFFFFF" BorderBrush="#E0E5F5" BorderThickness="0,1,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="260"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock x:Name="FooterLeft" Grid.Column="0"
                           Text="v1.2  |  Administrator"
                           Foreground="#A8B4E8" FontSize="11" FontWeight="SemiBold"
                           VerticalAlignment="Center" Margin="20,10,0,10"/>

                <TextBlock x:Name="FooterMid" Grid.Column="1"
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

$Global:PTS_Window.Dispatcher.add_UnhandledException({
    param($sender, $e)
    Write-PTSExceptionReport -Context "WPF.DispatcherUnhandledException" -Exception $e.Exception -Extra @{
        handled_before = $e.Handled
    }
})

[System.AppDomain]::CurrentDomain.add_UnhandledException({
    param($sender, $eventArgs)
    $ex = $eventArgs.ExceptionObject -as [System.Exception]
    Write-PTSExceptionReport -Context "AppDomain.UnhandledException" -Exception $ex -Extra @{
        is_terminating = $eventArgs.IsTerminating
    }
})

# ===========================================================================
# CACHE UI REFERENCES
# ===========================================================================
$Global:PTS_UI = @{
    ContentHost      = $Global:PTS_Window.FindName("ContentHost")
    ContentScroller  = $Global:PTS_Window.FindName("ContentScroller")
    SidebarPanel     = $Global:PTS_Window.FindName("SidebarPanel")
    SidebarGrid      = $Global:PTS_Window.FindName("SidebarGrid")
    SidebarDivTop    = $Global:PTS_Window.FindName("SidebarDivTop")
    SidebarDivBot    = $Global:PTS_Window.FindName("SidebarDivBot")
    HeaderEyebrow    = $Global:PTS_Window.FindName("HeaderEyebrow")
    HeaderTitle      = $Global:PTS_Window.FindName("HeaderTitle")
    HeaderSubtitle   = $Global:PTS_Window.FindName("HeaderSubtitle")
    HeaderBorder     = $Global:PTS_Window.FindName("HeaderBorder")
    FooterBorder     = $Global:PTS_Window.FindName("FooterBorder")
    FooterStatus     = $Global:PTS_Window.FindName("FooterStatus")
    FooterLeft       = $Global:PTS_Window.FindName("FooterLeft")
    FooterMid        = $Global:PTS_Window.FindName("FooterMid")
    BackBtn          = $Global:PTS_Window.FindName("BackBtn")
    DarkModeToggle   = $Global:PTS_Window.FindName("DarkModeToggle")
    DarkModeLabel    = $Global:PTS_Window.FindName("DarkModeLabel")
    LogoBorder       = $Global:PTS_Window.FindName("LogoBorder")
}

$Global:PTS_UI.LogoBorder.Background = $Global:PTS_Brush["SidebarBg"]

$Global:PTS_UI.DarkModeToggle.Add_Click({
    $isDark = [bool]$Global:PTS_UI.DarkModeToggle.IsChecked
    Apply-PTSTheme -DarkMode $isDark
})

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

if (Test-Path $Global:PTS_ModulesPath) {
    Get-ChildItem -Path $Global:PTS_ModulesPath -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
        $moduleFile = $_.FullName
        try   { . $moduleFile }
        catch {
            Write-Warning "Failed to load module $([System.IO.Path]::GetFileName($moduleFile)): $_"
            Write-PTSExceptionReport -Context "ModuleLoad" -ModuleFile $moduleFile -ErrorRecord $_
        }
    }
}

# ===========================================================================
# HELPERS
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

    if ($Global:PTS_ActiveSidebarBtn -ne $null -and $Global:PTS_ActiveSidebarBtn -ne $SenderBtn) {
        $prevBtn = $Global:PTS_ActiveSidebarBtn
        $prevBtn.Background = $Global:PTS_Brush["SidebarBg"]
        if ($prevBtn.Tag -ne $null) {
            $pt = $prevBtn.Tag
            if ($pt.Label)     { $pt.Label.Foreground = $Global:PTS_Brush["SidebarText"]; $pt.Label.FontWeight = "Normal" }
            if ($pt.Badge)     { $pt.Badge.Background = $Global:PTS_Brush["SidebarBadgeBg"] }
            if ($pt.CountText) { $pt.CountText.Foreground = $Global:PTS_Brush["SidebarText"] }
        }
    }

    $Global:PTS_ActiveSidebarBtn = $SenderBtn
    $SenderBtn.Background = $Global:PTS_Brush["SidebarActive"]

    $tag = $SenderBtn.Tag
    if ($tag.Label)     { $tag.Label.Foreground = $Global:PTS_Brush["SidebarTextActive"]; $tag.Label.FontWeight = "SemiBold" }
    if ($tag.Badge)     { $tag.Badge.Background = $Global:PTS_Brush["SidebarBadgeBgActive"] }
    if ($tag.CountText) { $tag.CountText.Foreground = $Global:PTS_Brush["SidebarTextActive"] }

    Show-PTSCategoryView -DisplayName $tag.DisplayName
}

function Global:Invoke-TileClick {
    param($SenderBtn, $EventArgs)
    $module = $SenderBtn.Tag
    if ($module) { Show-PTSModuleView -Module $module }
}

# ===========================================================================
# SIDEBAR BUILDER
# ===========================================================================
function Global:Build-PTSSidebar {
    $Global:PTS_UI.SidebarPanel.Children.Clear()

    $presentDisplayNames = $Global:PTS_Modules | ForEach-Object {
        $raw = $_.Category
        if ($Global:PTS_CategoryDisplayNames.ContainsKey($raw)) { $Global:PTS_CategoryDisplayNames[$raw] }
        else { $raw }
    } | Select-Object -Unique

    $orderedCategories = $Global:PTS_CategoryOrder | Where-Object { $presentDisplayNames -contains $_ }

    foreach ($displayName in $orderedCategories) {
        $internalKey = $null
        foreach ($entry in $Global:PTS_CategoryDisplayNames.GetEnumerator()) {
            if ($entry.Value -eq $displayName) { $internalKey = $entry.Key; break }
        }
        if (-not $internalKey) { $internalKey = $displayName }

        $modCount = ($Global:PTS_Modules | Where-Object { $_.Category -eq $internalKey }).Count

        $btn = New-Object System.Windows.Controls.Button
        $btn.Style      = $Global:PTS_Window.FindResource("SidebarButton")
        $btn.Background = $Global:PTS_Brush["SidebarBg"]

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
        $btn.Tag = [PSCustomObject]@{
            DisplayName = $displayName
            Label       = $label
            Badge       = $countBadge
            CountText   = $countText
        }

        $btn.Add_MouseEnter({ Invoke-SidebarMouseEnter -SenderBtn $args[0] -EventArgs $args[1] })
        $btn.Add_MouseLeave({ Invoke-SidebarMouseLeave -SenderBtn $args[0] -EventArgs $args[1] })
        $btn.Add_Click({     Invoke-SidebarClick       -SenderBtn $args[0] -EventArgs $args[1] })

        $Global:PTS_UI.SidebarPanel.Children.Add($btn) | Out-Null

        $div = New-Object System.Windows.Controls.Border
        $div.Height     = 1
        $div.Background = $Global:PTS_Brush["SidebarDivider"]
        $Global:PTS_UI.SidebarPanel.Children.Add($div) | Out-Null
    }

    if ($Global:PTS_ActiveSidebarBtn -ne $null) {
        foreach ($child in $Global:PTS_UI.SidebarPanel.Children) {
            if ($child -is [System.Windows.Controls.Button] -and
                $child.Tag -ne $null -and
                $child.Tag.DisplayName -eq $Global:PTS_ActiveSidebarBtn.Tag.DisplayName) {
                $Global:PTS_ActiveSidebarBtn = $child
                $child.Background = $Global:PTS_Brush["SidebarActive"]
                if ($child.Tag.Label)     { $child.Tag.Label.Foreground = $Global:PTS_Brush["SidebarTextActive"]; $child.Tag.Label.FontWeight = "SemiBold" }
                if ($child.Tag.Badge)     { $child.Tag.Badge.Background = $Global:PTS_Brush["SidebarBadgeBgActive"] }
                if ($child.Tag.CountText) { $child.Tag.CountText.Foreground = $Global:PTS_Brush["SidebarTextActive"] }
                break
            }
        }
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
        Write-PTSExceptionReport `
            -Context "ModuleView.Load" `
            -ModuleId $Module.Id `
            -ModuleName $Module.Name `
            -ErrorRecord $_

        $logPath = Get-PowerToolsErrorLogPath
        [System.Windows.MessageBox]::Show(
            "Failed to load module:`n`n$_`n`nDetailed error report:`n$logPath",
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

        $catBadge              = New-Object System.Windows.Controls.Border
        $catBadge.Background   = $Global:PTS_Brush["Primary"]
        $catBadge.CornerRadius = New-Object System.Windows.CornerRadius(4)
        $catBadge.Padding      = "8,3,8,3"
        $catBadge.Margin       = "0,0,0,8"
        $catBadge.HorizontalAlignment = "Left"

        $badgeText            = New-Object System.Windows.Controls.TextBlock
        $badgeText.Text       = $DisplayName.ToUpper()
        $badgeText.Foreground = $Global:PTS_Brush["SidebarTextActive"]
        $badgeText.FontSize   = 9
        $badgeText.FontWeight = "Bold"
        $catBadge.Child       = $badgeText
        $stack.Children.Add($catBadge) | Out-Null

        $tbl              = New-Object System.Windows.Controls.TextBlock
        $tbl.Text         = $mod.Name
        $tbl.Foreground   = $Global:PTS_Brush["TextDark"]
        $tbl.FontSize     = 15
        $tbl.FontWeight   = "SemiBold"
        $tbl.Margin       = "0,0,0,6"
        $tbl.TextWrapping = "Wrap"
        $stack.Children.Add($tbl) | Out-Null

        $dbl              = New-Object System.Windows.Controls.TextBlock
        $dbl.Text         = $mod.Description
        $dbl.Foreground   = $Global:PTS_Brush["TextMuted"]
        $dbl.FontSize     = 12
        $dbl.TextWrapping = "Wrap"
        $dbl.LineHeight   = 17
        $stack.Children.Add($dbl) | Out-Null

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
        $btn.Add_Click({ Invoke-TileClick -SenderBtn $args[0] -EventArgs $args[1] })
        $wrap.Children.Add($btn) | Out-Null
    }

    $Global:PTS_UI.ContentHost.Content = $wrap
    $Global:PTS_UI.ContentScroller.ScrollToTop()
}

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

$firstBtn = $Global:PTS_UI.SidebarPanel.Children |
    Where-Object { $_ -is [System.Windows.Controls.Button] } |
    Select-Object -First 1

if ($firstBtn) {
    $firstBtn.RaiseEvent(
        [System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)
    )
}

$Global:PTS_Window.ShowDialog() | Out-Null
