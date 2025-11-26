# Auto-elevate to Admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $processInfo.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($processInfo) | Out-Null
    }
    catch {
        Write-Warning "User declined elevation."
    }
    exit
}

Add-Type -AssemblyName PresentationFramework | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

$username = $env:USERNAME

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Optimizations" Height="650" Width="850"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#F5F5F5" FontFamily="Segoe UI">

    <Window.Resources>
        <Style TargetType="TabItem">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Grid Name="Panel">
                            <ContentPresenter x:Name="ContentSite"
                                            VerticalAlignment="Center"
                                            HorizontalAlignment="Center"
                                            ContentSource="Header"
                                            Margin="20,12"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Panel" Property="Background" Value="#FFFFFF"/>
                                <Setter Property="Foreground" Value="#007ACC"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                                <Setter TargetName="Panel" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect BlurRadius="5" ShadowDepth="1" Opacity="0.1" Color="Black"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="False">
                                <Setter TargetName="Panel" Property="Background" Value="Transparent"/>
                                <Setter Property="Foreground" Value="#777777"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="#005A9E"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style TargetType="GroupBox">
            <Setter Property="Padding" Value="15"/>
            <Setter Property="BorderBrush" Value="#DDDDDD"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Background" Value="White"/>
            <Setter Property="HeaderTemplate">
                <Setter.Value>
                    <DataTemplate>
                        <TextBlock Text="{Binding}" FontWeight="SemiBold" Foreground="#007ACC" Margin="5,0,5,0"/>
                    </DataTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Background">
                <Setter.Value>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                        <GradientStop Color="#007ACC" Offset="0"/>
                        <GradientStop Color="#005A9E" Offset="1"/>
                    </LinearGradientBrush>
                </Setter.Value>
            </Setter>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="30,10"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="3">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect BlurRadius="15" ShadowDepth="3" Opacity="0.4" Color="#005A9E"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="#CCCCCC"/>
                                <Setter Property="Foreground" Value="#888888"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="0,4"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Foreground" Value="#444"/>
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Foreground" Value="#AAAAAA"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#333"/>
        </Style>
    </Window.Resources>

    <Grid>
        <TabControl Background="Transparent" BorderThickness="0" Margin="10,10,10,10">
            
            <TabItem Header="Tweaks">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20">
                    
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="20"/> <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <GroupBox Header="Essentials" Grid.Column="0" VerticalAlignment="Top">
                                <StackPanel>
                                    <CheckBox x:Name="ChkTelemetry" Content="Disable Telemetry" IsChecked="True"/>
                                    <CheckBox x:Name="ChkActivity" Content="Disable Activity History" IsChecked="True"/>
                                    <CheckBox x:Name="ChkLocation" Content="Disable Location Tracking"/>
                                    <CheckBox x:Name="ChkHomeGroup" Content="Disable HomeGroup"/>
                                    <CheckBox x:Name="ChkOneDrive" Content="Remove OneDrive"/>
                                </StackPanel>
                            </GroupBox>

                            <GroupBox Header="Miscellaneous" Grid.Column="2" VerticalAlignment="Top">
                                <StackPanel>
                                    <CheckBox x:Name="ChkSticky" Content="Disable Sticky Keys"/>
                                    <CheckBox x:Name="ChkHiddenFiles" Content="Show Hidden Files &amp; Extensions"/>
                                    <CheckBox x:Name="ChkDisableBing" Content="Disable Bing Search in Start"/>
                                </StackPanel>
                            </GroupBox>
                        </Grid>

                        <GroupBox Header="Advanced" Margin="0,20,0,0">
                            <StackPanel>
                                <TextBlock Text="Requires safety override" Foreground="#D32F2F" FontSize="11" Margin="0,0,0,10" FontStyle="Italic"/>
                                <CheckBox x:Name="ChkRemoveEdge" Content="Remove Microsoft Edge" IsEnabled="False"/>
                                <CheckBox x:Name="ChkTrackingAggressive" Content="Remove Tracking Services" IsEnabled="False"/>
                                <CheckBox x:Name="ChkDisableUAC" Content="Disable UAC" IsEnabled="False"/>
                                <CheckBox x:Name="ChkDisableNotif" Content="Disable Notification Center" IsEnabled="False"/>
                            </StackPanel>
                        </GroupBox>

                        <Button x:Name="BtnApplyTweaks" Content="Apply Tweaks" HorizontalAlignment="Right" Margin="0,15,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Packages">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20">
                        <GroupBox Header="Browsers" Margin="0,0,0,15">
                            <StackPanel>
                                <CheckBox Content="Google Chrome"/>
                                <CheckBox Content="Mozilla Firefox"/>
                                <CheckBox Content="Brave Browser"/>
                            </StackPanel>
                        </GroupBox>
                        <Button Content="Install Selected" HorizontalAlignment="Right" Margin="0,10,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Debloat">
                <Grid Margin="20">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <TextBlock Grid.Row="0" Text="Select System Packages to Remove:" FontWeight="SemiBold" Margin="0,0,0,10"/>
                    
                    <Border Grid.Row="1" BorderBrush="#DDD" BorderThickness="1" Background="White" Padding="10">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="AppListStack" />
                        </ScrollViewer>
                    </Border>

                    <StackPanel Grid.Row="2" Orientation="Vertical" Margin="0,15,0,0">
                        <ProgressBar x:Name="RemoveProgress" Height="10" Margin="5,0,5,10" Visibility="Collapsed" Background="#EEE" Foreground="#C62828"/>
                        
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                            <Button x:Name="BtnRefreshApps" Content="Refresh" Background="#666"/>
                            <Button x:Name="BtnRemoveApps" Content="Debloat Selected" Background="#C62828"/>
                        </StackPanel>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="Config">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20">
                        <GroupBox Header="Safety Override" Margin="0,0,0,15">
                            <StackPanel>
                                
                                <CheckBox x:Name="ChkAllowUnsafeSettings" 
                                          Content="Allow unsafe tweaks" 
                                          Foreground="#DAA520" 
                                          FontWeight="Bold"/>
                            </StackPanel>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

        </TabControl>
        
        <TextBlock Text="Welcome, $username" 
                   HorizontalAlignment="Right" 
                   VerticalAlignment="Top" 
                   Margin="0,15,20,0" 
                   FontSize="14" 
                   Foreground="#777" 
                   FontWeight="SemiBold"/>
                   
    </Grid>
</Window>
"@

# --- Load XAML ---
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    Write-Error "Failed to load XAML: $_"
    exit
}

# --- Find Controls ---
$appListStack = $window.FindName("AppListStack")
$btnRemoveApps = $window.FindName("BtnRemoveApps")
$btnRefreshApps = $window.FindName("BtnRefreshApps")
$progressBar = $window.FindName("RemoveProgress")
$chkAllowUnsafeSettings = $window.FindName("ChkAllowUnsafeSettings")
$btnApplyTweaks = $window.FindName("BtnApplyTweaks")

# Essential
$chkTelemetry = $window.FindName("ChkTelemetry")
$chkActivity = $window.FindName("ChkActivity")
$chkLocation = $window.FindName("ChkLocation")
$chkHomeGroup = $window.FindName("ChkHomeGroup")
$chkOneDrive = $window.FindName("ChkOneDrive")

# Miscellaneous
$chkSticky = $window.FindName("ChkSticky")
$chkHiddenFiles = $window.FindName("ChkHiddenFiles")
$chkDisableBing = $window.FindName("ChkDisableBing")

# Advanced
$chkRemoveEdge = $window.FindName("ChkRemoveEdge")
$chkTrackingAggressive = $window.FindName("ChkTrackingAggressive")
$chkDisableUAC = $window.FindName("ChkDisableUAC")
$chkDisableNotif = $window.FindName("ChkDisableNotif")

# Group the advanced checkboxes for easy toggling (Removed Cortana)
$advancedTweaksList = @($chkRemoveEdge, $chkTrackingAggressive, $chkDisableUAC, $chkDisableNotif)

# --- Helper Functions ---

function Set-RegKey {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value, # Changed to string to handle multiple types
        [string]$PropertyType = "DWord"
    )
    if (!(Test-Path $Path)) { 
        New-Item -Path $Path -Force | Out-Null 
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force | Out-Null
}

function Disable-WinService {
    param([string]$ServiceName)
    if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# --- Global Safety Toggle Logic ---
function Update-SafetySettings {
    $allowUnsafe = $chkAllowUnsafeSettings.IsChecked
    
    # 1. Toggle Advanced Tweaks
    foreach ($chk in $advancedTweaksList) {
        $chk.IsEnabled = $allowUnsafe
        if (-not $allowUnsafe) { $chk.IsChecked = $false }
    }

    # 2. Toggle Critical Apps
    foreach ($element in $appListStack.Children) {
        if ($element.GetType().Name -eq "CheckBox") {
            $pkgRawName = $element.Tag.Name
            if (Is-CriticalApp $pkgRawName) {
                if ($allowUnsafe) {
                    $element.IsEnabled = $true; $element.Foreground = "#D32F2F"; $element.Opacity = 1.0
                }
                else {
                    $element.IsEnabled = $false; $element.IsChecked = $false; $element.Foreground = "#AAAAAA"; $element.Opacity = 0.6
                }
            }
        }
    }
}

$chkAllowUnsafeSettings.Add_Checked({ Update-SafetySettings })
$chkAllowUnsafeSettings.Add_Unchecked({ Update-SafetySettings })


# --- Apply Tweaks Logic ---

$btnApplyTweaks.Add_Click({
        $btnApplyTweaks.IsEnabled = $false
        $btnApplyTweaks.Content = "Applying..."
        $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)

        # --- Essentials ---
        if ($chkTelemetry.IsChecked) {
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
            Disable-WinService "DiagTrack"
            Disable-WinService "dmwappushservice"
        }
        if ($chkActivity.IsChecked) {
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0
        }
        if ($chkLocation.IsChecked) {
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "AllowLocation" -Value 0
            Disable-WinService "lfsvc"
        }
        if ($chkHomeGroup.IsChecked) {
            Disable-WinService "HomeGroupListener"
            Disable-WinService "HomeGroupProvider"
        }
        if ($chkOneDrive.IsChecked) {
            $os = if ([Environment]::Is64BitOperatingSystem) { "SysWOW64" } else { "System32" }
            $onedriveSetup = "$env:SystemRoot\$os\OneDriveSetup.exe"
            if (Test-Path $onedriveSetup) { Start-Process $onedriveSetup -ArgumentList "/uninstall" -NoNewWindow -Wait }
            Set-RegKey -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
        }

        # --- Miscellaneous ---
        if ($chkSticky.IsChecked) {
            # Disable Sticky Keys Shortcut (Shift 5x)
            Set-RegKey -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -PropertyType "String"
        }

        if ($chkHiddenFiles.IsChecked) {
            # Show Hidden Files
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
            # Show File Extensions
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
        }

        if ($chkDisableBing.IsChecked) {
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
        }

        # --- Advanced (Aggressive) ---
        if ($chkRemoveEdge.IsChecked) {
            Get-AppxPackage *Edge* | Remove-AppxPackage -ErrorAction SilentlyContinue
            Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" -Name "DoNotUpdateToEdgeWithChromium" -Value 1
        }
        if ($chkTrackingAggressive.IsChecked) {
            Disable-WinService "WerSvc"
            Disable-WinService "PcaSvc"
        }
        if ($chkDisableUAC.IsChecked) {
            Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
        }
        if ($chkDisableNotif.IsChecked) {
            if (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null }
            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -Force
        }

        Start-Sleep -Seconds 1 
    
        [System.Windows.MessageBox]::Show("The selected tweaks have been applied.", "Success")
    
        $btnApplyTweaks.Content = "Apply Tweaks"
        $btnApplyTweaks.IsEnabled = $true
    })


# --- Debloat Logic ---

$criticalApps = @(
    "Microsoft.WindowsStore", "Microsoft.StorePurchaseApp", "Microsoft.DesktopAppInstaller",
    "Microsoft.Services.Store.Engagement", "Microsoft.XboxApp", "Microsoft.XboxIdentityProvider", "Microsoft.XboxGamingOverlay"
)

function Is-CriticalApp($appName) {
    if ([string]::IsNullOrEmpty($appName)) { return $false }
    return ($criticalApps -contains $appName)
}

function Get-CleanAppName($rawName) {
    if (-not $rawName) { return "Unknown App" }
    $clean = $rawName -replace "^Microsoft\.", "" -replace "^Windows\.", "" -replace "\.", " "
    return $clean
}

function Load-StoreApps {
    $appListStack.Children.Clear()
    $loadingText = New-Object System.Windows.Controls.TextBlock
    $loadingText.Text = "Loading packages..."
    $loadingText.Foreground = "#888"; $loadingText.HorizontalAlignment = "Center"
    [void]$appListStack.Children.Add($loadingText)
    $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    
    $apps = Get-AppxPackage | Where-Object { 
        $_.IsFramework -eq $false -and $_.NonRemovable -eq $false -and $_.SignatureKind -ne "System" -and $_.Name -notlike "*Edge*" 
    } | Sort-Object Name

    $appListStack.Children.Clear()

    if ($apps.Count -eq 0) {
        $msg = New-Object System.Windows.Controls.TextBlock; $msg.Text = "No removable packages found."; [void]$appListStack.Children.Add($msg); return
    }

    foreach ($app in $apps) {
        $chk = New-Object System.Windows.Controls.CheckBox
        $chk.Content = Get-CleanAppName $app.Name
        $chk.Tag = @{ FullName = $app.PackageFullName; Name = $app.Name }
        $chk.Margin = "0,3,0,3"
        if (Is-CriticalApp $app.Name) { 
            # Logic: No "[LOCKED]" text, just disabled state
            $chk.Foreground = "#AAAAAA"
            $chk.IsEnabled = $false 
        }
        [void]$appListStack.Children.Add($chk)
    }
    Update-SafetySettings
}

$btnRefreshApps.Add_Click({ Load-StoreApps })

$btnRemoveApps.Add_Click({
        $appsToRemove = $appListStack.Children | Where-Object { $_.GetType().Name -eq "CheckBox" -and $_.IsChecked }
        if ($appsToRemove.Count -eq 0) { [System.Windows.MessageBox]::Show("Please select at least one package."); return }
    
        $confirm = [System.Windows.MessageBox]::Show("Remove $($appsToRemove.Count) packages?", "Confirm", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($confirm -eq 'Yes') {
            $progressBar.Visibility = "Visible"; $progressBar.Maximum = $appsToRemove.Count; $progressBar.Value = 0
            $btnRemoveApps.IsEnabled = $false
        
            foreach ($chk in $appsToRemove) {
                $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
                try { Remove-AppxPackage -Package $chk.Tag.FullName -ErrorAction Stop; [void]$appListStack.Children.Remove($chk) }
                catch { $chk.Foreground = "Orange"; $chk.IsChecked = $false }
                $progressBar.Value++
            }
            $progressBar.Visibility = "Collapsed"; $btnRemoveApps.IsEnabled = $true
            [System.Windows.MessageBox]::Show("Debloat process completed.")
        }
    })

Load-StoreApps

$window.ShowDialog() | Out-Null