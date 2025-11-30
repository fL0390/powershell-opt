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

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName WindowsBase

$username = $env:USERNAME

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Tweaker" Height="850" Width="900"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#F5F5F5" FontFamily="Segoe UI" x:Name="MainWindow">

    <Window.Resources>
        <SolidColorBrush x:Key="AccentColor" Color="#007ACC"/>
        <SolidColorBrush x:Key="AccentHover" Color="#0099FF"/>
        
        <SolidColorBrush x:Key="WindowBackground" Color="#F5F5F5"/>
        <SolidColorBrush x:Key="PanelBackground" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#333333"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#777777"/>
        <SolidColorBrush x:Key="BorderColor" Color="#DDDDDD"/>
        <SolidColorBrush x:Key="DisabledText" Color="#AAAAAA"/>
        <SolidColorBrush x:Key="ScrollThumb" Color="#CCCCCC"/>

        <QuadraticEase x:Key="EaseOut" EasingMode="EaseOut"/>
        <CubicEase x:Key="SmoothEase" EasingMode="EaseOut"/>

        <Style x:Key="ScrollBarThumb" TargetType="{x:Type Thumb}">
            <Setter Property="OverridesDefaultStyle" Value="true"/>
            <Setter Property="IsTabStop" Value="false"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Thumb}">
                        <Border x:Name="rectangle" Background="{DynamicResource ScrollThumb}" CornerRadius="4" BorderThickness="0"/>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="true">
                                <Setter TargetName="rectangle" Property="Background" Value="{DynamicResource AccentColor}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="{x:Type ScrollBar}">
            <Setter Property="Stylus.IsFlicksEnabled" Value="false"/>
            <Setter Property="Foreground" Value="{DynamicResource TextSecondary}"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ScrollBar}">
                        <Grid x:Name="GridRoot" Width="8" Background="{TemplateBinding Background}">
                            <Track x:Name="PART_Track" IsDirectionReversed="true" Focusable="false">
                                <Track.Thumb>
                                    <Thumb x:Name="Thumb" Background="{TemplateBinding Foreground}" Style="{StaticResource ScrollBarThumb}"/>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton x:Name="PageUp" Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="false"/>
                                </Track.IncreaseRepeatButton>
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton x:Name="PageDown" Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="false"/>
                                </Track.DecreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SlideInContent" TargetType="FrameworkElement">
            <Setter Property="RenderTransform">
                <Setter.Value>
                    <TranslateTransform X="0" Y="0"/>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <EventTrigger RoutedEvent="Loaded">
                    <BeginStoryboard>
                        <Storyboard>
                            <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.4"/>
                            <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.Y)" From="20" To="0" Duration="0:0:0.4" EasingFunction="{StaticResource SmoothEase}"/>
                        </Storyboard>
                    </BeginStoryboard>
                </EventTrigger>
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
                                <Setter Property="Foreground" Value="{DynamicResource AccentHover}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style TargetType="GroupBox">
            <Setter Property="Padding" Value="10,5,10,15"/>
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
                                <Border Grid.Row="0" Padding="10,12,10,5">
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
            <Setter Property="Background" Value="{DynamicResource AccentColor}"/>
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
                                <Setter TargetName="border" Property="Background" Value="{DynamicResource AccentHover}"/>
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

        <Style x:Key="SelectAllStyle" TargetType="CheckBox">
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Foreground" Value="{DynamicResource TextSecondary}"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalAlignment" Value="Right"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Foreground" Value="{DynamicResource DisabledText}"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="0,4"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="RenderTransform">
                <Setter.Value>
                    <TranslateTransform X="0" Y="0"/>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Foreground" Value="{DynamicResource DisabledText}"/>
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                    <Trigger.EnterActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.X)" To="5" Duration="0:0:0.2" EasingFunction="{StaticResource EaseOut}"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.EnterActions>
                    <Trigger.ExitActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.X)" To="0" Duration="0:0:0.2"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.ExitActions>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="8"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Background" Value="{DynamicResource PanelBackground}"/>
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource BorderColor}"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>

        <Style TargetType="TextBlock" x:Key="HeaderTitleStyle">
            <Setter Property="Foreground" Value="{DynamicResource AccentColor}"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
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
    
    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard>
                <Storyboard>
                    <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.5"/>
                    <ThicknessAnimation Storyboard.TargetProperty="Margin" From="0,50,0,-50" To="0" Duration="0:0:0.5">
                        <ThicknessAnimation.EasingFunction>
                            <CubicEase EasingMode="EaseOut"/>
                        </ThicknessAnimation.EasingFunction>
                    </ThicknessAnimation>
                </Storyboard>
            </BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

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

                            <StackPanel Grid.Column="0">
                                <GroupBox VerticalAlignment="Top" Margin="0,0,0,20">
                                    <GroupBox.Header>
                                        <DockPanel Width="360">
                                            <TextBlock Text="Essentials" Style="{StaticResource HeaderTitleStyle}"/>
                                            <CheckBox x:Name="ChkAllEssentials" Content="Select All" Style="{StaticResource SelectAllStyle}"/>
                                        </DockPanel>
                                    </GroupBox.Header>
                                    <StackPanel x:Name="StackEssentials">
                                        <CheckBox x:Name="ChkTelemetry" Content="Disable Telemetry" IsChecked="True"/>
                                        <CheckBox x:Name="ChkActivity" Content="Disable Activity History" IsChecked="True"/>
                                        <CheckBox x:Name="ChkBackgroundApps" Content="Disable Background Apps"/>
                                        <CheckBox x:Name="ChkCopilot" Content="Disable Microsoft Copilot"/>
                                        <CheckBox x:Name="ChkRecall" Content="Disable Windows Recall (AI)"/>
                                        <CheckBox x:Name="ChkOneDrive" Content="Remove OneDrive"/>
                                        <CheckBox x:Name="ChkUltPerf" Content="Enable Ultimate Performance Plan"/>
                                        <CheckBox x:Name="ChkDisableRecs" Content="Disable Start Menu Recommendations"/>
                                    </StackPanel>
                                </GroupBox>
                                
                                <GroupBox>
                                    <GroupBox.Header>
                                        <DockPanel Width="360">
                                            <TextBlock Text="Visuals &amp; System" Style="{StaticResource HeaderTitleStyle}"/>
                                            <CheckBox x:Name="ChkAllVisuals" Content="Select All" Style="{StaticResource SelectAllStyle}"/>
                                        </DockPanel>
                                    </GroupBox.Header>
                                    <StackPanel x:Name="StackVisuals">
                                        <TextBlock Text="System Colors:" Margin="0,0,0,3" FontSize="12" Foreground="{DynamicResource TextSecondary}"/>
                                        <ComboBox x:Name="CmbWindowsTheme" Margin="0,0,0,10">
                                            <ComboBoxItem Content="Dark Mode"/>
                                            <ComboBoxItem Content="Light Mode"/>
                                        </ComboBox>
                                        
                                        <CheckBox x:Name="ChkWallpaperQuality" Content="Disable JPEG Wallpaper Compression" ToolTip="Sets Import Quality to 100%"/>
                                    </StackPanel>
                                </GroupBox>
                            </StackPanel>

                            <GroupBox Grid.Column="2" VerticalAlignment="Stretch">
                                <GroupBox.Header>
                                    <DockPanel Width="360">
                                        <TextBlock Text="Miscellaneous" Style="{StaticResource HeaderTitleStyle}"/>
                                        <CheckBox x:Name="ChkAllMisc" Content="Select All" Style="{StaticResource SelectAllStyle}"/>
                                    </DockPanel>
                                </GroupBox.Header>
                                <StackPanel x:Name="StackMisc">
                                    <CheckBox x:Name="ChkMouseAccel" Content="Disable Mouse Acceleration"/>
                                    <CheckBox x:Name="ChkLocation" Content="Disable Location Tracking"/>
                                    <CheckBox x:Name="ChkHomeGroup" Content="Disable HomeGroup"/>
                                    <CheckBox x:Name="ChkSticky" Content="Disable Sticky Keys"/>
                                    <CheckBox x:Name="ChkHiddenFiles" Content="Show Hidden Files &amp; Extensions"/>
                                    <CheckBox x:Name="ChkDisableBing" Content="Disable Bing Search in Start"/>
                                    <CheckBox x:Name="ChkClassicContext" Content="Restore Classic Context Menu"/>
                                    <CheckBox x:Name="ChkNagle" Content="Disable Nagle's Algorithm (Latency)"/>
                                    <CheckBox x:Name="ChkFlushDNS" Content="Flush DNS Cache"/>
                                    <CheckBox x:Name="ChkVerboseLogon" Content="Verbose Messages During Logon"/>
                                    <CheckBox x:Name="ChkDisableMPO" Content="Disable Multiplane Overlay (MPO)"/>
                                </StackPanel>
                            </GroupBox>
                        </Grid>

                        <GroupBox Margin="0,20,0,0">
                             <GroupBox.Header>
                                <DockPanel Width="760">
                                    <TextBlock Text="Advanced" Style="{StaticResource HeaderTitleStyle}"/>
                                    <CheckBox x:Name="ChkAllAdvanced" Content="Select All" Style="{StaticResource SelectAllStyle}" IsEnabled="False"/>
                                </DockPanel>
                            </GroupBox.Header>
                            <StackPanel x:Name="StackAdvanced">
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
                    
                    <GroupBox Grid.Row="0" Margin="0,0,0,10">
                        <GroupBox.Header>
                             <DockPanel Width="760">
                                <TextBlock Text="Select System Packages to Remove:" Style="{StaticResource HeaderTitleStyle}"/>
                                <CheckBox x:Name="ChkSelectAllApps" Content="Select All" Style="{StaticResource SelectAllStyle}"/>
                            </DockPanel>
                        </GroupBox.Header>
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

            <TabItem Header="System">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <Grid Margin="20" Style="{StaticResource SlideInContent}">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <Grid Grid.Row="0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="20"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <GroupBox Grid.Column="0">
                                <GroupBox.Header>
                                    <TextBlock Text="Interface Theme" Style="{StaticResource HeaderTitleStyle}"/>
                                </GroupBox.Header>
                                <StackPanel>
                                    <ComboBox x:Name="CmbTheme" SelectedIndex="0" Width="Auto" HorizontalAlignment="Stretch">
                                        <ComboBoxItem Content="System (Auto)"/>
                                        <ComboBoxItem Content="Light"/>
                                        <ComboBoxItem Content="Dark"/>
                                    </ComboBox>
                                </StackPanel>
                            </GroupBox>

                            <GroupBox Grid.Column="2">
                                <GroupBox.Header>
                                    <TextBlock Text="Safety Override" Style="{StaticResource HeaderTitleStyle}"/>
                                </GroupBox.Header>
                                <StackPanel>
                                    <CheckBox x:Name="ChkAllowUnsafeSettings" 
                                              Content="Allow unsafe tweaks" 
                                              Foreground="#DAA520" 
                                              FontWeight="Bold"/>
                                </StackPanel>
                            </GroupBox>
                        </Grid>

                        <GroupBox Grid.Row="1" Margin="0,20,0,0">
                            <GroupBox.Header>
                                <TextBlock Text="System Information" Style="{StaticResource HeaderTitleStyle}"/>
                            </GroupBox.Header>
                            <Grid Margin="20">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="140"/> 
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/> <RowDefinition Height="20"/>   <RowDefinition Height="Auto"/> <RowDefinition Height="15"/>   <RowDefinition Height="Auto"/> <RowDefinition Height="15"/>   <RowDefinition Height="Auto"/> <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/> </Grid.RowDefinitions>

                                <TextBlock Text="Computer Name:" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center" Foreground="{DynamicResource TextSecondary}" FontSize="13"/>
                                
                                <Grid Grid.Row="0" Grid.Column="1">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBox x:Name="TxtPcName" Grid.Column="0" Margin="0,0,10,0"/>
                                    <Button x:Name="BtnRenamePc" Grid.Column="1" Padding="15,5" Margin="0" Content="Apply Name"/>
                                </Grid>

                                <TextBlock Text="Processor:" Grid.Row="2" Grid.Column="0" Foreground="{DynamicResource TextSecondary}" FontSize="13"/>
                                <TextBlock x:Name="LblProcessor" Grid.Row="2" Grid.Column="1" FontWeight="SemiBold" FontSize="13" TextWrapping="Wrap" Foreground="{DynamicResource TextPrimary}"/>

                                <TextBlock Text="Memory (RAM):" Grid.Row="4" Grid.Column="0" Foreground="{DynamicResource TextSecondary}" FontSize="13"/>
                                <TextBlock x:Name="LblRam" Grid.Row="4" Grid.Column="1" FontWeight="SemiBold" FontSize="13" Foreground="{DynamicResource TextPrimary}"/>

                                <TextBlock Text="Graphics (GPU):" Grid.Row="6" Grid.Column="0" Foreground="{DynamicResource TextSecondary}" FontSize="13"/>
                                <TextBlock x:Name="LblGpu" Grid.Row="6" Grid.Column="1" FontWeight="SemiBold" FontSize="13" Foreground="{DynamicResource TextPrimary}"/>

                                <StackPanel Grid.Row="8" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right">
                                    <Button x:Name="BtnEditHosts" Content="Edit Hosts File" Background="#555"/>
                                </StackPanel>
                            </Grid>
                        </GroupBox>
                    </Grid>
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

        <Grid x:Name="NotificationOverlay" VerticalAlignment="Bottom" Margin="20" Visibility="Hidden" Panel.ZIndex="100">
             <Grid.RenderTransform>
                <TranslateTransform X="0" Y="20"/>
             </Grid.RenderTransform>
             <Border x:Name="NotificationBorder" Background="#43A047" CornerRadius="4" Padding="20,10">
                <Border.Effect>
                    <DropShadowEffect BlurRadius="10" ShadowDepth="2" Opacity="0.3"/>
                </Border.Effect>
                <TextBlock x:Name="NotificationText" Text="Operation Successful" Foreground="White" FontWeight="SemiBold" HorizontalAlignment="Center"/>
             </Border>
        </Grid>
                    
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
$dlcListStack = $window.FindName("DlcListStack")
$btnRemoveApps = $window.FindName("BtnRemoveApps")
$btnRefreshApps = $window.FindName("BtnRefreshApps")
$mainProgressBar = $window.FindName("MainProgressBar")
$chkAllowUnsafeSettings = $window.FindName("ChkAllowUnsafeSettings")
$btnApplyTweaks = $window.FindName("BtnApplyTweaks")
$btnUndoTweaks = $window.FindName("BtnUndoTweaks")
$cmbTheme = $window.FindName("CmbTheme")
$mainWindow = $window.FindName("MainWindow")

# System Info Controls
$txtPcName = $window.FindName("TxtPcName")
$btnRenamePc = $window.FindName("BtnRenamePc")
$lblProcessor = $window.FindName("LblProcessor")
$lblRam = $window.FindName("LblRam")
$lblGpu = $window.FindName("LblGpu")
$btnEditHosts = $window.FindName("BtnEditHosts")

$notificationOverlay = $window.FindName("NotificationOverlay")
$notificationBorder = $window.FindName("NotificationBorder")
$notificationText = $window.FindName("NotificationText")

$chkAllEssentials = $window.FindName("ChkAllEssentials")
$stackEssentials = $window.FindName("StackEssentials")
$chkAllVisuals = $window.FindName("ChkAllVisuals")
$stackVisuals = $window.FindName("StackVisuals")
$chkAllMisc = $window.FindName("ChkAllMisc")
$stackMisc = $window.FindName("StackMisc")
$chkAllAdvanced = $window.FindName("ChkAllAdvanced")
$stackAdvanced = $window.FindName("StackAdvanced")
$chkSelectAllApps = $window.FindName("ChkSelectAllApps")

$chkTelemetry = $window.FindName("ChkTelemetry")
$chkActivity = $window.FindName("ChkActivity")
$chkBackgroundApps = $window.FindName("ChkBackgroundApps")
$chkCopilot = $window.FindName("ChkCopilot")
$chkRecall = $window.FindName("ChkRecall")
$chkOneDrive = $window.FindName("ChkOneDrive")
$chkUltPerf = $window.FindName("ChkUltPerf")
$chkDisableRecs = $window.FindName("ChkDisableRecs") 

$cmbWindowsTheme = $window.FindName("CmbWindowsTheme") 
$chkWallpaperQuality = $window.FindName("ChkWallpaperQuality") 

$chkMouseAccel = $window.FindName("ChkMouseAccel")
$chkLocation = $window.FindName("ChkLocation")
$chkHomeGroup = $window.FindName("ChkHomeGroup")
$chkSticky = $window.FindName("ChkSticky")
$chkHiddenFiles = $window.FindName("ChkHiddenFiles")
$chkDisableBing = $window.FindName("ChkDisableBing")
$chkClassicContext = $window.FindName("ChkClassicContext")
$chkNagle = $window.FindName("ChkNagle")
$chkFlushDNS = $window.FindName("ChkFlushDNS")
$chkVerboseLogon = $window.FindName("ChkVerboseLogon") 
$chkDisableMPO = $window.FindName("ChkDisableMPO") 

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
        $mainWindow.Resources["ScrollThumb"] = $converter.ConvertFromString("#555555")
        $mainWindow.Background = $mainWindow.Resources["WindowBackground"]
    }
    else {
        $mainWindow.Resources["WindowBackground"] = $converter.ConvertFromString("#F5F5F5")
        $mainWindow.Resources["PanelBackground"] = $converter.ConvertFromString("#FFFFFF")
        $mainWindow.Resources["TextPrimary"] = $converter.ConvertFromString("#333333")
        $mainWindow.Resources["TextSecondary"] = $converter.ConvertFromString("#777777")
        $mainWindow.Resources["BorderColor"] = $converter.ConvertFromString("#DDDDDD")
        $mainWindow.Resources["DisabledText"] = $converter.ConvertFromString("#AAAAAA")
        $mainWindow.Resources["ScrollThumb"] = $converter.ConvertFromString("#CCCCCC")
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


$currentWinMode = Check-SystemTheme
if ($currentWinMode -eq "Dark") { $cmbWindowsTheme.SelectedIndex = 0 } 
else { $cmbWindowsTheme.SelectedIndex = 1 } 


function Show-Notification {
    param([string]$Message, [bool]$IsError = $false)
    
    $converter = New-Object System.Windows.Media.BrushConverter
    $notificationText.Text = $Message
    
    if ($IsError) { $notificationBorder.Background = $converter.ConvertFromString("#E53935") }
    else { $notificationBorder.Background = $converter.ConvertFromString("#43A047") }
    
    $notificationOverlay.Visibility = "Visible"
    
    $duration = [TimeSpan]::FromSeconds(0.3)
    
    $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
    $fadeIn.From = 0
    $fadeIn.To = 1
    $fadeIn.Duration = $duration
    
    $slideUp = New-Object System.Windows.Media.Animation.DoubleAnimation
    $slideUp.From = 20
    $slideUp.To = 0
    $slideUp.Duration = $duration
    $slideUp.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
    $slideUp.EasingFunction.EasingMode = "EaseOut"

    $notificationOverlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeIn)
    $notificationOverlay.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $slideUp)

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(3)
    $timer.Add_Tick({
        $this.Stop() 
        $animDuration = [TimeSpan]::FromSeconds(0.3)

        $fadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeOut.From = 1
        $fadeOut.To = 0
        $fadeOut.Duration = $animDuration
        
        $slideDown = New-Object System.Windows.Media.Animation.DoubleAnimation
        $slideDown.From = 0
        $slideDown.To = 20
        $slideDown.Duration = $animDuration
        
        $fadeOut.Add_Completed({ $notificationOverlay.Visibility = "Hidden" })
        
        $notificationOverlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeOut)
        $notificationOverlay.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $slideDown)
    })
    $timer.Start()
}

function Set-RegKey {
    param([string]$Path, [string]$Name, [string]$Value, [string]$PropertyType = "DWord")
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force | Out-Null
}

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

function Update-SelectAllVisibility {
    param($checkBox, $stackPanel)
    $count = 0
    foreach($child in $stackPanel.Children) {
        if ($child.GetType().Name -eq "CheckBox") { $count++ }
    }

    if ($count -lt 2) {
        $checkBox.Visibility = "Collapsed"
    } else {
        $checkBox.Visibility = "Visible"
    }
}

function Update-SafetySettings {
    $allowUnsafe = $chkAllowUnsafeSettings.IsChecked
    $converter = New-Object System.Windows.Media.BrushConverter

    $chkAllAdvanced.IsEnabled = $allowUnsafe
    if ($allowUnsafe) {
        $chkAllAdvanced.Opacity = 1.0
    }
    else {
        $chkAllAdvanced.IsChecked = $false
        $chkAllAdvanced.Opacity = 0.6
    }

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

function Toggle-Group {
    param($masterChk, $stack)
    $state = $masterChk.IsChecked
    foreach ($element in $stack.Children) {
        if ($element.GetType().Name -eq "CheckBox" -and $element.IsEnabled) {
            $element.IsChecked = $state
        }
    }
}

$chkAllEssentials.Add_Click({ Toggle-Group $chkAllEssentials $stackEssentials })
$chkAllVisuals.Add_Click({ Toggle-Group $chkAllVisuals $stackVisuals })
$chkAllMisc.Add_Click({ Toggle-Group $chkAllMisc $stackMisc })
$chkAllAdvanced.Add_Click({ Toggle-Group $chkAllAdvanced $stackAdvanced })

$chkSelectAllApps.Add_Click({
    $state = $chkSelectAllApps.IsChecked
    foreach ($element in $appListStack.Children) {
        if ($element.GetType().Name -eq "CheckBox" -and $element.IsEnabled) {
            $element.IsChecked = $state
        }
    }
})

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

        if ($chkDisableRecs.IsChecked) {
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value 0
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecommendedSection" -Value 1
        }

        if ($chkWallpaperQuality.IsChecked) {
            Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality" -Value 100
        }

        $winThemeSel = $cmbWindowsTheme.SelectedItem.Content
        if ($winThemeSel -eq "Dark Mode") {
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
        }
        elseif ($winThemeSel -eq "Light Mode") {
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1
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
        
        if ($chkDisableBing.IsChecked) { 
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 
        }
    
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

        if ($chkVerboseLogon.IsChecked) {
            Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "verbosestatus" -Value 1
        }

        if ($chkDisableMPO.IsChecked) {
            Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5
        }

        if ($chkRemoveEdge.IsChecked) { Get-AppxPackage *Edge* | Remove-AppxPackage -ErrorAction SilentlyContinue; Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" -Name "DoNotUpdateToEdgeWithChromium" -Value 1 }
        if ($chkTrackingAggressive.IsChecked) { Disable-WinService "WerSvc"; Disable-WinService "PcaSvc" }
        if ($chkIntelMM.IsChecked) { Disable-WinService "LMS" }
        if ($chkDisableUAC.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 }
        if ($chkDisableNotif.IsChecked) { if (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null }; Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -Force }

        Start-Sleep -Seconds 1
    
        $mainProgressBar.Visibility = "Hidden"
        
        Show-Notification "Changes Applied Successfully" $false
        
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

        if ($chkDisableRecs.IsChecked) {
             Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value 1
             Remove-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecommendedSection"
        }

        if ($chkWallpaperQuality.IsChecked) {
            Remove-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "JPEGImportQuality"
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
        
        if ($chkDisableBing.IsChecked) { 
            Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 0
            Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 1 
        }
    
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

        if ($chkVerboseLogon.IsChecked) {
            Remove-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "verbosestatus"
        }

        if ($chkDisableMPO.IsChecked) {
            Remove-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode"
        }

        if ($chkTrackingAggressive.IsChecked) { Enable-WinService "WerSvc"; Enable-WinService "PcaSvc" }
        if ($chkIntelMM.IsChecked) { Enable-WinService "LMS" }
        if ($chkDisableUAC.IsChecked) { Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 }
        if ($chkDisableNotif.IsChecked) { Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 0 -Type DWord -Force }

        Start-Sleep -Seconds 1
    
        $mainProgressBar.Visibility = "Hidden"
        
        Show-Notification "Restored Defaults Successfully" $false
        
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
    Update-SelectAllVisibility $chkSelectAllApps $appListStack
    Update-SafetySettings
}

$btnRefreshApps.Add_Click({ Load-StoreApps })
$btnRemoveApps.Add_Click({
        $appsToRemove = ($appListStack.Children + $dlcListStack.Children) | Where-Object { $_.GetType().Name -eq "CheckBox" -and $_.IsChecked }
        if ($appsToRemove.Count -eq 0) { Show-Notification "Please select a package" $true; return }
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
            $btnRemoveApps.IsEnabled = $true; 
            Show-Notification "Debloat Process Completed" $false
        }
    })

function Load-SystemSpecs {
    try {
        $proc = (Get-CimInstance Win32_Processor).Name
        $mem = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)
        $gpu = (Get-CimInstance Win32_VideoController).Name
        
        $lblProcessor.Text = $proc
        $lblRam.Text = "$mem GB"
        $lblGpu.Text = $gpu
        $txtPcName.Text = $env:COMPUTERNAME
    } catch {
        $lblProcessor.Text = "Unknown"
    }
}

$btnRenamePc.Add_Click({
    $newName = $txtPcName.Text
    if ([string]::IsNullOrWhiteSpace($newName) -or $newName -eq $env:COMPUTERNAME) { return }
    
    $confirm = [System.Windows.MessageBox]::Show("Rename PC to '$newName' and restart?", "Confirm", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -eq 'Yes') {
        try {
            Rename-Computer -NewName $newName -ErrorAction Stop
            [System.Windows.MessageBox]::Show("Restarting now...", "Success")
            Restart-Computer -Force
        } catch {
            Show-Notification "Rename Failed" $true
        }
    }
})

$btnEditHosts.Add_Click({
    Start-Process notepad.exe "$env:SystemRoot\System32\drivers\etc\hosts" -Verb RunAs
})

Update-SelectAllVisibility $chkAllEssentials $stackEssentials
Update-SelectAllVisibility $chkAllVisuals $stackVisuals
Update-SelectAllVisibility $chkAllMisc $stackMisc
Update-SelectAllVisibility $chkAllAdvanced $stackAdvanced

Load-SystemSpecs
Load-StoreApps

$window.ShowDialog() | Out-Null