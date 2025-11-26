Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing

function Get-UserProfilePicture {
    $picPath = "$env:APPDATA\Microsoft\Windows\AccountPictures"
    if (Test-Path $picPath) {
        $pic = Get-ChildItem $picPath -Filter *.jpg | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($pic) { return $pic.FullName }
    }
    
    $publicPic = "$env:PROGRAMDATA\Microsoft\User Account Pictures\user.png"
    if (Test-Path $publicPic) { return $publicPic }
    
    return $null
}



$userPicPath = Get-UserProfilePicture
$username = $env:USERNAME

$userPicXaml = ""
if ($userPicPath) {
    $userPicXaml = @"
            <Border CornerRadius="20" Width="40" Height="40" BorderThickness="1" BorderBrush="#CCC">
                <Border.Background>
                    <ImageBrush ImageSource="$userPicPath" Stretch="UniformToFill"/>
                </Border.Background>
            </Border>
"@
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerShell GUI" Height="500" Width="700"
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
            <Setter Property="Padding" Value="30,15"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect BlurRadius="15" ShadowDepth="3" Opacity="0.4" Color="#005A9E"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="0,8"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Foreground" Value="#444"/>
        </Style>
        
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#333"/>
        </Style>
    </Window.Resources>

    <Grid>
        <TabControl Background="Transparent" BorderThickness="0" Margin="10,10,10,10">
            
            <TabItem Header="Optimisations">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20">
                        <GroupBox Header="Category 1">
                            <StackPanel>
                                <CheckBox Content="Option A"/>
                                <CheckBox Content="Test"/>
                                <CheckBox Content="Option B"/>
                                <CheckBox Content="Option C"/>
                            </StackPanel>
                        </GroupBox>
                        
                        <GroupBox Header="Category 2">
                            <StackPanel>
                                <CheckBox Content="Enable Feature X"/>
                                <CheckBox Content="Enable Feature Y"/>
                            </StackPanel>
                        </GroupBox>

                        <Button Content="Run Optimisations" HorizontalAlignment="Left" Margin="0,10,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Install">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20">
                        <GroupBox Header="Category A">
                            <StackPanel>
                                <CheckBox Content="Check System Status"/>
                                <CheckBox Content="Verify Logs"/>
                            </StackPanel>
                        </GroupBox>
                        <Button Content="Install Selected" HorizontalAlignment="Left" Margin="0,10,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Settings">
                <Grid>
                    <TextBlock Text="Settings are currently empty." HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#999" FontSize="16"/>
                </Grid>
            </TabItem>

        </TabControl>

        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,12,20,0">
            <TextBlock Text="Welcome, $username" VerticalAlignment="Center" FontSize="16" Foreground="#555" Margin="0,0,15,0"/>
            $userPicXaml
        </StackPanel>
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

$window.ShowDialog() | Out-Null
