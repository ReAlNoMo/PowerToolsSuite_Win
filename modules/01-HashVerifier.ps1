# Module: Hash Verifier
# Computes and compares file hashes across multiple algorithms.

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
            <Border Grid.Column="0" Background="#FFFFFF" BorderBrush="#D0D6F0"
                    BorderThickness="1.5" CornerRadius="8" Margin="0,0,8,0" Height="40">
                <TextBlock x:Name="FilePathLabel" Text="No file selected..."
                           Foreground="#B0B8D8" FontSize="12"
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
                 Background="#FFFFFF" Foreground="#111827"
                 BorderBrush="#D0D6F0" BorderThickness="1.5"
                 FontFamily="Cascadia Code, Consolas, Courier New"
                 VerticalContentAlignment="Center"/>
    </StackPanel>

    <Button Grid.Row="3" x:Name="VerifyBtn" Content="Verify Hash"
            Style="{DynamicResource PrimaryButton}" Height="46"
            FontSize="14" IsEnabled="False" Margin="0,6,0,0"/>

    <Grid Grid.Row="4" Margin="0,20,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" VerticalAlignment="Center"/>
        <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="5" Background="#FAFBFF" BorderBrush="#D8DEFA"
            BorderThickness="1.5" CornerRadius="10">
        <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
            <TextBlock x:Name="LogBox" Foreground="#8890B8"
                       FontFamily="Cascadia Code, Consolas, Courier New"
                       FontSize="12" Padding="16,14" TextWrapping="Wrap"
                       LineHeight="20"
                       Text="Ready. Select a file and enter a hash value."/>
        </ScrollViewer>
    </Border>
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    # Inherit styles from main window
    $view.Resources.MergedDictionaries.Clear()
    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $script:HV_algo         = $view.FindName("AlgoCombo")
    $script:HV_browse       = $view.FindName("BrowseBtn")
    $script:HV_pathLbl      = $view.FindName("FilePathLabel")
    $script:HV_expected     = $view.FindName("ExpectedHashBox")
    $script:HV_verify       = $view.FindName("VerifyBtn")
    $script:HV_reset        = $view.FindName("ResetBtn")
    $script:HV_clearLog     = $view.FindName("ClearLogBtn")
    $script:HV_logBox       = $view.FindName("LogBox")
    $script:HV_logScroller  = $view.FindName("LogScroller")
    $script:HV_selectedFile = ""
    $script:HV_initText     = "Ready. Select a file and enter a hash value."

    function Global:HV-UpdateVerify {
        $script:HV_verify.IsEnabled = ($script:HV_selectedFile -ne "") -and ($script:HV_expected.Text.Trim() -ne "")
    }

    function Global:HV-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) {
            "OK"   { "[OK]  " }  "FAIL" { "[FAIL]" }
            "WARN" { "[WARN]" }  "HASH" { "[HASH]" }
            default { "[INFO]" }
        }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:HV_logBox.Text -eq $script:HV_initText) { $script:HV_logBox.Text = $entry }
        else { $script:HV_logBox.Text += $entry }
        $script:HV_logScroller.Dispatcher.Invoke([action]{ $script:HV_logScroller.ScrollToEnd() })
    }

    $script:HV_browse.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Title  = "Select a file"
        $ofd.Filter = "All Files (*.*)|*.*"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $script:HV_selectedFile     = $ofd.FileName
            $script:HV_pathLbl.Text     = $ofd.FileName
            $script:HV_pathLbl.Foreground = Get-PowerToolsBrush "TextDark"
            $script:HV_logBox.Foreground  = Get-PowerToolsBrush "TextMuted"
            HV-AddLog "File loaded: $($ofd.SafeFileName)" "INFO"
            HV-UpdateVerify
        }
    })

    $script:HV_expected.Add_TextChanged({ HV-UpdateVerify })
    $script:HV_algo.Add_SelectionChanged({ HV-UpdateVerify })

    $script:HV_verify.Add_Click({
        if ($script:HV_selectedFile -eq "" -or -not (Test-Path -LiteralPath $script:HV_selectedFile)) {
            HV-AddLog "Error: No valid file selected." "WARN"; return
        }
        $input = $script:HV_expected.Text.Trim().ToUpper()
        if ($input -eq "") { HV-AddLog "Error: No hash value entered." "WARN"; return }

        $algoName = $script:HV_algo.Text
        $algoKey = switch ($algoName) {
            "SHA-256" { "SHA256" } "SHA-512" { "SHA512" } "SHA-384" { "SHA384" }
            "SHA-1"   { "SHA1"   } "MD5"     { "MD5"    } default   { "SHA256" }
        }

        HV-AddLog "Starting verification with algorithm: $algoName" "INFO"
        try {
            $fi = Get-Item -LiteralPath $script:HV_selectedFile
            $sz = [math]::Round($fi.Length / 1024, 2)
            HV-AddLog "File: $($fi.Name)  ($sz KB)" "INFO"

            $computed = (Get-FileHash -Path $script:HV_selectedFile -Algorithm $algoKey).Hash
            HV-AddLog "Computed : $computed" "HASH"
            HV-AddLog "Expected : $input"    "HASH"

            if ($computed -eq $input) {
                HV-AddLog "RESULT: HASH VALUES MATCH  [PASS]" "OK"
                $script:HV_logBox.Foreground = Get-PowerToolsBrush "Success"
            } else {
                HV-AddLog "RESULT: HASH VALUES DO NOT MATCH  [FAIL]" "FAIL"
                $script:HV_logBox.Foreground = Get-PowerToolsBrush "Danger"
            }
        } catch {
            HV-AddLog "Error processing file: $_" "WARN"
        }
    })

    $script:HV_reset.Add_Click({
        $script:HV_selectedFile      = ""
        $script:HV_pathLbl.Text      = "No file selected..."
        $script:HV_pathLbl.Foreground = Get-PowerToolsBrush "TextFaint"
        $script:HV_expected.Text     = ""
        $script:HV_logBox.Text       = $script:HV_initText
        $script:HV_logBox.Foreground = Get-PowerToolsBrush "TextMuted"
        HV-UpdateVerify
        HV-AddLog "Form reset." "INFO"
    })

    $script:HV_clearLog.Add_Click({
        $script:HV_logBox.Text = ""
        $script:HV_logBox.Foreground = Get-PowerToolsBrush "TextMuted"
        HV-AddLog "Log cleared." "INFO"
    })

    return $view
}
