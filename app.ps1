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
        Title="Windows Tweaker" Height="780" Width="850"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#F5F5F5" FontFamily="Segoe UI" x:Name="MainWindow">

    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard>
                <Storyboard>
                    <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.4"/>
                    <ThicknessAnimation Storyboard.TargetProperty="Margin" From="0,20,0,-20" To="0" Duration="0:0:0.4" DecelerationRatio="0.9"/>
                </Storyboard>
            </BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <Window.Resources>
        <SolidColorBrush x:Key="WindowBackground" Color="#F5F5F5"/>
        <SolidColorBrush x:Key="PanelBackground" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#333333"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#777777"/>
        <SolidColorBrush x:Key="AccentColor" Color="#007ACC"/>
        <SolidColorBrush x:Key="BorderColor" Color="#DDDDDD"/>
        <SolidColorBrush x:Key="DisabledText" Color="#AAAAAA"/>

        <Style x:Key="SlideInContent" TargetType="FrameworkElement">
            <Setter Property="RenderTransform">
                <Setter.Value>
                    <TranslateTransform X="0" Y="0"/>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsVisible" Value="True">
                    <Trigger.EnterActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.3"/>
                                <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.X)" From="30" To="0" Duration="0:0:0.3" DecelerationRatio="0.7"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.EnterActions>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Grid Name="Panel">
                            <ContentPresenter x:Name="ContentSite"
                                            VerticalAlignment="Center"
                                            HorizontalAlignment="Center"
                                            ContentSource="Header"
                                            Margin="20,10,20,10"/> 
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Panel" Property="Background" Value="{DynamicResource PanelBackground}"/>
                                <Setter Property="Foreground" Value="{DynamicResource AccentColor}"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                                <Setter TargetName="Panel" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect BlurRadius="5" ShadowDepth="1" Opacity="0.1" Color="Black"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="False">
                                <Setter TargetName="Panel" Property="Background" Value="Transparent"/>
                                <Setter Property="Foreground" Value="{DynamicResource TextSecondary}"/>
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
            <Setter Property="Padding" Value="15,5,15,15"/>
            <Setter Property="BorderBrush" Value="{DynamicResource BorderColor}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Background" Value="{DynamicResource PanelBackground}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="GroupBox">
                        <Border BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Background="{TemplateBinding Background}"
                                CornerRadius="4">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <Border Grid.Row="0" Padding="15,12,15,5">
                                    <ContentPresenter ContentSource="Header" RecognizesAccessKey="True">
                                        <ContentPresenter.Resources>
                                            <Style TargetType="TextBlock">
                                                <Setter Property="FontWeight" Value="SemiBold"/>
                                                <Setter Property="Foreground" Value="{DynamicResource AccentColor}"/>
                                                <Setter Property="FontSize" Value="13"/>
                                            </Style>
                                        </ContentPresenter.Resources>
                                    </ContentPresenter>
                                </Border>
                                <ContentPresenter Grid.Row="1" Margin="{TemplateBinding Padding}"/>
                            </Grid>
                        </Border>
                    </ControlTemplate>
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
            <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
            <Setter Property="RenderTransform">
                <Setter.Value>
                    <ScaleTransform ScaleX="1" ScaleY="1"/>
                </Setter.Value>
            </Setter>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="3">
                            <Border.Effect>
                                <DropShadowEffect x:Name="shadow" BlurRadius="15" ShadowDepth="3" Opacity="0" Color="#005A9E"/>
                            </Border.Effect>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Trigger.EnterActions>
                                    <BeginStoryboard>
                                        <Storyboard>
                                            <DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleX" To="1.05" Duration="0:0:0.1"/>
                                            <DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleY" To="1.05" Duration="0:0:0.1"/>
                                            <DoubleAnimation Storyboard.TargetName="shadow" Storyboard.TargetProperty="Opacity" To="0.4" Duration="0:0:0.2"/>
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.EnterActions>
                                <Trigger.ExitActions>
                                    <BeginStoryboard>
                                        <Storyboard>
                                            <DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleX" To="1.0" Duration="0:0:0.1"/>
                                            <DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleY" To="1.0" Duration="0:0:0.1"/>
                                            <DoubleAnimation Storyboard.TargetName="shadow" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.2"/>
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.ExitActions>
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
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Foreground" Value="{DynamicResource DisabledText}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style TargetType="Expander">
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource BorderColor}"/>
            <Setter Property="Background" Value="{DynamicResource PanelBackground}"/>
        </Style>

        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Margin" Value="0,5"/>
            <Setter Property="Width" Value="200"/>
            <Setter Property="HorizontalAlignment" Value="Left"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>    <RowDefinition Height="Auto"/> </Grid.RowDefinitions>

        <TabControl Grid.Row="0" Background="Transparent" BorderThickness="0" Margin="10,15,10,0">
            
            <TabItem Header="Tweaks">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20" Style="{StaticResource SlideInContent}">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="20"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <GroupBox Header="Essentials" Grid.Column="0" VerticalAlignment="Top">
                                <StackPanel>
                                    <CheckBox x:Name="ChkTelemetry" Content="Disable Telemetry" IsChecked="True"/>
                                    <CheckBox x:Name="ChkActivity" Content="Disable Activity History" IsChecked="True"/>
                                    <CheckBox x:Name="ChkBackgroundApps" Content="Disable Background Apps"/>
                                    <CheckBox x:Name="ChkCopilot" Content="Disable Microsoft Copilot"/>
                                    <CheckBox x:Name="ChkRecall" Content="Disable Windows Recall (AI)"/>
                                    <CheckBox x:Name="ChkOneDrive" Content="Remove OneDrive"/>
                                    <CheckBox x:Name="ChkUltPerf" Content="Enable Ultimate Performance Plan"/>
                                </StackPanel>
                            </GroupBox>

                            <GroupBox Header="Miscellaneous" Grid.Column="2" VerticalAlignment="Top">
                                <StackPanel>
                                    <CheckBox x:Name="ChkMouseAccel" Content="Disable Mouse Acceleration"/>
                                    <CheckBox x:Name="ChkLocation" Content="Disable Location Tracking"/>
                                    <CheckBox x:Name="ChkHomeGroup" Content="Disable HomeGroup"/>
                                    <CheckBox x:Name="ChkSticky" Content="Disable Sticky Keys"/>
                                    <CheckBox x:Name="ChkHiddenFiles" Content="Show Hidden Files &amp; Extensions"/>
                                    <CheckBox x:Name="ChkDisableBing" Content="Disable Bing Search in Start"/>
                                    <CheckBox x:Name="ChkClassicContext" Content="Restore Classic Context Menu"/>
                                    <CheckBox x:Name="ChkNagle" Content="Disable Nagle's Algorithm (Latency)"/>
                                    <CheckBox x:Name="ChkFlushDNS" Content="Flush DNS Cache"/>
                                </StackPanel>
                            </GroupBox>
                        </Grid>

                        <GroupBox Header="Advanced" Margin="0,20,0,0">
                            <StackPanel>
                                <TextBlock Text="Requires safety override" Foreground="#D32F2F" FontSize="11" Margin="0,0,0,10" FontStyle="Italic"/>
                                <CheckBox x:Name="ChkRemoveEdge" Content="Remove Microsoft Edge" IsEnabled="False"/>
                                <CheckBox x:Name="ChkTrackingAggressive" Content="Remove Tracking Services" IsEnabled="False"/>
                                <CheckBox x:Name="ChkIntelMM" Content="Disable Intel Management Engine (MM)" IsEnabled="False"/>
                                <CheckBox x:Name="ChkDisableUAC" Content="Disable UAC" IsEnabled="False"/>
                                <CheckBox x:Name="ChkDisableNotif" Content="Disable Notification Center" IsEnabled="False"/>
                            </StackPanel>
                        </GroupBox>

                        <Grid Margin="0,15,0,0">
                            <Button x:Name="BtnUndoTweaks" Content="Restore Selected" HorizontalAlignment="Left" Background="#555555"/>
                            <Button x:Name="BtnApplyTweaks" Content="Apply Tweaks" HorizontalAlignment="Right"/>
                        </Grid>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Debloat">
                <Grid Margin="20" Style="{StaticResource SlideInContent}">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <GroupBox Header="Select System Packages to Remove:" Grid.Row="0" Margin="0,0,0,10">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="AppListStack" />
                        </ScrollViewer>
                    </GroupBox>

                    <Expander Grid.Row="1" Header="Game DLCs &amp; Add-ons" Margin="0,0,0,10" IsExpanded="False">
                        <Border BorderBrush="{DynamicResource BorderColor}" BorderThickness="1" CornerRadius="4" Padding="10" Background="{DynamicResource PanelBackground}"
                                RenderTransformOrigin="0.5,0">
                            <Border.RenderTransform>
                                <TransformGroup>
                                    <ScaleTransform/>
                                    <TranslateTransform/>
                                </TransformGroup>
                            </Border.RenderTransform>
                            <Border.Style>
                                <Style TargetType="Border">
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding IsExpanded, RelativeSource={RelativeSource AncestorType=Expander}}" Value="True">
                                            <DataTrigger.EnterActions>
                                                <BeginStoryboard>
                                                    <Storyboard>
                                                        <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.3"/>
                                                        <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.Y)" From="-10" To="0" Duration="0:0:0.3"/>
                                                    </Storyboard>
                                                </BeginStoryboard>
                                            </DataTrigger.EnterActions>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </Border.Style>
                            
                             <ScrollViewer VerticalScrollBarVisibility="Auto" MaxHeight="150">
                                <StackPanel x:Name="DlcListStack" />
                            </ScrollViewer>
                        </Border>
                    </Expander>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,5,0,0">
                        <Button x:Name="BtnRefreshApps" Content="Refresh" Background="#666"/>
                        <Button x:Name="BtnRemoveApps" Content="Debloat Selected" Background="#C62828"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="Config">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20" Style="{StaticResource SlideInContent}">
                        <GroupBox Header="General" Margin="0,0,0,15">
                            <StackPanel>
                                <TextBlock Text="Interface Theme:" Margin="0,0,0,5"/>
                                <ComboBox x:Name="CmbTheme" SelectedIndex="0">
                                    <ComboBoxItem Content="System (Auto)"/>
                                    <ComboBoxItem Content="Light"/>
                                    <ComboBoxItem Content="Dark"/>
                                </ComboBox>
                            </StackPanel>
                        </GroupBox>

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
        
        <TextBlock Grid.Row="0" Text="Welcome, $username" 
                   HorizontalAlignment="Right" 
                   VerticalAlignment="Top" 
                   Margin="0,25,20,0" 
                   FontSize="14" 
                   Panel.ZIndex="5"
                   Foreground="{DynamicResource TextSecondary}" 
                   FontWeight="SemiBold"/>

        <ProgressBar x:Name="MainProgressBar" Grid.Row="1" Height="4" Margin="0,5,0,0" Visibility="Hidden" 
                     Background="Transparent" BorderThickness="0" Foreground="{DynamicResource AccentColor}" 
                     IsIndeterminate="True"/>
                   
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

# --- Find Controls ---
$appListStack = $window.FindName("AppListStack")
$dlcListStack = $window.FindName("DlcListStack")
$btnRemoveApps = $window.FindName("BtnRemoveApps")
$btnRefreshApps = $window.FindName("BtnRefreshApps")
$mainProgressBar = $window.FindName("MainProgressBar")
$chkAllowUnsafeSettings = $window.FindName("ChkAllowUnsafeSettings")
$btnApplyTweaks = $window.FindName("BtnApplyTweaks")
$btnUndoTweaks = $window.FindName("BtnUndoTweaks")
$cmbTheme = $window.FindName("CmbTheme")
$mainWindow = $window.FindName("MainWindow")

# Checkboxes - Essentials
$chkTelemetry = $window.FindName("ChkTelemetry")
$chkActivity = $window.FindName("ChkActivity")
$chkBackgroundApps = $window.FindName("ChkBackgroundApps")
$chkCopilot = $window.FindName("ChkCopilot")
$chkRecall = $window.FindName("ChkRecall")
$chkOneDrive = $window.FindName("ChkOneDrive")
$chkUltPerf = $window.FindName("ChkUltPerf")

# Checkboxes - Misc
$chkMouseAccel = $window.FindName("ChkMouseAccel")
$chkLocation = $window.FindName("ChkLocation")
$chkHomeGroup = $window.FindName("ChkHomeGroup")
$chkSticky = $window.FindName("ChkSticky")
$chkHiddenFiles = $window.FindName("ChkHiddenFiles")
$chkDisableBing = $window.FindName("ChkDisableBing")
$chkClassicContext = $window.FindName("ChkClassicContext")
$chkNagle = $window.FindName("ChkNagle")
$chkFlushDNS = $window.FindName("ChkFlushDNS")

# Checkboxes - Advanced
$chkRemoveEdge = $window.FindName("ChkRemoveEdge")
$chkTrackingAggressive = $window.FindName("ChkTrackingAggressive")
$chkIntelMM = $window.FindName("ChkIntelMM")
$chkDisableUAC = $window.FindName("ChkDisableUAC")
$chkDisableNotif = $window.FindName("ChkDisableNotif")

$advancedTweaksList = @($chkRemoveEdge, $chkTrackingAggressive, $chkIntelMM, $chkDisableUAC, $chkDisableNotif)



function Set-Theme {
    param([string]$Mode)

    $converter = New-Object System.Windows.Media.BrushConverter

    if ($Mode -eq "Dark") {
        $mainWindow.Resources["WindowBackground"] = $converter.ConvertFromString("#1E1E1E")
        $mainWindow.Resources["PanelBackground"] = $converter.ConvertFromString("#2D2D30")
        $mainWindow.Resources["TextPrimary"] = $converter.ConvertFromString("#FFFFFF")
        $mainWindow.Resources["TextSecondary"] = $converter.ConvertFromString("#AAAAAA")
        $mainWindow.Resources["BorderColor"] = $converter.ConvertFromString("#3E3E42")
        $mainWindow.Resources["DisabledText"] = $converter.ConvertFromString("#555555")
        $mainWindow.Background = $mainWindow.Resources["WindowBackground"]
    }
    else {
        $mainWindow.Resources["WindowBackground"] = $converter.ConvertFromString("#F5F5F5")
        $mainWindow.Resources["PanelBackground"] = $converter.ConvertFromString("#FFFFFF")
        $mainWindow.Resources["TextPrimary"] = $converter.ConvertFromString("#333333")
        $mainWindow.Resources["TextSecondary"] = $converter.ConvertFromString("#777777")
        $mainWindow.Resources["BorderColor"] = $converter.ConvertFromString("#DDDDDD")
        $mainWindow.Resources["DisabledText"] = $converter.ConvertFromString("#AAAAAA")
        $mainWindow.Background = $mainWindow.Resources["WindowBackground"]
    }
}

function Check-SystemTheme {
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $val = Get-ItemProperty -Path $regPath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
        if ($val -and $val.AppsUseLightTheme -eq 0) { return "Dark" }
        return "Light"
    }
    catch { return "Light" }
}

$cmbTheme.Add_SelectionChanged({
        $selected = $cmbTheme.SelectedItem.Content
        if ($selected -eq "System (Auto)") {
            $sysMode = Check-SystemTheme
            Set-Theme -Mode $sysMode
        }
        elseif ($selected -eq "Dark") {
            Set-Theme -Mode "Dark"
        }
        else {
            Set-Theme -Mode "Light"
        }
        if ($appListStack.Children.Count -gt 0) { Update-SafetySettings }
    })

$cmbTheme.SelectedIndex = 0
$sysMode = Check-SystemTheme
Set-Theme -Mode $sysMode



function Set-RegKey {
    param([string]$Path, [string]$Name, [string]$Value, [string]$PropertyType = "DWord")
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force | Out-Null
}

# Same as Set-RegKey but removes the property or sets default
function Remove-RegKey {
    param([string]$Path, [string]$Name)
    if (Test-Path $Path) {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    }
}

function Disable-WinService {
    param([string]$ServiceName)
    if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

function Enable-WinService {
    param([string]$ServiceName)
    if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
        Set-Service -Name $ServiceName -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    }
}


function Update-SafetySettings {
    $allowUnsafe = $chkAllowUnsafeSettings.IsChecked
    $converter = New-Object System.Windows.Media.BrushConverter

    foreach ($chk in $advancedTweaksList) {
        $chk.IsEnabled = $allowUnsafe
        if (-not $allowUnsafe) { $chk.IsChecked = $false }
    }
    
    function Update-ListColors($stack) {
        foreach ($element in $stack.Children) {
            if ($element.GetType().Name -eq "CheckBox") {
                $pkgRawName = $element.Tag.Name
                if (Is-CriticalApp $pkgRawName) {
                    if ($allowUnsafe) {
                        $element.IsEnabled = $true; $element.Opacity = 1.0
                        if ($cmbTheme.SelectedItem.Content -eq "Dark") { $element.Foreground = $converter.ConvertFromString("#FF6B6B") }
                        else { $element.Foreground = $converter.ConvertFromString("#D32F2F") }
                    }
                    else {
                        $element.IsEnabled = $false; $element.IsChecked = $false; $element.Opacity = 0.6
                        $element.Foreground = $mainWindow.Resources["DisabledText"]
                    }
                }
                else {
                    $element.Foreground = $mainWindow.Resources["TextPrimary"]
                }
            }
        }
    }
    Update-ListColors $appListStack
    Update-ListColors $dlcListStack
}

$chkAllowUnsafeSettings.Add_Checked({ Update-SafetySettings })
$chkAllowUnsafeSettings.Add_Unchecked({ Update-SafetySettings })


$btnApplyTweaks.Add_Click({
        $btnApplyTweaks.IsEnabled = $false
        $btnUndoTweaks.IsEnabled = $false
        $mainProgressBar.Visibility = "Visible"
        $btnApplyTweaks.Content = "Applying..."
    
        $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)

        if ($chkTelemetry.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0; Disable-WinService "DiagTrack"; Disable-WinService "dmwappushservice" }
        if ($chkActivity.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0; Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 }
    
        if ($chkBackgroundApps.IsChecked) { 
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Value 2 
        }
    
        if ($chkCopilot.IsChecked) { 
            Set-RegKey -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 
        }
    
        if ($chkRecall.IsChecked) { 
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1 
        }

        if ($chkOneDrive.IsChecked) { 
            $os = if ([Environment]::Is64BitOperatingSystem) { "SysWOW64" } else { "System32" }
            $setup = "$env:SystemRoot\$os\OneDriveSetup.exe"
            if (Test-Path $setup) { Start-Process $setup -ArgumentList "/uninstall" -NoNewWindow -Wait }
            Set-RegKey -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 
        }
    
        if ($chkUltPerf.IsChecked) {
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        }

        if ($chkMouseAccel.IsChecked) { 
            Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -PropertyType String 
            Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -PropertyType String 
            Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -PropertyType String 
        }
    
        if ($chkLocation.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "AllowLocation" -Value 0; Disable-WinService "lfsvc" }
        if ($chkHomeGroup.IsChecked) { Disable-WinService "HomeGroupListener"; Disable-WinService "HomeGroupProvider" }
        if ($chkSticky.IsChecked) { Set-RegKey -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -PropertyType "String" }
        if ($chkHiddenFiles.IsChecked) { Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1; Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 }
        if ($chkDisableBing.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1; Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 }
    
        if ($chkClassicContext.IsChecked) {
            Set-RegKey -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -PropertyType String
        }
    
        if ($chkNagle.IsChecked) {
            $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            foreach ($iface in $interfaces) {
                Set-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $iface.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            }
        }
    
        if ($chkFlushDNS.IsChecked) {
            Clear-DnsClientCache
        }

        if ($chkRemoveEdge.IsChecked) { Get-AppxPackage *Edge* | Remove-AppxPackage -ErrorAction SilentlyContinue; Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" -Name "DoNotUpdateToEdgeWithChromium" -Value 1 }
        if ($chkTrackingAggressive.IsChecked) { Disable-WinService "WerSvc"; Disable-WinService "PcaSvc" }
        if ($chkIntelMM.IsChecked) { Disable-WinService "LMS" }
        if ($chkDisableUAC.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 }
        if ($chkDisableNotif.IsChecked) { if (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null }; Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -Force }

        Start-Sleep -Seconds 1
    
        $mainProgressBar.Visibility = "Hidden"
        [System.Windows.MessageBox]::Show("The selected tweaks have been applied.", "Success")
        $btnApplyTweaks.Content = "Apply Tweaks"; $btnApplyTweaks.IsEnabled = $true; $btnUndoTweaks.IsEnabled = $true
    })



$btnUndoTweaks.Add_Click({
        $btnApplyTweaks.IsEnabled = $false
        $btnUndoTweaks.IsEnabled = $false
        $mainProgressBar.Visibility = "Visible"
        $btnUndoTweaks.Content = "Restoring..."
    
        $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)

        if ($chkTelemetry.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 1; Enable-WinService "DiagTrack"; Enable-WinService "dmwappushservice" }
        if ($chkActivity.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 1; Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 1 }
    
        if ($chkBackgroundApps.IsChecked) { 
            Remove-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled"
            Remove-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground"
        }
    
        if ($chkCopilot.IsChecked) { 
            Set-RegKey -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 0 
        }
    
        if ($chkRecall.IsChecked) { 
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 0 
        }

        if ($chkMouseAccel.IsChecked) { 
            Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1" -PropertyType String 
            Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "6" -PropertyType String 
            Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "10" -PropertyType String 
        }
    
        if ($chkLocation.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "AllowLocation" -Value 1; Enable-WinService "lfsvc" }
        if ($chkHomeGroup.IsChecked) { Enable-WinService "HomeGroupListener"; Enable-WinService "HomeGroupProvider" }
        if ($chkSticky.IsChecked) { Set-RegKey -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "510" -PropertyType "String" }
        if ($chkHiddenFiles.IsChecked) { Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2; Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 }
        if ($chkDisableBing.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 0; Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 1 }
    
        if ($chkClassicContext.IsChecked) {
            if (Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}") {
                Remove-Item "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force
            }
        }
    
        if ($chkNagle.IsChecked) {
            $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            foreach ($iface in $interfaces) {
                Remove-RegKey -Path $iface.PSPath -Name "TcpAckFrequency"
                Remove-RegKey -Path $iface.PSPath -Name "TCPNoDelay"
            }
        }

        if ($chkTrackingAggressive.IsChecked) { Enable-WinService "WerSvc"; Enable-WinService "PcaSvc" }
        if ($chkIntelMM.IsChecked) { Enable-WinService "LMS" }
        if ($chkDisableUAC.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 }
        if ($chkDisableNotif.IsChecked) { Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 0 -Type DWord -Force }

        Start-Sleep -Seconds 1
    
        $mainProgressBar.Visibility = "Hidden"
        [System.Windows.MessageBox]::Show("Selected tweaks have been restored to default values.", "Restore Complete")
        $btnUndoTweaks.Content = "Restore Selected"; $btnApplyTweaks.IsEnabled = $true; $btnUndoTweaks.IsEnabled = $true
    })


$criticalApps = @("Microsoft.WindowsStore", "Microsoft.StorePurchaseApp", "Microsoft.DesktopAppInstaller", "Microsoft.Services.Store.Engagement", "Microsoft.XboxApp", "Microsoft.XboxIdentityProvider", "Microsoft.XboxGamingOverlay")

function Is-CriticalApp($appName) { if ([string]::IsNullOrEmpty($appName)) { return $false }; return ($criticalApps -contains $appName) }
function Get-CleanAppName($rawName) { if (-not $rawName) { return "Unknown App" }; $clean = $rawName -replace "^Microsoft\.", "" -replace "^Windows\.", "" -replace "\.", " "; return $clean }

function Load-StoreApps {
    $appListStack.Children.Clear()
    $dlcListStack.Children.Clear()
    
    $loadingText = New-Object System.Windows.Controls.TextBlock
    $loadingText.Text = "Loading packages..."
    $loadingText.Foreground = $mainWindow.Resources["DisabledText"]; $loadingText.HorizontalAlignment = "Center"
    [void]$appListStack.Children.Add($loadingText)
    $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    
    $apps = Get-AppxPackage | Where-Object { $_.IsFramework -eq $false -and $_.NonRemovable -eq $false -and $_.SignatureKind -ne "System" -and $_.Name -notlike "*Edge*" } | Sort-Object Name
    $appListStack.Children.Clear()

    if ($apps.Count -eq 0) { $msg = New-Object System.Windows.Controls.TextBlock; $msg.Text = "No removable packages found."; [void]$appListStack.Children.Add($msg); return }

    foreach ($app in $apps) {
        $chk = New-Object System.Windows.Controls.CheckBox
        $chk.Content = Get-CleanAppName $app.Name
        $chk.Tag = @{ FullName = $app.PackageFullName; Name = $app.Name }
        $chk.Margin = "0,3,0,3"
        
        if (Is-CriticalApp $app.Name) { $chk.Foreground = $mainWindow.Resources["DisabledText"]; $chk.IsEnabled = $false }
        else { $chk.Foreground = $mainWindow.Resources["TextPrimary"] }

        if ($app.Name -match "^\d") { [void]$dlcListStack.Children.Add($chk) }
        else { [void]$appListStack.Children.Add($chk) }
    }
    
    if ($dlcListStack.Children.Count -eq 0) {
        $msg = New-Object System.Windows.Controls.TextBlock; $msg.Text = "No DLC packages found."; 
        $msg.Foreground = $mainWindow.Resources["DisabledText"]
        [void]$dlcListStack.Children.Add($msg)
    }
    Update-SafetySettings
}

$btnRefreshApps.Add_Click({ Load-StoreApps })
$btnRemoveApps.Add_Click({
        $appsToRemove = ($appListStack.Children + $dlcListStack.Children) | Where-Object { $_.GetType().Name -eq "CheckBox" -and $_.IsChecked }
        if ($appsToRemove.Count -eq 0) { [System.Windows.MessageBox]::Show("Please select at least one package."); return }
        $confirm = [System.Windows.MessageBox]::Show("Remove $($appsToRemove.Count) packages?", "Confirm", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($confirm -eq 'Yes') {
            $mainProgressBar.Visibility = "Visible"
            $btnRemoveApps.IsEnabled = $false
            foreach ($chk in $appsToRemove) {
                $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
                try { 
                    Remove-AppxPackage -Package $chk.Tag.FullName -ErrorAction Stop; 
                    if ($appListStack.Children.Contains($chk)) { [void]$appListStack.Children.Remove($chk) }
                    if ($dlcListStack.Children.Contains($chk)) { [void]$dlcListStack.Children.Remove($chk) }
                }
                catch { $chk.Foreground = "Orange"; $chk.IsChecked = $false }
            }
            $mainProgressBar.Visibility = "Hidden"
            $btnRemoveApps.IsEnabled = $true; [System.Windows.MessageBox]::Show("Debloat process completed.")
        }
    })

Load-StoreApps

$window.ShowDialog() | Out-Null