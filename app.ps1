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
        Title="PowerShell Manager (Power User)" Height="600" Width="800"
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
            <Setter Property="Margin" Value="0,0,0,15"/>
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
                        <GroupBox Header="System">
                            <StackPanel>
                                <CheckBox Content="Disable Background Apps"/>
                                <CheckBox Content="Disable Telemetry"/>
                                <CheckBox Content="High Performance Plan"/>
                            </StackPanel>
                        </GroupBox>
                        
                        <GroupBox Header="UI / Visuals">
                            <StackPanel>
                                <CheckBox Content="Disable Transparency"/>
                                <CheckBox Content="Disable Animations"/>
                            </StackPanel>
                        </GroupBox>

                        <Button Content="Apply Tweaks" HorizontalAlignment="Right" Margin="0,10,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Packages">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20">
                        <GroupBox Header="Browsers">
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
                        <GroupBox Header="General">
                            <StackPanel>
                                <CheckBox Content="Create Restore Point" IsChecked="True"/>
                                <CheckBox Content="Output Logs to Desktop"/>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox Header="Safety Override">
                            <StackPanel>
                                <TextBlock Text="Warning: Unlocking critical apps may result in system instability." Foreground="#888" Margin="0,0,0,10" TextWrapping="Wrap"/>
                                
                                <CheckBox x:Name="ChkAllowUnsafeSettings" 
                                          Content="Allow removal of Critical Packages" 
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

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    Write-Error "Failed to load XAML: $_"
    exit
}

$appListStack = $window.FindName("AppListStack")
$btnRemoveApps = $window.FindName("BtnRemoveApps")
$btnRefreshApps = $window.FindName("BtnRefreshApps")
$progressBar = $window.FindName("RemoveProgress")
$chkAllowUnsafeSettings = $window.FindName("ChkAllowUnsafeSettings")

# Critical system apps that should not be removed
$criticalApps = @(
    "Microsoft.WindowsStore", 
    "Microsoft.StorePurchaseApp", 
    "Microsoft.DesktopAppInstaller",
    "Microsoft.Services.Store.Engagement",
    "Microsoft.XboxApp", 
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxGamingOverlay"
)

function Is-CriticalApp($appName) {
    if ([string]::IsNullOrEmpty($appName)) { return $false }
    return ($criticalApps -contains $appName)
}

function Get-CleanAppName($rawName) {
    if (-not $rawName) { return "Unknown App" }
    
    $clean = $rawName -replace "^Microsoft\.", "" `
        -replace "^Windows\.", "" `
        -replace "\.", " "
    return $clean
}

function Update-AppListSafety {
    $allowUnsafe = $chkAllowUnsafeSettings.IsChecked
    
    foreach ($element in $appListStack.Children) {
        if ($element.GetType().Name -eq "CheckBox") {
            $pkgRawName = $element.Tag.Name
            
            if (Is-CriticalApp $pkgRawName) {
                if ($allowUnsafe) {
                    $element.IsEnabled = $true
                    $element.Foreground = "#D32F2F" 
                    $element.Content = (Get-CleanAppName $pkgRawName)
                    $element.Opacity = 1.0
                }
                else {
                    $element.IsEnabled = $false
                    $element.IsChecked = $false
                    $element.Foreground = "#AAAAAA" 
                    $element.Content = (Get-CleanAppName $pkgRawName)
                    $element.Opacity = 0.6
                }
            }
        }
    }
}

$chkAllowUnsafeSettings.Add_Checked({ Update-AppListSafety })
$chkAllowUnsafeSettings.Add_Unchecked({ Update-AppListSafety })

function Load-StoreApps {
    $appListStack.Children.Clear()
    
    $loadingText = New-Object System.Windows.Controls.TextBlock
    $loadingText.Text = "Loading packages..."
    $loadingText.Foreground = "#888"
    $loadingText.Margin = "0,10,0,0"
    $loadingText.HorizontalAlignment = "Center"
    [void]$appListStack.Children.Add($loadingText)
    
    $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    
    # Exclude Edge/WebView2 to avoid breaking system web rendering
    $apps = Get-AppxPackage | Where-Object { 
        $_.IsFramework -eq $false -and 
        $_.NonRemovable -eq $false -and 
        $_.SignatureKind -ne "System" -and
        $_.Name -notlike "*Edge*" 
    } | Sort-Object Name

    $appListStack.Children.Clear()

    if ($apps.Count -eq 0) {
        $msg = New-Object System.Windows.Controls.TextBlock
        $msg.Text = "No removable packages found."
        [void]$appListStack.Children.Add($msg)
        return
    }

    foreach ($app in $apps) {
        $chk = New-Object System.Windows.Controls.CheckBox
        
        $friendlyName = Get-CleanAppName $app.Name
        
        $chk.Content = $friendlyName
        
        $chk.Tag = @{ 
            FullName = $app.PackageFullName; 
            Name     = $app.Name 
        }
        
        $chk.ToolTip = "Package: $($app.Name)"
        $chk.Margin = "0,3,0,3"

        if (Is-CriticalApp $app.Name) {
            $chk.Foreground = "#AAAAAA"
            $chk.IsEnabled = $false 
            $chk.Content = "[LOCKED] $friendlyName"
        }

        [void]$appListStack.Children.Add($chk)
    }

    Update-AppListSafety
}

$btnRefreshApps.Add_Click({
        Load-StoreApps
    })

$btnRemoveApps.Add_Click({
        $appsToRemove = $appListStack.Children | Where-Object { $_.GetType().Name -eq "CheckBox" -and $_.IsChecked }
    
        if ($appsToRemove.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Please select at least one package to remove.")
            return
        }

        $confirmResult = [System.Windows.MessageBox]::Show("Are you sure you want to remove $($appsToRemove.Count) packages?`n`nNote: Removing critical packages may break system features.", "Confirm Debloat", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    
        if ($confirmResult -eq 'Yes') {
    
            $progressBar.Visibility = "Visible"
            $progressBar.Minimum = 0
            $progressBar.Maximum = $appsToRemove.Count
            $progressBar.Value = 0

            $btnRemoveApps.IsEnabled = $false
            $btnRefreshApps.IsEnabled = $false
            $chkAllowUnsafeSettings.IsEnabled = $false
            
            foreach ($chk in $appsToRemove) {
                $packageFullName = $chk.Tag.FullName
            
                $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
            
                try {
                    Remove-AppxPackage -Package $packageFullName -ErrorAction Stop
                
                    [void]$appListStack.Children.Remove($chk)
                }
                catch {
                    $chk.Foreground = "Orange"
                    $chk.Content = "$($chk.Content) (Failed)"
                    $chk.IsChecked = $false
                }
            
                $progressBar.Value++
            }

            $progressBar.Visibility = "Collapsed"
            $btnRemoveApps.IsEnabled = $true
            $btnRefreshApps.IsEnabled = $true
            $chkAllowUnsafeSettings.IsEnabled = $true
        
            [System.Windows.MessageBox]::Show("Debloat process completed.")
        }
    })

Load-StoreApps

$window.ShowDialog() | Out-Null