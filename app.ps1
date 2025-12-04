# Auto-elevate to Admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $processInfo.Verb = "runas"
    try { [System.Diagnostics.Process]::Start($processInfo) | Out-Null } catch {}
    exit
}

if (-not ("FluentWindow" -as [type])) {
    $code = @"
    using System;
    using System.Runtime.InteropServices;
    public class FluentWindow {
        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, int[] attrValue, int attrSize);
        private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
        public static void ForceDark(IntPtr handle) {
            int[] darkMode = new int[] { 1 };
            DwmSetWindowAttribute(handle, DWMWA_USE_IMMERSIVE_DARK_MODE, darkMode, 4);
        }
    }
"@
    Add-Type -TypeDefinition $code -Language CSharp
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Tweaker" Height="880" Width="1050"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#181818"
        FontFamily="Segoe UI Variable Display, Segoe UI"
        SnapsToDevicePixels="True" UseLayoutRounding="True"
        x:Name="MainWindow">

    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="40" GlassFrameThickness="0" CornerRadius="0" ResizeBorderThickness="0"/>
    </WindowChrome.WindowChrome>

    <Window.Resources>
        <SolidColorBrush x:Key="AppBackground" Color="#181818"/>
        <SolidColorBrush x:Key="CardFill" Color="#202020"/>
        <SolidColorBrush x:Key="CardStroke" Color="#333333"/>
        <SolidColorBrush x:Key="ControlFill" Color="#2D2D2D"/>
        <SolidColorBrush x:Key="ControlHover" Color="#383838"/>
        <SolidColorBrush x:Key="AccentFill" Color="#60CDFF"/>
        <SolidColorBrush x:Key="AccentText" Color="#101010"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#AAAAAA"/>
        <SolidColorBrush x:Key="Critical" Color="#FF453A"/>
        
        <FontFamily x:Key="IconFont">Segoe MDL2 Assets</FontFamily>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="0,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Grid Background="Transparent">
                            <Grid.ColumnDefinitions> <ColumnDefinition Width="*"/> <ColumnDefinition Width="Auto"/> </Grid.ColumnDefinitions>
                            <ContentPresenter Grid.Column="0" VerticalAlignment="Center" Content="{TemplateBinding Content}" Margin="0,0,16,0"/>
                            <Border x:Name="Pill" Grid.Column="1" Width="40" Height="20" CornerRadius="10" 
                                    Background="#333333" BorderBrush="#555555" BorderThickness="1">
                                <Grid>
                                    <Ellipse x:Name="Dot" Width="12" Height="12" Fill="#AAAAAA" 
                                             HorizontalAlignment="Left" Margin="3,0,0,0">
                                        <Ellipse.RenderTransform> <TranslateTransform X="0"/> </Ellipse.RenderTransform>
                                    </Ellipse>
                                </Grid>
                            </Border>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Pill" Property="Background" Value="#444444"/>
                                <Setter TargetName="Dot" Property="Fill" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Pill" Property="Background" Value="{DynamicResource AccentFill}"/>
                                <Setter TargetName="Pill" Property="BorderThickness" Value="0"/>
                                <Setter TargetName="Dot" Property="Fill" Value="{DynamicResource AccentText}"/>
                                <Setter TargetName="Dot" Property="RenderTransform">
                                    <Setter.Value>
                                        <TranslateTransform X="20"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="HeaderToggle" TargetType="CheckBox" BasedOn="{StaticResource {x:Type CheckBox}}">
            <Setter Property="Content" Value=""/>
            <Setter Property="ToolTip" Value="Select All"/>
            <Setter Property="LayoutTransform">
                <Setter.Value>
                    <ScaleTransform ScaleX="0.85" ScaleY="0.85"/>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource ControlFill}"/>
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource CardStroke}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="16,6"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource ControlHover}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#222222"/>
                                <Setter Property="Foreground" Value="#AAAAAA"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="{DynamicResource AccentFill}"/>
            <Setter Property="Foreground" Value="{DynamicResource AccentText}"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.9"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="GroupBox">
            <Setter Property="Margin" Value="0,0,0,16"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="GroupBox">
                        <Border Background="{DynamicResource CardFill}" BorderBrush="{DynamicResource CardStroke}" BorderThickness="1" CornerRadius="8">
                            <Grid>
                                <Grid.RowDefinitions> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> </Grid.RowDefinitions>
                                <ContentPresenter ContentSource="Header" Margin="20,16,20,8"/>
                                <ContentPresenter Margin="20,0,20,20" Grid.Row="1"/>
                            </Grid>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="Header" TargetType="TextBlock">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="Opacity" Value="0.9"/>
        </Style>

        <Style x:Key="WinBtn" TargetType="Button">
            <Setter Property="Width" Value="46"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="FontFamily" Value="{StaticResource IconFont}"/>
            <Setter Property="FontSize" Value="10"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="WindowChrome.IsHitTestVisibleInChrome" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"> <Setter TargetName="Bd" Property="Background" Value="#20FFFFFF"/> </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="CloseBtn" TargetType="Button" BasedOn="{StaticResource WinBtn}">
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True"> <Setter Property="Background" Value="#E81123"/> <Setter Property="Foreground" Value="White"/> </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="TabControl">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="TabStripPlacement" Value="Left"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabControl">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0" IsItemsHost="True" Margin="0,10,0,0"/>
                            <ContentPresenter Grid.Column="1" ContentSource="SelectedContent"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Height" Value="48"/>
            <Setter Property="Width" Value="220"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Grid x:Name="Panel" Background="Transparent" Margin="0,4">
                            <Border x:Name="Hover" CornerRadius="6"/>
                            <Rectangle x:Name="SelectionBar" Width="3" Height="20" HorizontalAlignment="Left" Fill="{DynamicResource AccentFill}" Opacity="0" RadiusX="1.5" RadiusY="1.5"/>
                            <StackPanel Orientation="Horizontal" Margin="16,0">
                                <TextBlock Text="{TemplateBinding Tag}" FontFamily="{StaticResource IconFont}" FontSize="18" VerticalAlignment="Center" x:Name="Icon" Foreground="{DynamicResource TextSecondary}" Width="32" TextAlignment="Center"/>
                                <ContentPresenter x:Name="Text" ContentSource="Header" VerticalAlignment="Center" TextElement.Foreground="{DynamicResource TextSecondary}" TextElement.FontSize="15" TextElement.FontWeight="Medium"/>
                            </StackPanel>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Hover" Property="Background" Value="#12FFFFFF"/>
                                <Setter TargetName="SelectionBar" Property="Opacity" Value="1"/>
                                <Setter TargetName="Text" Property="TextElement.Foreground" Value="{DynamicResource TextPrimary}"/>
                                <Setter TargetName="Text" Property="TextElement.FontWeight" Value="SemiBold"/>
                                <Setter TargetName="Icon" Property="Foreground" Value="{DynamicResource AccentFill}"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Hover" Property="Background" Value="#08FFFFFF"/>
                                <Setter TargetName="Text" Property="TextElement.Foreground" Value="{DynamicResource TextPrimary}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="40"/>
            <RowDefinition Height="*"/> 
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Background="Transparent" x:Name="TitleBar">
            <TextBlock Text="Windows Tweaker" VerticalAlignment="Center" Margin="24,0,0,0" FontSize="12" Foreground="{DynamicResource TextSecondary}"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button Content="&#xE921;" Style="{StaticResource WinBtn}" x:Name="BtnMinimize"/>
                <Button Content="&#xE8BB;" Style="{StaticResource CloseBtn}" x:Name="BtnClose"/>
            </StackPanel>
        </Grid>

        <TabControl Grid.Row="1" Margin="10,0,0,20" x:Name="MainTabs">
            
            <TabItem Header="Tweaks" Tag="&#xE713;">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="20,0,20,0">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="30"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <StackPanel Grid.Column="0" Margin="0,10,0,40">
                             <TextBlock Text="Privacy &amp; Interface" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}" Margin="0,0,0,20"/>

                            <GroupBox>
                                <GroupBox.Header>
                                    <DockPanel LastChildFill="False">
                                        <TextBlock Text="Privacy Essentials" Style="{StaticResource Header}"/>
                                        <CheckBox x:Name="ChkAllEssentials" Style="{StaticResource HeaderToggle}" DockPanel.Dock="Right"/>
                                    </DockPanel>
                                </GroupBox.Header>
                                <StackPanel x:Name="StackEssentials">
                                    <CheckBox x:Name="ChkTelemetry" Content="Disable Telemetry"/>
                                    <CheckBox x:Name="ChkActivity" Content="Disable Activity History"/>
                                    <CheckBox x:Name="ChkBackgroundApps" Content="Disable Background Apps"/>
                                    <CheckBox x:Name="ChkCopilot" Content="Disable Microsoft Copilot"/>
                                    <CheckBox x:Name="ChkRecall" Content="Disable Windows Recall"/>
                                    <CheckBox x:Name="ChkDisableRecs" Content="Disable Start Menu Recommendations"/>
                                </StackPanel>
                            </GroupBox>

                            <GroupBox>
                                <GroupBox.Header>
                                    <DockPanel LastChildFill="False">
                                        <TextBlock Text="Visuals" Style="{StaticResource Header}"/>
                                        <CheckBox x:Name="ChkAllVisuals" Style="{StaticResource HeaderToggle}" DockPanel.Dock="Right"/>
                                    </DockPanel>
                                </GroupBox.Header>
                                <StackPanel x:Name="StackVisuals">
                                    <CheckBox x:Name="ChkWallpaperQuality" Content="Disable Wallpaper Compression"/>
                                </StackPanel>
                            </GroupBox>

                            <GroupBox>
                                <GroupBox.Header>
                                    <DockPanel LastChildFill="False">
                                        <TextBlock Text="File Explorer" Style="{StaticResource Header}"/>
                                        <CheckBox x:Name="ChkAllExplorer" Style="{StaticResource HeaderToggle}" DockPanel.Dock="Right"/>
                                    </DockPanel>
                                </GroupBox.Header>
                                <StackPanel x:Name="StackExplorer">
                                    <CheckBox x:Name="ChkClassicContext" Content="Restore Classic Context Menu" ToolTip="Requires Explorer Restart"/>
                                    <CheckBox x:Name="ChkHiddenFiles" Content="Show Hidden Files"/>
                                    <CheckBox x:Name="ChkExtensions" Content="Show File Extensions"/>
                                </StackPanel>
                            </GroupBox>
                        </StackPanel>

                        <StackPanel Grid.Column="2" Margin="0,10,0,40">
                             <TextBlock Text="System &amp; Performance" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}" Margin="0,0,0,20"/>
                            
                            <GroupBox>
                                <GroupBox.Header>
                                    <DockPanel LastChildFill="False">
                                        <TextBlock Text="Performance" Style="{StaticResource Header}"/>
                                        <CheckBox x:Name="ChkAllMisc" Style="{StaticResource HeaderToggle}" DockPanel.Dock="Right"/>
                                    </DockPanel>
                                </GroupBox.Header>
                                <StackPanel x:Name="StackMisc">
                                    <CheckBox x:Name="ChkMouseAccel" Content="Disable Mouse Acceleration"/>
                                    <CheckBox x:Name="ChkLocation" Content="Disable Location Tracking"/>
                                    <CheckBox x:Name="ChkHomeGroup" Content="Disable HomeGroup Services"/>
                                    <CheckBox x:Name="ChkSticky" Content="Disable Sticky Keys"/>
                                    <CheckBox x:Name="ChkDisableBing" Content="Disable Bing Search"/>
                                    <CheckBox x:Name="ChkNagle" Content="Disable Nagle's Algorithm"/>
                                    <CheckBox x:Name="ChkFlushDNS" Content="Flush DNS Cache"/>
                                </StackPanel>
                            </GroupBox>

                            <GroupBox>
                                <GroupBox.Header>
                                    <DockPanel LastChildFill="False">
                                        <TextBlock Text="Advanced" Style="{StaticResource Header}"/>
                                        <CheckBox x:Name="ChkAllAdvanced" Style="{StaticResource HeaderToggle}" DockPanel.Dock="Right" IsEnabled="False"/>
                                    </DockPanel>
                                </GroupBox.Header>
                                <StackPanel x:Name="StackAdvanced">
                                    <CheckBox x:Name="ChkRemoveEdge" Content="Remove Microsoft Edge" IsEnabled="False"/>
                                    <CheckBox x:Name="ChkTrackingAggressive" Content="Disable Tracking" IsEnabled="False"/>
                                    <CheckBox x:Name="ChkIntelMM" Content="Disable Intel Management" IsEnabled="False"/>
                                    <CheckBox x:Name="ChkDisableUAC" Content="Disable UAC" IsEnabled="False"/>
                                    <CheckBox x:Name="ChkDisableNotif" Content="Disable Notifications" IsEnabled="False"/>
                                </StackPanel>
                            </GroupBox>
                            
                            <Grid Margin="0,15,0,0">
                                <Button x:Name="BtnApplyTweaks" Content="Apply Changes" HorizontalAlignment="Right" Style="{StaticResource AccentButton}" Width="160"/>
                                <Button x:Name="BtnUndoTweaks" Content="Revert Selected" HorizontalAlignment="Right" Width="160" Margin="0,0,170,0"/>
                            </Grid>
                        </StackPanel>
                    </Grid>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Debloat" Tag="&#xE74C;">
                <Grid Margin="20,10,20,0">
                    <Grid.RowDefinitions> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> <RowDefinition Height="Auto"/> </Grid.RowDefinitions>
                    <TextBlock Text="Package Manager" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}" Margin="0,0,0,20"/>
                    <GroupBox Grid.Row="1">
                        <GroupBox.Header>
                            <DockPanel LastChildFill="False">
                                <TextBlock Text="Installed Apps" Style="{StaticResource Header}"/>
                                <CheckBox x:Name="ChkSelectAllApps" Style="{StaticResource HeaderToggle}" DockPanel.Dock="Right"/>
                            </DockPanel>
                        </GroupBox.Header>
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="AppListStack" Margin="0,4"/>
                        </ScrollViewer>
                    </GroupBox>
                    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,20,0,20">
                        <Button x:Name="BtnRefreshApps" Content="Refresh List" Margin="0,0,12,0"/>
                        <Button x:Name="BtnRemoveApps" Content="Uninstall Selected" Foreground="{DynamicResource Critical}" BorderBrush="{DynamicResource Critical}"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="Configuration" Tag="&#xE968;">
                <Grid Margin="20,10,20,0">
                     <StackPanel>
                        <TextBlock Text="Configuration &amp; Specs" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}" Margin="0,0,0,20"/>
                        
                        <Border Background="{DynamicResource ControlFill}" CornerRadius="8" Padding="20" Margin="0,0,0,20" BorderBrush="{DynamicResource CardStroke}" BorderThickness="1">
                             <Grid>
                                 <Grid.ColumnDefinitions> <ColumnDefinition Width="Auto"/> <ColumnDefinition Width="*"/> <ColumnDefinition Width="Auto"/> </Grid.ColumnDefinitions>
                                 <TextBlock Text="&#xE7F4;" FontFamily="{StaticResource IconFont}" FontSize="32" Foreground="{DynamicResource AccentFill}" VerticalAlignment="Center" Margin="0,0,15,0"/>
                                 <StackPanel Grid.Column="1" VerticalAlignment="Center">
                                     <TextBox x:Name="TxtPcName" FontSize="20" FontWeight="Bold" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource TextPrimary}" Padding="0"/>
                                     <TextBlock Text="Local Machine" Foreground="{DynamicResource TextSecondary}" FontSize="13"/>
                                 </StackPanel>
                                 <Button x:Name="BtnRenamePc" Grid.Column="2" Content="Rename" Padding="12,6"/>
                             </Grid>
                        </Border>

                        <GroupBox>
                            <GroupBox.Header> <TextBlock Text="Specifications" Style="{StaticResource Header}"/> </GroupBox.Header>
                            <Grid>
                                <Grid.RowDefinitions> <RowDefinition Height="Auto"/> <RowDefinition Height="12"/> <RowDefinition Height="Auto"/> <RowDefinition Height="12"/> <RowDefinition Height="Auto"/> </Grid.RowDefinitions>
                                <Grid.ColumnDefinitions> <ColumnDefinition Width="80"/> <ColumnDefinition Width="*"/> </Grid.ColumnDefinitions>
                                <TextBlock Text="Processor" Grid.Row="0" Grid.Column="0" Foreground="{DynamicResource TextSecondary}"/>
                                <TextBlock x:Name="LblProcessor" Grid.Row="0" Grid.Column="1" TextWrapping="Wrap" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}"/>
                                <TextBlock Text="Memory" Grid.Row="2" Grid.Column="0" Foreground="{DynamicResource TextSecondary}"/>
                                <TextBlock x:Name="LblRam" Grid.Row="2" Grid.Column="1" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}"/>
                                <TextBlock Text="Graphics" Grid.Row="4" Grid.Column="0" Foreground="{DynamicResource TextSecondary}"/>
                                <TextBlock x:Name="LblGpu" Grid.Row="4" Grid.Column="1" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}"/>
                            </Grid>
                        </GroupBox>
                        
                         <GroupBox>
                             <GroupBox.Header> <TextBlock Text="System Tools" Style="{StaticResource Header}"/> </GroupBox.Header>
                            <StackPanel>
                                <Button x:Name="BtnRestorePoint" Content="Create Restore Point" HorizontalAlignment="Left" Margin="0,0,0,10"/>
                                <TextBlock Text="Unlock advanced features (Risky)" Foreground="{DynamicResource TextSecondary}" Margin="0,10,0,10" FontSize="13"/>
                                <CheckBox x:Name="ChkAllowUnsafeSettings" Content="I understand the risks" Foreground="{DynamicResource AccentFill}"/>
                            </StackPanel>
                        </GroupBox>
                    </StackPanel>
                </Grid>
            </TabItem>
        </TabControl>
        
        <ProgressBar x:Name="MainProgressBar" Grid.Row="0" Grid.RowSpan="2" VerticalAlignment="Top" Height="2" Visibility="Hidden" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource AccentFill}" IsIndeterminate="True"/>

        <Grid x:Name="NotificationOverlay" Grid.Row="1" VerticalAlignment="Bottom" HorizontalAlignment="Center" Margin="0,0,0,40" Visibility="Hidden" Panel.ZIndex="100">
             <Grid.RenderTransform> <TranslateTransform X="0" Y="20"/> </Grid.RenderTransform>
             <Border x:Name="NotificationBorder" Background="#252525" CornerRadius="8" Padding="16,12" BorderThickness="1" BorderBrush="#404040">
                <Border.Effect> <DropShadowEffect BlurRadius="20" ShadowDepth="8" Opacity="0.6"/> </Border.Effect>
                <StackPanel Orientation="Horizontal">
                    <Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="{DynamicResource AccentFill}" Margin="0,0,12,0"/>
                    <TextBlock x:Name="NotificationText" Text="Done" Foreground="White" FontWeight="SemiBold" FontSize="14"/>
                </StackPanel>
             </Border>
        </Grid>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try { $window = [Windows.Markup.XamlReader]::Load($reader) } catch { Write-Error "XAML Error: $_"; exit }

$appListStack = $window.FindName("AppListStack")
$btnRemoveApps = $window.FindName("BtnRemoveApps"); $btnRefreshApps = $window.FindName("BtnRefreshApps")
$mainProgressBar = $window.FindName("MainProgressBar")
$chkAllowUnsafeSettings = $window.FindName("ChkAllowUnsafeSettings"); $btnApplyTweaks = $window.FindName("BtnApplyTweaks"); $btnUndoTweaks = $window.FindName("BtnUndoTweaks")
$mainWindow = $window.FindName("MainWindow"); $mainTabs = $window.FindName("MainTabs")

$txtPcName = $window.FindName("TxtPcName"); $btnRenamePc = $window.FindName("BtnRenamePc"); $lblProcessor = $window.FindName("LblProcessor"); $lblRam = $window.FindName("LblRam"); $lblGpu = $window.FindName("LblGpu")
$notificationOverlay = $window.FindName("NotificationOverlay"); $notificationText = $window.FindName("NotificationText"); $statusDot = $window.FindName("StatusDot")
$btnRestorePoint = $window.FindName("BtnRestorePoint")

$chkTelemetry = $window.FindName("ChkTelemetry"); $chkActivity = $window.FindName("ChkActivity"); $chkBackgroundApps = $window.FindName("ChkBackgroundApps"); $chkCopilot = $window.FindName("ChkCopilot"); $chkRecall = $window.FindName("ChkRecall"); $chkDisableRecs = $window.FindName("ChkDisableRecs")
$chkWallpaperQuality = $window.FindName("ChkWallpaperQuality"); $chkClassicContext = $window.FindName("ChkClassicContext")
$chkHiddenFiles = $window.FindName("ChkHiddenFiles"); $chkExtensions = $window.FindName("ChkExtensions")
$chkMouseAccel = $window.FindName("ChkMouseAccel"); $chkLocation = $window.FindName("ChkLocation"); $chkHomeGroup = $window.FindName("ChkHomeGroup"); $chkSticky = $window.FindName("ChkSticky"); $chkDisableBing = $window.FindName("ChkDisableBing"); $chkNagle = $window.FindName("ChkNagle"); $chkFlushDNS = $window.FindName("ChkFlushDNS")
$chkRemoveEdge = $window.FindName("ChkRemoveEdge"); $chkTrackingAggressive = $window.FindName("ChkTrackingAggressive"); $chkIntelMM = $window.FindName("ChkIntelMM"); $chkDisableUAC = $window.FindName("ChkDisableUAC"); $chkDisableNotif = $window.FindName("ChkDisableNotif")

$chkAllEssentials = $window.FindName("ChkAllEssentials"); $stackEssentials = $window.FindName("StackEssentials")
$chkAllVisuals = $window.FindName("ChkAllVisuals"); $stackVisuals = $window.FindName("StackVisuals")
$chkAllExplorer = $window.FindName("ChkAllExplorer"); $stackExplorer = $window.FindName("StackExplorer")
$chkAllMisc = $window.FindName("ChkAllMisc"); $stackMisc = $window.FindName("StackMisc")
$chkAllAdvanced = $window.FindName("ChkAllAdvanced"); $stackAdvanced = $window.FindName("StackAdvanced")
$chkSelectAllApps = $window.FindName("ChkSelectAllApps")

$advancedTweaksList = @($chkRemoveEdge, $chkTrackingAggressive, $chkIntelMM, $chkDisableUAC, $chkDisableNotif)

$window.Add_Loaded({
    $handle = new-object System.IntPtr -ArgumentList $mainWindow.Handle
    try { [FluentWindow]::ForceDark($handle) } catch {}
    
    Load-SystemSpecs
    Load-StoreApps
})

$window.FindName("TitleBar").Add_MouseDown({ param($s,$e) if($e.ChangedButton -eq "Left"){ $window.DragMove() } })
$window.FindName("BtnMinimize").Add_Click({ $window.WindowState = "Minimized" })
$window.FindName("BtnClose").Add_Click({ $window.Close() })

function Show-Notification {
    param([string]$Message, [bool]$IsError = $false)
    $converter = New-Object System.Windows.Media.BrushConverter
    $notificationText.Text = $Message
    if ($IsError) { $statusDot.Fill = $converter.ConvertFromString("#FF453A") } else { $statusDot.Fill = $mainWindow.Resources["AccentFill"] }
    $notificationOverlay.Visibility = "Visible"
    $timer = New-Object System.Windows.Threading.DispatcherTimer; $timer.Interval = [TimeSpan]::FromSeconds(3)
    $timer.Add_Tick({ $this.Stop(); $notificationOverlay.Visibility = "Hidden" })
    $timer.Start()
}

function Set-RegKey { param($Path, $Name, $Value, $Type="DWord") if(!(Test-Path $Path)){New-Item $Path -Force|Out-Null}; New-ItemProperty $Path $Name -Value $Value -PropertyType $Type -Force|Out-Null }
function Remove-RegKey { param($Path, $Name) if(Test-Path $Path){Remove-ItemProperty $Path $Name -ErrorAction SilentlyContinue} }
function Disable-WinService { param($ServiceName) if(Get-Service $ServiceName -EA SilentlyContinue){Stop-Service $ServiceName -Force -EA SilentlyContinue; Set-Service $ServiceName -StartupType Disabled -EA SilentlyContinue} }
function Enable-WinService { param($ServiceName) if(Get-Service $ServiceName -EA SilentlyContinue){Set-Service $ServiceName -StartupType Automatic -EA SilentlyContinue; Start-Service $ServiceName -EA SilentlyContinue} }

function Update-SelectAllVisibility {
    param($checkBox, $stackPanel)
    $count = 0; foreach($child in $stackPanel.Children) { if ($child.GetType().Name -eq "CheckBox") { $count++ } }
    if ($count -lt 2) { $checkBox.Visibility = "Collapsed" } else { $checkBox.Visibility = "Visible" }
}

function Update-SafetySettings {
    $allowUnsafe = $chkAllowUnsafeSettings.IsChecked; $converter = New-Object System.Windows.Media.BrushConverter
    foreach ($chk in $advancedTweaksList) { $chk.IsEnabled = $allowUnsafe; if (-not $allowUnsafe) { $chk.IsChecked = $false } }
    foreach ($element in $appListStack.Children) { if ($element.GetType().Name -eq "CheckBox" -and (Is-CriticalApp $element.Tag.Name)) {
         if ($allowUnsafe) { $element.IsEnabled = $true; $element.Opacity = 1.0; $element.Foreground = $converter.ConvertFromString("#FF453A") }
         else { $element.IsEnabled = $false; $element.IsChecked = $false; $element.Opacity = 0.5; $element.Foreground = $mainWindow.Resources["TextSecondary"] }
    }}
}
$chkAllowUnsafeSettings.Add_Checked({ Update-SafetySettings }); $chkAllowUnsafeSettings.Add_Unchecked({ Update-SafetySettings })
function Toggle-Group { param($masterChk, $stack) $state=$masterChk.IsChecked; foreach ($e in $stack.Children) { if($e.GetType().Name -eq "CheckBox" -and $e.IsEnabled){$e.IsChecked=$state} } }
$chkAllEssentials.Add_Click({ Toggle-Group $chkAllEssentials $stackEssentials })
$chkAllVisuals.Add_Click({ Toggle-Group $chkAllVisuals $stackVisuals })
$chkAllExplorer.Add_Click({ Toggle-Group $chkAllExplorer $stackExplorer })
$chkAllMisc.Add_Click({ Toggle-Group $chkAllMisc $stackMisc })
$chkAllAdvanced.Add_Click({ Toggle-Group $chkAllAdvanced $stackAdvanced })
$chkSelectAllApps.Add_Click({ $state = $chkSelectAllApps.IsChecked; foreach ($e in $appListStack.Children) { if ($e.GetType().Name -eq "CheckBox" -and $e.IsEnabled) { $e.IsChecked = $state } } })

$btnApplyTweaks.Add_Click({
    $btnApplyTweaks.IsEnabled = $false; $btnUndoTweaks.IsEnabled = $false; $mainProgressBar.Visibility = "Visible"
    $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    if ($chkTelemetry.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0; Disable-WinService "DiagTrack"; Disable-WinService "dmwappushservice" }
    if ($chkActivity.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0; Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0 }
    if ($chkBackgroundApps.IsChecked) { Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1; Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2 }
    if ($chkCopilot.IsChecked) { Set-RegKey "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1 }
    if ($chkRecall.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1 }
    if ($chkDisableRecs.IsChecked) { Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" 0; Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" 1 }
    if ($chkWallpaperQuality.IsChecked) { Set-RegKey "HKCU:\Control Panel\Desktop" "JPEGImportQuality" 100 }
    if ($chkClassicContext.IsChecked) { Set-RegKey "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "(Default)" "" "String" }
    if ($chkHiddenFiles.IsChecked) { Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1 }
    if ($chkExtensions.IsChecked) { Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 }
    if ($chkMouseAccel.IsChecked) { Set-RegKey "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"; Set-RegKey "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"; Set-RegKey "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String" }
    if ($chkLocation.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "AllowLocation" 0; Disable-WinService "lfsvc" }
    if ($chkHomeGroup.IsChecked) { Disable-WinService "HomeGroupListener"; Disable-WinService "HomeGroupProvider" }
    if ($chkSticky.IsChecked) { Set-RegKey "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "String" }
    if ($chkDisableBing.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1; Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0 }
    if ($chkNagle.IsChecked) { Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object { Set-ItemProperty $_.PSPath "TcpAckFrequency" 1 -Type DWord -EA SilentlyContinue; Set-ItemProperty $_.PSPath "TCPNoDelay" 1 -Type DWord -EA SilentlyContinue } }
    if ($chkFlushDNS.IsChecked) { Clear-DnsClientCache }
    if ($chkRemoveEdge.IsChecked) { Get-AppxPackage *Edge* | Remove-AppxPackage -EA SilentlyContinue; Set-RegKey "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" "DoNotUpdateToEdgeWithChromium" 1 }
    if ($chkTrackingAggressive.IsChecked) { Disable-WinService "WerSvc"; Disable-WinService "PcaSvc" }
    if ($chkIntelMM.IsChecked) { Disable-WinService "LMS" }
    if ($chkDisableUAC.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 0 }
    if ($chkDisableNotif.IsChecked) { if (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null }; Set-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableNotificationCenter" 1 -Type DWord -Force }
    if ($chkClassicContext.IsChecked -or $chkHiddenFiles.IsChecked -or $chkExtensions.IsChecked) { Stop-Process -Name explorer -Force }
    Start-Sleep -Seconds 1; $mainProgressBar.Visibility = "Hidden"; Show-Notification "Changes Applied" $false; $btnApplyTweaks.IsEnabled = $true; $btnUndoTweaks.IsEnabled = $true
})

$btnUndoTweaks.Add_Click({
    $btnApplyTweaks.IsEnabled = $false; $btnUndoTweaks.IsEnabled = $false; $mainProgressBar.Visibility = "Visible"
    $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    if ($chkTelemetry.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 1; Enable-WinService "DiagTrack"; Enable-WinService "dmwappushservice" }
    if ($chkActivity.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 1; Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 1 }
    if ($chkBackgroundApps.IsChecked) { Remove-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled"; Remove-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" }
    if ($chkCopilot.IsChecked) { Set-RegKey "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 0 }
    if ($chkRecall.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 0 }
    if ($chkDisableRecs.IsChecked) { Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" 1; Remove-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" }
    if ($chkWallpaperQuality.IsChecked) { Remove-RegKey "HKCU:\Control Panel\Desktop" "JPEGImportQuality" }
    if ($chkClassicContext.IsChecked) { if(Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"){Remove-Item "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force} }
    if ($chkHiddenFiles.IsChecked) { Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 2 }
    if ($chkExtensions.IsChecked) { Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 1 }
    if ($chkMouseAccel.IsChecked) { Set-RegKey "HKCU:\Control Panel\Mouse" "MouseSpeed" "1" "String"; Set-RegKey "HKCU:\Control Panel\Mouse" "MouseThreshold1" "6" "String"; Set-RegKey "HKCU:\Control Panel\Mouse" "MouseThreshold2" "10" "String" }
    if ($chkLocation.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "AllowLocation" 1; Enable-WinService "lfsvc" }
    if ($chkHomeGroup.IsChecked) { Enable-WinService "HomeGroupListener"; Enable-WinService "HomeGroupProvider" }
    if ($chkSticky.IsChecked) { Set-RegKey "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "510" "String" }
    if ($chkDisableBing.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 0; Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 1 }
    if ($chkNagle.IsChecked) { Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object { Remove-RegKey $_.PSPath "TcpAckFrequency"; Remove-RegKey $_.PSPath "TCPNoDelay" } }
    if ($chkTrackingAggressive.IsChecked) { Enable-WinService "WerSvc"; Enable-WinService "PcaSvc" }
    if ($chkIntelMM.IsChecked) { Enable-WinService "LMS" }
    if ($chkDisableUAC.IsChecked) { Set-RegKey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1 }
    if ($chkDisableNotif.IsChecked) { Set-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableNotificationCenter" 0 -Type DWord -Force }
    if ($chkClassicContext.IsChecked -or $chkHiddenFiles.IsChecked -or $chkExtensions.IsChecked) { Stop-Process -Name explorer -Force }
    Start-Sleep -Seconds 1; $mainProgressBar.Visibility = "Hidden"; Show-Notification "Restored" $false; $btnUndoTweaks.IsEnabled = $true; $btnApplyTweaks.IsEnabled = $true
})

$criticalApps = @("Microsoft.WindowsStore", "Microsoft.StorePurchaseApp", "Microsoft.DesktopAppInstaller", "Microsoft.Services.Store.Engagement", "Microsoft.XboxApp", "Microsoft.XboxIdentityProvider", "Microsoft.XboxGamingOverlay")
function Is-CriticalApp($appName) { if ([string]::IsNullOrEmpty($appName)) { return $false }; return ($criticalApps -contains $appName) }
function Get-CleanAppName($rawName) { if (-not $rawName) { return "Unknown App" }; $clean = $rawName -replace "^Microsoft\.", "" -replace "^Windows\.", "" -replace "\.", " "; return $clean }

function Load-StoreApps {
    if ($appListStack -eq $null) { return }
    $appListStack.Children.Clear()
    $loadingText = New-Object System.Windows.Controls.TextBlock; $loadingText.Text = "Loading..."; $loadingText.Foreground = $mainWindow.Resources["TextSecondary"]; [void]$appListStack.Children.Add($loadingText)
    $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    $apps = Get-AppxPackage | Where-Object { $_.IsFramework -eq $false -and $_.NonRemovable -eq $false -and $_.SignatureKind -ne "System" -and $_.Name -notlike "*Edge*" } | Sort-Object Name
    $appListStack.Children.Clear()
    if ($apps.Count -eq 0) { $msg = New-Object System.Windows.Controls.TextBlock; $msg.Text = "No apps found."; [void]$appListStack.Children.Add($msg); return }
    foreach ($app in $apps) {
        $chk = New-Object System.Windows.Controls.CheckBox; $chk.Content = Get-CleanAppName $app.Name; $chk.Tag = @{ FullName = $app.PackageFullName; Name = $app.Name }
        if (Is-CriticalApp $app.Name) { $chk.Foreground = $mainWindow.Resources["TextSecondary"]; $chk.IsEnabled = $false } else { $chk.Foreground = $mainWindow.Resources["TextPrimary"] }
        [void]$appListStack.Children.Add($chk)
    }
    Update-SafetySettings
    Update-SelectAllVisibility $chkSelectAllApps $appListStack
}

$btnRefreshApps.Add_Click({ Load-StoreApps })
$btnRemoveApps.Add_Click({
    $appsToRemove = $appListStack.Children | Where-Object { $_.GetType().Name -eq "CheckBox" -and $_.IsChecked }
    if ($appsToRemove.Count -eq 0) { Show-Notification "No apps selected" $true; return }
    if ([System.Windows.MessageBox]::Show("Remove $($appsToRemove.Count) packages?", "Confirm", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq 'Yes') {
        $mainProgressBar.Visibility = "Visible"; $btnRemoveApps.IsEnabled = $false
        foreach ($chk in $appsToRemove) {
            $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
            try { Remove-AppxPackage -Package $chk.Tag.FullName -ErrorAction Stop; if ($appListStack.Children.Contains($chk)) { [void]$appListStack.Children.Remove($chk) } }
            catch { $chk.Foreground = "Orange"; $chk.IsChecked = $false }
        }
        $mainProgressBar.Visibility = "Hidden"; $btnRemoveApps.IsEnabled = $true; Show-Notification "Cleaned" $false
    }
})

function Load-SystemSpecs {
    try { $proc = (Get-CimInstance Win32_Processor).Name; $mem = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0); $gpu = (Get-CimInstance Win32_VideoController).Name; $lblProcessor.Text = $proc; $lblRam.Text = "$mem GB"; $lblGpu.Text = $gpu; $txtPcName.Text = $env:COMPUTERNAME } catch { $lblProcessor.Text = "Unknown" }
}

$btnRenamePc.Add_Click({
    $newName = $txtPcName.Text
    if ([string]::IsNullOrWhiteSpace($newName) -or $newName -eq $env:COMPUTERNAME) { return }
    if ([System.Windows.MessageBox]::Show("Rename to '$newName' and restart?", "Confirm", [System.Windows.MessageBoxButton]::YesNo) -eq 'Yes') { try { Rename-Computer -NewName $newName -ErrorAction Stop; Restart-Computer -Force } catch { Show-Notification "Failed" $true } }
})

$btnRestorePoint.Add_Click({
    $mainProgressBar.Visibility = "Visible"
    $window.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    try { Checkpoint-Computer -Description "WindowsTweaker Backup" -RestorePointType "MODIFY_SETTINGS"; Show-Notification "Restore Point Created" $false }
    catch { Show-Notification "Failed to create Restore Point" $true }
    $mainProgressBar.Visibility = "Hidden"
})

Update-SelectAllVisibility $chkAllEssentials $stackEssentials; Update-SelectAllVisibility $chkAllVisuals $stackVisuals; Update-SelectAllVisibility $chkAllExplorer $stackExplorer; Update-SelectAllVisibility $chkAllMisc $stackMisc; Update-SelectAllVisibility $chkAllAdvanced $stackAdvanced

$window.ShowDialog() | Out-Null