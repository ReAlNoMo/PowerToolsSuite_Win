# Module: Hash Verifier
# Computes and compares file hashes across multiple algorithms.
# Progress bar + live log updates via background runspace + DispatcherTimer.

Register-PowerToolsModule `
    -Id          "hash-verifier" `
    -Name        "Hash Verifier" `
    -Description "Verify file integrity by comparing a computed hash against an expected value." `
    -Category    "Security" `
    -Show        {

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
        <RowDefinition Height="*"/>
    </Grid.RowDefinitions>

    <Grid Grid.Row="0" Margin="0,0,0,16">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="160"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Margin="0,0,12,0">
            <TextBlock Text="ALGORITHM" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,6"/>
            <ComboBox x:Name="AlgoCombo" Height="40" FontSize="13" Padding="10,8">
                <ComboBoxItem Content="SHA-256" IsSelected="True"/>
                <ComboBoxItem Content="SHA-512"/>
                <ComboBoxItem Content="SHA-384"/>
                <ComboBoxItem Content="SHA-1"/>
                <ComboBoxItem Content="MD5"/>
            </ComboBox>
        </StackPanel>
        <StackPanel Grid.Column="1" VerticalAlignment="Bottom">
            <Button x:Name="ResetBtn" Content="Reset"
                    Style="{DynamicResource SecondaryButton}" Height="40"/>
        </StackPanel>
    </Grid>

    <StackPanel Grid.Row="1" Margin="0,0,0,16">
        <TextBlock Text="FILE" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,6"/>
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="120"/>
            </Grid.ColumnDefinitions>
            <Border Grid.Column="0" x:Name="FilePathBorder"
                    BorderThickness="1.5" CornerRadius="8" Margin="0,0,8,0" Height="40">
                <TextBlock x:Name="FilePathLabel" Text="No file selected..."
                           FontSize="12"
                           VerticalAlignment="Center" Padding="12,0"
                           TextTrimming="CharacterEllipsis"/>
            </Border>
            <Button Grid.Column="1" x:Name="BrowseBtn" Content="Browse..."
                    Style="{DynamicResource PrimaryButton}" Height="40"/>
        </Grid>
    </StackPanel>

    <StackPanel Grid.Row="2" Margin="0,0,0,16">
        <TextBlock Text="EXPECTED HASH" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,6"/>
        <TextBox x:Name="ExpectedHashBox" Height="40" FontSize="13" Padding="12,10"
                 BorderThickness="1.5"
                 FontFamily="Cascadia Code, Consolas, Courier New"
                 VerticalContentAlignment="Center"/>
    </StackPanel>

    <Button Grid.Row="3" x:Name="VerifyBtn" Content="Verify Hash"
            Style="{DynamicResource PrimaryButton}" Height="46"
            FontSize="14" IsEnabled="False" Margin="0,0,0,14"/>

    <Grid Grid.Row="4" Margin="0,0,0,6">
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
    <ProgressBar Grid.Row="5" x:Name="ProgressBar" Height="6"
                 Minimum="0" Maximum="100" Value="0" Margin="0,0,0,14"/>

    <Grid Grid.Row="6" Margin="0,0,0,0">
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

        <Border Grid.Row="1" x:Name="LogBorder"
                BorderThickness="1.5" CornerRadius="10" MinHeight="120">
            <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogBox"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="12" Padding="16,14" TextWrapping="Wrap"
                           LineHeight="20"
                           Text="Ready. Select a file and enter a hash value."/>
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

    $Global:HV_algo         = $view.FindName("AlgoCombo")
    $Global:HV_browse       = $view.FindName("BrowseBtn")
    $Global:HV_pathLbl      = $view.FindName("FilePathLabel")
    $Global:HV_pathBorder   = $view.FindName("FilePathBorder")
    $Global:HV_expected     = $view.FindName("ExpectedHashBox")
    $Global:HV_verify       = $view.FindName("VerifyBtn")
    $Global:HV_reset        = $view.FindName("ResetBtn")
    $Global:HV_clearLog     = $view.FindName("ClearLogBtn")
    $Global:HV_logBox       = $view.FindName("LogBox")
    $Global:HV_logBorder    = $view.FindName("LogBorder")
    $Global:HV_logScroller  = $view.FindName("LogScroller")
    $Global:HV_progress     = $view.FindName("ProgressBar")
    $Global:HV_statusLabel  = $view.FindName("StatusLabel")
    $Global:HV_pctLabel     = $view.FindName("PctLabel")
    $Global:HV_selectedFile = ""
    $Global:HV_initText     = "Ready. Select a file and enter a hash value."
    $Global:HV_msgQueue     = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:HV_timer        = $null

    # Apply theme-aware colors
    $Global:HV_pathBorder.Background   = $Global:PTS_Brush["InputBg"]
    $Global:HV_pathBorder.BorderBrush  = $Global:PTS_Brush["Border"]
    $Global:HV_pathLbl.Foreground      = $Global:PTS_Brush["TextFaint"]
    $Global:HV_expected.Background     = $Global:PTS_Brush["InputBg"]
    $Global:HV_expected.Foreground     = $Global:PTS_Brush["InputFg"]
    $Global:HV_expected.BorderBrush    = $Global:PTS_Brush["Border"]
    $Global:HV_logBox.Foreground       = $Global:PTS_Brush["TextMuted"]
    $Global:HV_logBorder.Background    = $Global:PTS_Brush["LogBg"]
    $Global:HV_logBorder.BorderBrush   = $Global:PTS_Brush["LogBorder"]

    # ===========================================================================
    # HELPERS
    # ===========================================================================
    function Global:HV-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($Global:HV_logBox.Text -eq $Global:HV_initText) { $Global:HV_logBox.Text = $entry }
        else { $Global:HV_logBox.Text += $entry }
        $Global:HV_logScroller.ScrollToEnd()
    }

    function Global:HV-UpdateVerify {
        $Global:HV_verify.IsEnabled = (
            $Global:HV_selectedFile -ne "" -and
            $Global:HV_expected.Text.Trim() -ne ""
        )
    }

    function Global:HV-StartTimer {
        $Global:HV_timer = New-Object System.Windows.Threading.DispatcherTimer
        $Global:HV_timer.Interval = [TimeSpan]::FromMilliseconds(150)
        $Global:HV_timer.Add_Tick({
            $item = $null
            while ($Global:HV_msgQueue.TryDequeue([ref]$item)) {
                switch ($item.Type) {
                    "LOG" {
                        HV-AddLog -Msg $item.Msg -Type $item.Tag
                    }
                    "PROGRESS" {
                        $Global:HV_progress.Value   = $item.Pct
                        $Global:HV_statusLabel.Text = $item.Status
                        $Global:HV_pctLabel.Text    = "$($item.Pct)%"
                    }
                    "RESULT" {
                        $Global:HV_timer.Stop()
                        $Global:HV_progress.Value   = 100
                        $Global:HV_pctLabel.Text    = "100%"
                        $Global:HV_verify.IsEnabled = $true
                        $Global:HV_verify.Content   = "Verify Hash"

                        if ($item.Match) {
                            $Global:HV_statusLabel.Text      = "PASS - Hash values match"
                            $Global:HV_statusLabel.Foreground = $Global:PTS_Brush["Success"]
                            $Global:HV_logBox.Foreground      = $Global:PTS_Brush["Success"]
                        } else {
                            $Global:HV_statusLabel.Text      = "FAIL - Hash mismatch"
                            $Global:HV_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                            $Global:HV_logBox.Foreground      = $Global:PTS_Brush["Danger"]
                        }
                    }
                    "ERROR" {
                        $Global:HV_timer.Stop()
                        $Global:HV_statusLabel.Text      = "Error"
                        $Global:HV_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                        $Global:HV_verify.IsEnabled      = $true
                        $Global:HV_verify.Content        = "Verify Hash"
                    }
                }
            }
        })
        $Global:HV_timer.Start()
    }

    # Background hash script
    $Global:HV_hashScript = {
        param($FilePath, $AlgoKey, $ExpectedHash, $Queue)

        function Enqueue-Log     { param($M,$T="INFO") $Queue.Enqueue([PSCustomObject]@{Type="LOG";Msg=$M;Tag=$T}) }
        function Enqueue-Progress{ param($P,$S) $Queue.Enqueue([PSCustomObject]@{Type="PROGRESS";Pct=$P;Status=$S}) }

        try {
            $fi   = Get-Item -LiteralPath $FilePath
            $szMB = [math]::Round($fi.Length / 1MB, 2)
            Enqueue-Log "File      : $($fi.Name)" "INFO"
            Enqueue-Log "Size      : $szMB MB" "INFO"
            Enqueue-Log "Algorithm : $AlgoKey" "INFO"
            Enqueue-Progress 5 "Opening file..."

            $algo   = [System.Security.Cryptography.HashAlgorithm]::Create($AlgoKey)
            $stream = [System.IO.File]::OpenRead($FilePath)
            $buf    = New-Object byte[] 1MB
            $total  = $stream.Length
            $read   = 0
            $sw     = [System.Diagnostics.Stopwatch]::StartNew()

            while (($n = $stream.Read($buf, 0, $buf.Length)) -gt 0) {
                $algo.TransformBlock($buf, 0, $n, $null, 0) | Out-Null
                $read += $n
                $pct   = [int](($read / $total) * 90) + 5
                if ($sw.ElapsedMilliseconds % 300 -lt 50) {
                    Enqueue-Progress $pct "Hashing... $([math]::Round($read/1MB,0)) / $([math]::Round($total/1MB,0)) MB"
                }
            }

            $algo.TransformFinalBlock([byte[]]@(), 0, 0) | Out-Null
            $stream.Close()
            $computed = [BitConverter]::ToString($algo.Hash) -replace "-",""

            Enqueue-Log "Computed  : $computed" "INFO"
            Enqueue-Log "Expected  : $ExpectedHash" "INFO"
            Enqueue-Progress 100 "Complete"

            $match = $computed.ToUpper() -eq $ExpectedHash.ToUpper().Trim()
            if ($match) {
                Enqueue-Log "Result: MATCH - File is intact." "OK"
            } else {
                Enqueue-Log "Result: MISMATCH - File may be corrupted or tampered." "FAIL"
            }
            $Queue.Enqueue([PSCustomObject]@{Type="RESULT";Match=$match})

        } catch {
            Enqueue-Log "Error: $_" "FAIL"
            $Queue.Enqueue([PSCustomObject]@{Type="ERROR"})
        }
    }

    # ===========================================================================
    # EVENT HANDLERS
    # ===========================================================================
    $Global:HV_browse.Add_Click({
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Title  = "Select file to verify"
        $ofd.Filter = "All Files (*.*)|*.*"
        if ($ofd.ShowDialog() -eq $true) {
            $Global:HV_selectedFile    = $ofd.FileName
            $Global:HV_pathLbl.Text   = [System.IO.Path]::GetFileName($ofd.FileName)
            $Global:HV_pathLbl.Foreground = $Global:PTS_Brush["TextDark"]
            HV-UpdateVerify
        }
    })

    $Global:HV_expected.Add_TextChanged({ HV-UpdateVerify })

    $Global:HV_verify.Add_Click({
        if ($Global:HV_selectedFile -eq "") { HV-AddLog "No file selected." "WARN"; return }
        $inputHash = $Global:HV_expected.Text.Trim()
        if ($inputHash -eq "") { HV-AddLog "No hash value entered." "WARN"; return }

        $algoName = $Global:HV_algo.Text
        $algoKey  = switch ($algoName) {
            "SHA-256" { "SHA256" } "SHA-512" { "SHA512" } "SHA-384" { "SHA384" }
            "SHA-1"   { "SHA1"   } "MD5"     { "MD5"    } default   { "SHA256" }
        }

        $Global:HV_verify.IsEnabled       = $false
        $Global:HV_verify.Content         = "Verifying..."
        $Global:HV_progress.Value         = 0
        $Global:HV_pctLabel.Text          = "0%"
        $Global:HV_statusLabel.Text       = "Starting..."
        $Global:HV_statusLabel.Foreground  = $Global:PTS_Brush["TextMuted"]
        $Global:HV_logBox.Foreground       = $Global:PTS_Brush["TextMuted"]
        $Global:HV_msgQueue               = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

        HV-AddLog "Starting verification: $algoName" "INFO"
        HV-StartTimer

        $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $rs.Open()
        $ps = [System.Management.Automation.PowerShell]::Create()
        $ps.Runspace = $rs
        $ps.AddScript($Global:HV_hashScript) | Out-Null
        $ps.AddArgument($Global:HV_selectedFile) | Out-Null
        $ps.AddArgument($algoKey)                | Out-Null
        $ps.AddArgument($inputHash)              | Out-Null
        $ps.AddArgument($Global:HV_msgQueue)     | Out-Null
        $ps.BeginInvoke() | Out-Null
    })

    $Global:HV_reset.Add_Click({
        if ($Global:HV_timer -ne $null) { $Global:HV_timer.Stop() }
        $Global:HV_selectedFile           = ""
        $Global:HV_pathLbl.Text           = "No file selected..."
        $Global:HV_pathLbl.Foreground     = $Global:PTS_Brush["TextFaint"]
        $Global:HV_expected.Text          = ""
        $Global:HV_logBox.Text            = $Global:HV_initText
        $Global:HV_logBox.Foreground      = $Global:PTS_Brush["TextMuted"]
        $Global:HV_progress.Value         = 0
        $Global:HV_pctLabel.Text          = ""
        $Global:HV_statusLabel.Text       = "Idle"
        $Global:HV_statusLabel.Foreground  = $Global:PTS_Brush["TextMuted"]
        HV-UpdateVerify
    })

    $Global:HV_clearLog.Add_Click({
        $Global:HV_logBox.Text       = ""
        $Global:HV_logBox.Foreground = $Global:PTS_Brush["TextMuted"]
        HV-AddLog "Log cleared." "INFO"
    })

    return $view
}
