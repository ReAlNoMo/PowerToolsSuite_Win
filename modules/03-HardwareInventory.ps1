# Module: Hardware Inventory
# Generates a styled HTML report of system hardware and opens it in the default browser.

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

    <Grid Grid.Row="3" Margin="0,6,0,8">
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
                       FontSize="12" Padding="16,14" TextWrapping="Wrap"
                       LineHeight="20" Text="Ready. Click Generate Report to begin."/>
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

    # All controls in script-scope so event handlers can reach them
    $script:HW_generate    = $view.FindName("GenerateBtn")
    $script:HW_openLast    = $view.FindName("OpenLastBtn")
    $script:HW_clearLog    = $view.FindName("ClearLogBtn")
    $script:HW_outputLbl   = $view.FindName("OutputPath")
    $script:HW_logBox      = $view.FindName("LogBox")
    $script:HW_logScroller = $view.FindName("LogScroller")
    $script:HW_initText    = "Ready. Click Generate Report to begin."
    $script:HW_lastReport  = ""

    $script:HW_outputLbl.Text = Join-Path $env:USERPROFILE "Desktop\Hardware_Report_<timestamp>.html"

    function Global:HW-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:HW_logBox.Text -eq $script:HW_initText) { $script:HW_logBox.Text = $entry }
        else { $script:HW_logBox.Text += $entry }
        $script:HW_logScroller.Dispatcher.Invoke([action]{ $script:HW_logScroller.ScrollToEnd() })
    }

    function Global:HW-ConvertSize {
        param([long]$Bytes)
        if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
        elseif ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
        elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
        else { return "{0:N2} KB" -f ($Bytes / 1KB) }
    }

    function Global:HW-HtmlTable {
        param([array]$Data, [string[]]$Props)
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.Append("<table><tr>")
        foreach ($p in $Props) { [void]$sb.Append("<th>$p</th>") }
        [void]$sb.Append("</tr>")
        foreach ($item in $Data) {
            [void]$sb.Append("<tr>")
            foreach ($p in $Props) {
                $v = $item.$p; if ($null -eq $v -or $v -eq "") { $v = "-" }
                [void]$sb.Append("<td>$v</td>")
            }
            [void]$sb.Append("</tr>")
        }
        [void]$sb.Append("</table>")
        return $sb.ToString()
    }

    $script:HW_generate.Add_Click({
        $script:HW_generate.IsEnabled = $false
        $script:HW_generate.Content   = "Generating..."
        try {
            HW-AddLog "Collecting system information..." "INFO"
            $ErrorActionPreference = "SilentlyContinue"

            $rp = Join-Path $env:USERPROFILE ("Desktop\Hardware_Report_{0}.html" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm'))
            $script:HW_outputLbl.Text = $rp

            $CS       = Get-CimInstance Win32_ComputerSystem
            $BIOS     = Get-CimInstance Win32_BIOS
            $Board    = Get-CimInstance Win32_BaseBoard
            $CPUs     = Get-CimInstance Win32_Processor
            $RAMSlots = Get-CimInstance Win32_PhysicalMemory
            $RAMTotal = ($RAMSlots | Measure-Object -Property Capacity -Sum).Sum
            $GPUs     = Get-CimInstance Win32_VideoController
            $Disks    = Get-CimInstance Win32_DiskDrive
            $Parts    = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
            $NICs     = Get-CimInstance Win32_NetworkAdapter | Where-Object {
                $_.PhysicalAdapter -eq $true -and $_.Name -notmatch "Virtual|Bluetooth|WAN|Miniport"
            }
            $NICCfg   = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
            $Audio    = Get-CimInstance Win32_SoundDevice
            $Drivers  = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null }

            HW-AddLog "Building HTML report..." "INFO"

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
                $h += "<tr><td>L2 Cache</td><td>$(HW-ConvertSize ($cpu.L2CacheSize * 1024))</td></tr>"
                $h += "<tr><td>L3 Cache</td><td>$(HW-ConvertSize ($cpu.L3CacheSize * 1024))</td></tr>"
                $h += "<tr><td>Driver Version</td><td>$($cd.DriverVersion)</td></tr>"
                $h += "<tr><td>Driver Date</td><td>$($cd.DriverDate)</td></tr></table>"
            }

            $h += "<h2>Memory (RAM)</h2>"
            $h += "<p><strong>Total: $(HW-ConvertSize $RAMTotal) | $($RAMSlots.Count) Module(s)</strong></p>"
            $ramD = $RAMSlots | Select-Object `
                @{N="Slot";E={$_.DeviceLocator}}, @{N="Capacity";E={HW-ConvertSize $_.Capacity}},
                @{N="Speed";E={"$($_.Speed) MHz"}}, @{N="Manufacturer";E={$_.Manufacturer}},
                @{N="Part Number";E={$_.PartNumber}}, @{N="Serial Number";E={$_.SerialNumber}}
            $h += HW-HtmlTable -Data $ramD -Props "Slot","Capacity","Speed","Manufacturer","Part Number","Serial Number"

            $h += "<h2>Graphics Card (GPU)</h2>"
            $gpuD = $GPUs | Select-Object Name,
                @{N="VRAM";E={HW-ConvertSize $_.AdapterRAM}},
                @{N="Resolution";E={"$($_.CurrentHorizontalResolution) x $($_.CurrentVerticalResolution)"}},
                @{N="Driver";E={$_.DriverVersion}}, @{N="Driver Date";E={$_.DriverDate}}, Status
            $h += HW-HtmlTable -Data $gpuD -Props "Name","VRAM","Resolution","Driver","Driver Date","Status"

            $h += "<h2>Storage Drives</h2>"
            $diskD = $Disks | ForEach-Object {
                [PSCustomObject]@{
                    "Model"="$($_.Model)"; "Interface"="$($_.InterfaceType)";
                    "Size"=(HW-ConvertSize $_.Size); "Serial Number"="$($_.SerialNumber.Trim())";
                    "Partitions"="$($_.Partitions)"; "Status"="$($_.Status)"
                }
            }
            $h += HW-HtmlTable -Data $diskD -Props "Model","Interface","Size","Serial Number","Partitions","Status"

            $h += "<h2>Logical Drives</h2>"
            $partD = $Parts | Select-Object @{N="Drive";E={$_.DeviceID}},
                @{N="Size";E={HW-ConvertSize $_.Size}}, @{N="Free";E={HW-ConvertSize $_.FreeSpace}},
                @{N="File System";E={$_.FileSystem}}, @{N="Label";E={$_.VolumeName}}
            $h += HW-HtmlTable -Data $partD -Props "Drive","Size","Free","File System","Label"

            $h += "<h2>Network Adapters</h2>"
            $nicD = $NICs | ForEach-Object {
                $n = $_
                $drv = $Drivers | Where-Object { $_.DeviceName -eq $n.Name } | Select-Object -First 1
                $ip  = $NICCfg  | Where-Object { $_.Description -eq $n.Name }
                [PSCustomObject]@{
                    "Name"=$n.Name; "Manufacturer"=$n.Manufacturer; "MAC"=$n.MACAddress;
                    "Type"=$n.AdapterType; "Driver"=$drv.DriverVersion;
                    "Driver Date"=$drv.DriverDate; "IP"=($ip.IPAddress -join ", ")
                }
            }
            $h += HW-HtmlTable -Data $nicD -Props "Name","Manufacturer","MAC","Type","Driver","Driver Date","IP"

            $h += "<h2>Audio Devices</h2>"
            $audD = $Audio | ForEach-Object {
                $a = $_; $drv = $Drivers | Where-Object { $_.DeviceName -eq $a.Name } | Select-Object -First 1
                [PSCustomObject]@{
                    "Name"=$a.Name; "Manufacturer"=$a.Manufacturer; "Status"=$a.Status;
                    "Driver"=$drv.DriverVersion; "Driver Date"=$drv.DriverDate
                }
            }
            $h += HW-HtmlTable -Data $audD -Props "Name","Manufacturer","Status","Driver","Driver Date"

            $h += "<h2>All PnP Drivers</h2>"
            $drvD = $Drivers | Where-Object { $_.DriverVersion -ne $null } |
                Sort-Object DeviceClass, DeviceName |
                Select-Object @{N="Class";E={$_.DeviceClass}}, @{N="Device";E={$_.DeviceName}},
                    @{N="Version";E={$_.DriverVersion}}, @{N="Provider";E={$_.DriverProviderName}},
                    @{N="Date";E={$_.DriverDate}}
            $h += HW-HtmlTable -Data $drvD -Props "Class","Device","Version","Provider","Date"

            $h += "<div class='info'>Report by PowerTools Suite | $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')</div>"
            $h += "</body></html>"

            $h | Out-File -FilePath $rp -Encoding UTF8
            $script:HW_lastReport = $rp
            HW-AddLog "Report saved: $rp" "OK"
            HW-AddLog "Opening in browser..." "INFO"
            Start-Process $rp
            $script:HW_openLast.IsEnabled = $true
        }
        catch { HW-AddLog "Error: $_" "FAIL" }
        finally {
            $script:HW_generate.IsEnabled = $true
            $script:HW_generate.Content   = "Generate Report"
        }
    })

    $script:HW_openLast.Add_Click({
        if ($script:HW_lastReport -and (Test-Path $script:HW_lastReport)) {
            Start-Process $script:HW_lastReport
            HW-AddLog "Opened: $($script:HW_lastReport)" "INFO"
        } else { HW-AddLog "No report available." "WARN" }
    })

    $script:HW_clearLog.Add_Click({
        $script:HW_logBox.Text = ""
        HW-AddLog "Log cleared." "INFO"
    })

    return $view
}
