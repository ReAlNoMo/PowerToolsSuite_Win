# Module: Hardware Inventory
# Generates a styled HTML report of system hardware and opens it in the default browser.
# Progress bar + live log updates via background runspace + DispatcherTimer.

Register-PowerToolsModule `
    -Id            "hardware-inventory" `
    -Name          "Hardware Inventory" `
    -Description   "Generate a complete HTML hardware report: CPU, RAM, GPU, storage, network, and drivers." `
    -Category      "Diagnostics" `
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
        <RowDefinition Height="*"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" Background="#FFFFFF" BorderBrush="#D0D6F0"
            BorderThickness="1.5" CornerRadius="10" Padding="18,16" Margin="0,0,0,14">
        <StackPanel>
            <TextBlock Text="WHAT THIS DOES" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock Foreground="#4A5280" FontSize="13" TextWrapping="Wrap" LineHeight="20"
                Text="Collects hardware information via WMI/CIM and writes a styled HTML report to your Desktop."/>
        </StackPanel>
    </Border>

    <StackPanel Grid.Row="1" Margin="0,0,0,14">
        <TextBlock Text="OUTPUT PATH" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,6"/>
        <Border Background="#FAFBFF" BorderBrush="#D8DEFA" BorderThickness="1.5"
                CornerRadius="8" Padding="12,10">
            <TextBlock x:Name="OutputPath" Foreground="#4A5280" FontSize="12"
                       FontFamily="Cascadia Code, Consolas"/>
        </Border>
    </StackPanel>

    <Grid Grid.Row="2" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="180"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="GenerateBtn" Content="Generate Report"
                Style="{DynamicResource PrimaryButton}" Height="46" FontSize="14" Margin="0,0,8,0"/>
        <Button Grid.Column="1" x:Name="OpenLastBtn" Content="Open Last Report"
                Style="{DynamicResource SecondaryButton}" Height="46" FontSize="13" IsEnabled="False"/>
    </Grid>

    <!-- Progress section -->
    <Grid Grid.Row="3" Margin="0,0,0,6">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="StatusLabel" Grid.Column="0"
                   Text="Idle" Foreground="#8890B8" FontSize="11"
                   VerticalAlignment="Center"/>
        <TextBlock x:Name="PctLabel" Grid.Column="1"
                   Text="" Foreground="#3B5BDB" FontSize="11" FontWeight="Bold"
                   VerticalAlignment="Center"/>
    </Grid>
    <ProgressBar Grid.Row="4" x:Name="ProgressBar" Height="6"
                 Minimum="0" Maximum="100" Value="0" Margin="0,0,0,14"/>

    <Grid Grid.Row="5">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" VerticalAlignment="Center"/>
            <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                    Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
        </Grid>

        <Border Grid.Row="1" Background="#FAFBFF" BorderBrush="#D8DEFA"
                BorderThickness="1.5" CornerRadius="10" MinHeight="160">
            <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogBox" Foreground="#8890B8"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="12" Padding="16,14" TextWrapping="Wrap"
                           LineHeight="20" Text="Ready. Click Generate Report to begin."/>
            </ScrollViewer>
        </Border>
    </Grid>
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $Global:HW_generate     = $view.FindName("GenerateBtn")
    $Global:HW_openLast     = $view.FindName("OpenLastBtn")
    $Global:HW_clearLog     = $view.FindName("ClearLogBtn")
    $Global:HW_outputLbl    = $view.FindName("OutputPath")
    $Global:HW_logBox       = $view.FindName("LogBox")
    $Global:HW_logScroller  = $view.FindName("LogScroller")
    $Global:HW_progress     = $view.FindName("ProgressBar")
    $Global:HW_statusLabel  = $view.FindName("StatusLabel")
    $Global:HW_pctLabel     = $view.FindName("PctLabel")
    $Global:HW_initText     = "Ready. Click Generate Report to begin."
    $Global:HW_lastReport   = ""
    $Global:HW_msgQueue     = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:HW_timer        = $null

    $Global:HW_outputLbl.Text = Join-Path $env:USERPROFILE "Desktop\Hardware_Report_<timestamp>.html"

    function Global:HW-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($Global:HW_logBox.Text -eq $Global:HW_initText) { $Global:HW_logBox.Text = $entry }
        else { $Global:HW_logBox.Text += $entry }
        $Global:HW_logScroller.ScrollToEnd()
    }

    function Global:HW-StartTimer {
        $Global:HW_timer = New-Object System.Windows.Threading.DispatcherTimer
        $Global:HW_timer.Interval = [TimeSpan]::FromMilliseconds(150)
        $Global:HW_timer.Add_Tick({
            $item = $null
            while ($Global:HW_msgQueue.TryDequeue([ref]$item)) {
                switch ($item.Type) {
                    "LOG" {
                        HW-AddLog -Msg $item.Msg -Type $item.Tag
                    }
                    "PROGRESS" {
                        $Global:HW_progress.Value   = $item.Pct
                        $Global:HW_statusLabel.Text = $item.Status
                        $Global:HW_pctLabel.Text    = "$($item.Pct)%"
                    }
                    "DONE" {
                        $Global:HW_timer.Stop()
                        $Global:HW_progress.Value        = 100
                        $Global:HW_pctLabel.Text         = "100%"
                        $Global:HW_statusLabel.Text      = "Report generated"
                        $Global:HW_statusLabel.Foreground = $Global:PTS_Brush["Success"]
                        $Global:HW_generate.IsEnabled    = $true
                        $Global:HW_generate.Content      = "Generate Report"
                        $Global:HW_lastReport            = $item.ReportPath
                        $Global:HW_outputLbl.Text        = $item.ReportPath
                        $Global:HW_openLast.IsEnabled    = $true
                        if ($item.ReportPath -ne "") { Start-Process $item.ReportPath }
                    }
                    "ERROR" {
                        $Global:HW_timer.Stop()
                        $Global:HW_statusLabel.Text      = "Error"
                        $Global:HW_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                        $Global:HW_generate.IsEnabled    = $true
                        $Global:HW_generate.Content      = "Generate Report"
                    }
                }
            }
        })
        $Global:HW_timer.Start()
    }

    # Background report generation script
    $Global:HW_reportScript = {
        param($ReportPath, $Queue)

        function Q-Log   { param($M,$T="INFO") $Queue.Enqueue([PSCustomObject]@{Type="LOG";Msg=$M;Tag=$T}) }
        function Q-Prog  { param($P,$S)        $Queue.Enqueue([PSCustomObject]@{Type="PROGRESS";Pct=$P;Status=$S}) }

        function ConvertSize {
            param([long]$Bytes)
            if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
            elseif ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
            elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
            else { return "{0:N2} KB" -f ($Bytes / 1KB) }
        }

        function HtmlTable {
            param([array]$Data, [string[]]$Props)
            $sb = [System.Text.StringBuilder]::new()
            [void]$sb.Append("<table><tr>")
            foreach ($p in $Props) { [void]$sb.Append("<th>$p</th>") }
            [void]$sb.Append("</tr>")
            foreach ($item in $Data) {
                [void]$sb.Append("<tr>")
                foreach ($p in $Props) {
                    $v = $item.$p
                    if ($null -eq $v -or $v -eq "") { $v = "-" }
                    [void]$sb.Append("<td>$v</td>")
                }
                [void]$sb.Append("</tr>")
            }
            [void]$sb.Append("</table>")
            return $sb.ToString()
        }

        try {
            $ErrorActionPreference = "SilentlyContinue"

            Q-Prog 5  "Collecting: System / Mainboard..."
            Q-Log  "Collecting system information..."
            $CS    = Get-CimInstance Win32_ComputerSystem
            $BIOS  = Get-CimInstance Win32_BIOS
            $Board = Get-CimInstance Win32_BaseBoard

            Q-Prog 15 "Collecting: CPU..."
            Q-Log  "Collecting CPU data..."
            $CPUs = Get-CimInstance Win32_Processor

            Q-Prog 25 "Collecting: RAM..."
            Q-Log  "Collecting RAM data..."
            $RAMSlots = Get-CimInstance Win32_PhysicalMemory
            $RAMTotal = ($RAMSlots | Measure-Object -Property Capacity -Sum).Sum

            Q-Prog 35 "Collecting: GPU..."
            Q-Log  "Collecting GPU data..."
            $GPUs = Get-CimInstance Win32_VideoController

            Q-Prog 45 "Collecting: Storage..."
            Q-Log  "Collecting storage data..."
            $Disks = Get-CimInstance Win32_DiskDrive
            $Parts = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

            Q-Prog 55 "Collecting: Network adapters..."
            Q-Log  "Collecting network adapter data..."
            $NICs   = Get-CimInstance Win32_NetworkAdapter | Where-Object {
                $_.PhysicalAdapter -eq $true -and $_.Name -notmatch "Virtual|Bluetooth|WAN|Miniport"
            }
            $NICCfg = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }

            Q-Prog 65 "Collecting: Audio devices..."
            Q-Log  "Collecting audio device data..."
            $Audio = Get-CimInstance Win32_SoundDevice

            Q-Prog 75 "Collecting: PnP drivers (may take a moment)..."
            Q-Log  "Collecting PnP driver data..."
            $Drivers = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null }

            Q-Prog 85 "Building HTML report..."
            Q-Log  "Building HTML report..."

            $css  = "body{font-family:Segoe UI,Arial,sans-serif;background:#1a1a2e;color:#eee;margin:20px}"
            $css += "h1{color:#00d4ff;text-align:center;border-bottom:2px solid #00d4ff;padding-bottom:10px}"
            $css += "h2{color:#00d4ff;background:#16213e;padding:8px 15px;border-left:4px solid #00d4ff;margin-top:30px}"
            $css += "table{width:100%;border-collapse:collapse;margin-bottom:20px}"
            $css += "th{background:#0f3460;color:#00d4ff;padding:10px;text-align:left}"
            $css += "td{padding:8px 10px;border-bottom:1px solid #333}"
            $css += "tr:hover{background:#16213e} tr:nth-child(even){background:#0d0d1a}"
            $css += ".info{color:#aaa;font-size:12px;text-align:center;margin-top:40px}"
            $css += ".badge{background:#00d4ff;color:#000;padding:2px 8px;border-radius:10px;font-size:11px}"

            $h  = "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'>"
            $h += "<title>Hardware Report - $($CS.Name)</title><style>$css</style></head><body>"
            $h += "<h1>Hardware Inventory Report</h1>"
            $h += "<p style='text-align:center'>Generated: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss') | "
            $h += "Computer: <span class='badge'>$($CS.Name)</span> | User: <span class='badge'>$($CS.UserName)</span></p>"

            $h += "<h2>System / Mainboard</h2><table><tr><th>Property</th><th>Value</th></tr>"
            $h += "<tr><td>Manufacturer</td><td>$($CS.Manufacturer)</td></tr>"
            $h += "<tr><td>Model</td><td>$($CS.Model)</td></tr>"
            $h += "<tr><td>Board Manufacturer</td><td>$($Board.Manufacturer)</td></tr>"
            $h += "<tr><td>Board Product</td><td>$($Board.Product)</td></tr>"
            $h += "<tr><td>Board Version</td><td>$($Board.Version)</td></tr>"
            $h += "<tr><td>Board Serial</td><td>$($Board.SerialNumber)</td></tr>"
            $h += "<tr><td>BIOS Version</td><td>$($BIOS.SMBIOSBIOSVersion)</td></tr>"
            $h += "<tr><td>BIOS Date</td><td>$($BIOS.ReleaseDate)</td></tr>"
            $h += "<tr><td>BIOS Manufacturer</td><td>$($BIOS.Manufacturer)</td></tr></table>"

            $h += "<h2>CPU / Processor</h2>"
            foreach ($cpu in $CPUs) {
                $cd = $Drivers | Where-Object { $_.DeviceName -match "Processor" } | Select-Object -First 1
                $h += "<table><tr><th>Property</th><th>Value</th></tr>"
                $h += "<tr><td>Name</td><td>$($cpu.Name)</td></tr>"
                $h += "<tr><td>Manufacturer</td><td>$($cpu.Manufacturer)</td></tr>"
                $h += "<tr><td>Cores (Physical)</td><td>$($cpu.NumberOfCores)</td></tr>"
                $h += "<tr><td>Logical Cores</td><td>$($cpu.NumberOfLogicalProcessors)</td></tr>"
                $h += "<tr><td>Max Clock Speed</td><td>$($cpu.MaxClockSpeed) MHz</td></tr>"
                $h += "<tr><td>Socket</td><td>$($cpu.SocketDesignation)</td></tr>"
                $h += "<tr><td>L2 Cache</td><td>$(ConvertSize ($cpu.L2CacheSize * 1024))</td></tr>"
                $h += "<tr><td>L3 Cache</td><td>$(ConvertSize ($cpu.L3CacheSize * 1024))</td></tr>"
                $h += "<tr><td>Driver Version</td><td>$($cd.DriverVersion)</td></tr>"
                $h += "<tr><td>Driver Date</td><td>$($cd.DriverDate)</td></tr></table>"
            }

            $h += "<h2>Memory (RAM)</h2>"
            $h += "<p><strong>Total: $(ConvertSize $RAMTotal) | $($RAMSlots.Count) Module(s)</strong></p>"
            $ramD = $RAMSlots | Select-Object `
                @{N="Slot";E={$_.DeviceLocator}}, @{N="Capacity";E={ConvertSize $_.Capacity}},
                @{N="Speed";E={"$($_.Speed) MHz"}}, @{N="Manufacturer";E={$_.Manufacturer}},
                @{N="Part Number";E={$_.PartNumber}}, @{N="Serial Number";E={$_.SerialNumber}}
            $h += HtmlTable -Data $ramD -Props "Slot","Capacity","Speed","Manufacturer","Part Number","Serial Number"

            $h += "<h2>Graphics Card (GPU)</h2>"
            $gpuD = $GPUs | Select-Object Name,
                @{N="VRAM";E={ConvertSize $_.AdapterRAM}},
                @{N="Resolution";E={"$($_.CurrentHorizontalResolution) x $($_.CurrentVerticalResolution)"}},
                @{N="Driver";E={$_.DriverVersion}}, @{N="Driver Date";E={$_.DriverDate}}, Status
            $h += HtmlTable -Data $gpuD -Props "Name","VRAM","Resolution","Driver","Driver Date","Status"

            $h += "<h2>Storage Drives</h2>"
            $diskD = $Disks | ForEach-Object {
                [PSCustomObject]@{
                    "Model"="$($_.Model)"; "Interface"="$($_.InterfaceType)";
                    "Size"=(ConvertSize $_.Size); "Serial Number"="$($_.SerialNumber.Trim())";
                    "Partitions"="$($_.Partitions)"; "Status"="$($_.Status)"
                }
            }
            $h += HtmlTable -Data $diskD -Props "Model","Interface","Size","Serial Number","Partitions","Status"

            $h += "<h2>Logical Drives</h2>"
            $partD = $Parts | Select-Object @{N="Drive";E={$_.DeviceID}},
                @{N="Size";E={ConvertSize $_.Size}}, @{N="Free";E={ConvertSize $_.FreeSpace}},
                @{N="File System";E={$_.FileSystem}}, @{N="Label";E={$_.VolumeName}}
            $h += HtmlTable -Data $partD -Props "Drive","Size","Free","File System","Label"

            $h += "<h2>Network Adapters</h2>"
            $nicD = $NICs | ForEach-Object {
                $n   = $_
                $drv = $Drivers | Where-Object { $_.DeviceName -eq $n.Name } | Select-Object -First 1
                $ip  = $NICCfg  | Where-Object { $_.Description -eq $n.Name }
                [PSCustomObject]@{
                    "Name"=$n.Name; "Manufacturer"=$n.Manufacturer; "MAC"=$n.MACAddress;
                    "Type"=$n.AdapterType; "Driver"=$drv.DriverVersion;
                    "Driver Date"=$drv.DriverDate; "IP"=($ip.IPAddress -join ", ")
                }
            }
            $h += HtmlTable -Data $nicD -Props "Name","Manufacturer","MAC","Type","Driver","Driver Date","IP"

            $h += "<h2>Audio Devices</h2>"
            $audD = $Audio | ForEach-Object {
                $a = $_
                $drv = $Drivers | Where-Object { $_.DeviceName -eq $a.Name } | Select-Object -First 1
                [PSCustomObject]@{
                    "Name"=$a.Name; "Manufacturer"=$a.Manufacturer; "Status"=$a.Status;
                    "Driver"=$drv.DriverVersion; "Driver Date"=$drv.DriverDate
                }
            }
            $h += HtmlTable -Data $audD -Props "Name","Manufacturer","Status","Driver","Driver Date"

            $h += "<h2>All PnP Drivers</h2>"
            $drvD = $Drivers | Where-Object { $_.DriverVersion -ne $null } |
                Sort-Object DeviceClass, DeviceName |
                Select-Object @{N="Class";E={$_.DeviceClass}}, @{N="Device";E={$_.DeviceName}},
                    @{N="Version";E={$_.DriverVersion}}, @{N="Provider";E={$_.DriverProviderName}},
                    @{N="Date";E={$_.DriverDate}}
            $h += HtmlTable -Data $drvD -Props "Class","Device","Version","Provider","Date"

            $h += "<div class='info'>Report by PowerTools Suite | $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')</div>"
            $h += "</body></html>"

            Q-Prog 95 "Saving report..."
            Q-Log  "Saving report to: $ReportPath"
            $h | Out-File -FilePath $ReportPath -Encoding UTF8

            Q-Log "Report saved: $ReportPath" "OK"
            $Queue.Enqueue([PSCustomObject]@{Type="DONE"; ReportPath=$ReportPath})
        }
        catch {
            Q-Log "Error: $_" "FAIL"
            $Queue.Enqueue([PSCustomObject]@{Type="ERROR"})
        }
    }

    $Global:HW_generate.Add_Click({
        $Global:HW_generate.IsEnabled        = $false
        $Global:HW_generate.Content          = "Generating..."
        $Global:HW_progress.Value            = 0
        $Global:HW_pctLabel.Text             = "0%"
        $Global:HW_statusLabel.Text          = "Starting..."
        $Global:HW_statusLabel.Foreground    = $Global:PTS_Brush["TextMuted"]
        $Global:HW_msgQueue                  = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

        $rp = Join-Path $env:USERPROFILE ("Desktop\Hardware_Report_{0}.html" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm'))
        $Global:HW_outputLbl.Text = $rp

        HW-AddLog "Starting hardware inventory..." "INFO"
        HW-StartTimer

        $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $rs.Open()
        $ps = [System.Management.Automation.PowerShell]::Create()
        $ps.Runspace = $rs
        $ps.AddScript($Global:HW_reportScript) | Out-Null
        $ps.AddArgument($rp)                   | Out-Null
        $ps.AddArgument($Global:HW_msgQueue)   | Out-Null
        $ps.BeginInvoke() | Out-Null
    })

    $Global:HW_openLast.Add_Click({
        if ($Global:HW_lastReport -and (Test-Path $Global:HW_lastReport)) {
            Start-Process $Global:HW_lastReport
            HW-AddLog "Opened: $($Global:HW_lastReport)" "INFO"
        } else { HW-AddLog "No report available." "WARN" }
    })

    $Global:HW_clearLog.Add_Click({
        $Global:HW_logBox.Text = ""
        HW-AddLog "Log cleared." "INFO"
    })

    return $view
}
