<#
.SYNOPSIS
This script sets various system settings and installs software on Windows environments.

.DESCRIPTION
This script automates the configuration of system settings, software installation, and other customizations for Windows.

.AUTHOR
Sabneet Bains

.VERSION
1.0

.NOTES
This script is intended for Windows environments and requires administrative privileges to run.

#>

# Error handling function
function Show-Error {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "`n  -◯  $errorPrefix $Message ❌ `n" -ForegroundColor Red
    throw $Message
}


# Error action preference set to 'Stop' to treat all errors as terminating errors
$ErrorActionPreference = 'Stop'

# Function to check for administrative privileges and set execution policy.
function Test-Admin {
    Write-Host "`n✨ Checking for administrative privileges... `n" -ForegroundColor Cyan

    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    if (-Not $currentUser.IsInRole($adminRole)) {
        Show-Error "This script requires administrative privileges. Please run it as an administrator!"
        exit 1
    }

    Write-Host "`n  -◯  administrative privileges checked ✅ `n" -ForegroundColor Yellow
}

# Function to check if winget is installed and install it if not.
function Install-Winget {
    Write-Host "`n✨ Checking if winget is installed... `n" -ForegroundColor Cyan

    $Winget = Get-AppxPackage Microsoft.DesktopAppInstaller

    if ($Winget.Version -ge "1.12.11692.0") {
        Write-Host "`n  -◯  winget is already installed ✅ `n" -ForegroundColor Yellow
        return
    }
    else {
        Write-Host "`n  -◯  trying to install winget... `n" -ForegroundColor Yellow

        $progressPreference = 'silentlyContinue'
        $latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
        $latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]

        Write-Information "downloading winget to artifacts directory..."
        Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "./$latestWingetMsixBundle"

        $wingetMsixBundlePath = "$PSScriptRoot\$latestWingetMsixBundle"
        if (-not (Test-Path $wingetMsixBundlePath)) {
            Write-Error "Failed to download winget. The msixbundle file is missing."
            return
        }
        Write-Information "installing winget..."

        $wingetInstallResult = Start-Process -FilePath "winget" -ArgumentList "install" -Wait -PassThru -NoNewWindow
        if ($wingetInstallResult.ExitCode -ne 0) {
            Write-Error "Failed to install winget."
            return
        }

        Write-Host "`n  -◯  winget successfully installed ✅ `n" -ForegroundColor Yellow
    }
}

# Function to check prerequisites.
function Test-Preqs {
    Test-Admin
    Install-Winget
}

Test-Preqs

# Define a C# class for calling WinAPI.
Add-Type -TypeDefinition @'
using System;

public class SysParamsInfo {
    [System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);

    const int SPI_SETCURSORS = 0x0057;
    const int SPI_SETCURSORSHADOW = 0x101B;
    const int SPI_SETDESKWALLPAPER = 0x0014;
    const int SPI_SETLOGICALDPIOVERRIDE = 0x009F;

    const int SPIF_UPDATEINIFILE = 0x01;
    const int SPIF_SENDCHANGE = 0x02;

    public static void UpdateCursor(bool Shadow) {
        SystemParametersInfo(SPI_SETCURSORSHADOW, 0, Convert.ToUInt32(Shadow), SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
        SystemParametersInfo(SPI_SETCURSORS, 0, 0, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }

    public static void UpdateWallpaper() {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, 0, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }

    public static void UpdateScaling(int DPI) {
        SystemParametersInfo(SPI_SETLOGICALDPIOVERRIDE, unchecked((uint)DPI), 0, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
'@

# Function to set the display scaling. Valid values are -7 to 0, where:
# 0 = 300%, -1 = 250%, -2 = 225%, -3 = 200%, -4 = 175%, -5 = 150%, -6 = 125%, -7 = 100%
function Set-DisplayScaling {
    param (
        [int]$DPI = -3
    )

    Write-Host "`n✨ Setting display scaling... `n" -ForegroundColor Cyan

    try {
        [SysParamsInfo]::UpdateScaling($DPI)
    }
    catch {
        Show-Error "Failed to set display scaling. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  display scaling set ✅ `n" -ForegroundColor Yellow
}

# Function to set the power plan to ultimate performance.
function Set-PowerPlan {
    # Power plan GUID for "Ultimate Performance"
    $powerPlanGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $powerPlanName = "(Ultimate Performance)"

    Write-Host "`n✨ Setting power plan... `n" -ForegroundColor Cyan

    try {
        $powerScheme = powercfg /L | Select-String -Pattern $powerPlanName
        if (-not $powerScheme) {
             powercfg -duplicatescheme $powerPlanGUID
        }
        $newPowerPlanGUID = powercfg /L | findstr \"(Ultimate Performance)" | ForEach-Object { $_.Split()[3] }
        powercfg /setactive $newPowerPlanGUID
    }
    catch {
        Show-Error "Failed to set power plan. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  power plan set ✅ `n" -ForegroundColor Yellow
}

# Function to set the clipboard history to enabled and syncs across devices.
function Set-Clipboard {
    Write-Host "`n✨ Setting clipboard settings... `n" -ForegroundColor Cyan

    try {
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Clipboard" -name EnableClipboardHistory -value 00000001
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Clipboard" -name CloudClipboardAutomaticUpload -value 00000001
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Clipboard" -name EnableCloudClipboard -value 00000001
    }
    catch {
        Show-Error "Failed to set clipboard settings. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  clipboard settings set ✅ `n" -ForegroundColor Yellow
}

# Function to set the following system settings: display, power, and clipboard.
function Set-System {
    Set-DisplayScaling
    Set-PowerPlan
    Set-Clipboard
}

# Function to set the background image to a custom wallpaper.
function Set-Background {
    param (
        [string]$WallpaperPath = "$env:OneDrive\Pictures\Wallpapers\Scenic.jpg"
    )

    Write-Host "`n✨ Setting wallpaper... `n" -ForegroundColor Cyan

    try {
        Set-ItemProperty -path "HKCU:\Control Panel\Desktop" -name WallPaper -value $WallpaperPath
        [SysParamsInfo]::UpdateWallpaper()
    }
    catch {
        Show-Error "Failed to set wallpaper. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  wallpaper set ✅ `n" -ForegroundColor Yellow
}

# Function to set the accent color to Turf Green.
function Set-Colors {
    Write-Host "`n✨ Setting accent colors... `n" -ForegroundColor Cyan

    try {
        Set-ItemProperty -path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -name AppsUseLightTheme -Value 0 -Type Dword -Force
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" -name AccentPalette -value ([byte[]](0x5F,0xFF,0xAF,0x00,0x26,0xFF,0x8E,0x00,0x00,0xE7,0x75,0x00,0x00,0xCC,0x6A,0x00,0x00,0xB2,0x5A,0x00,0x00,0x76,0x35,0x00,0x00,0x3F,0x13,0x00,0xE3,0x00,0x8C,0x00))
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" -name StartColorMenu -value 4284133888
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" -name AccentColorMenu -value 4285189120
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\DWM" -name AccentColor -value 4285189120
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\DWM" -name ColorizationAfterglow -value 3288386666
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\DWM" -name ColorizationColor -value 3288386666
    }
    catch {
        Show-Error "Failed to set accent colors. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  accent colors set ✅ `n" -ForegroundColor Yellow
}

# Function to turn off tips and tricks on the lock screen.
function Set-Lockscreen {
    Write-Host "`n✨ Setting lock screen settings... `n" -ForegroundColor Cyan

    try {
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -name RotatingLockScreenOverlayEnabled -value 00000000
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -name SubscribedContent-338387Enabled -value 00000000
    }
    catch {
        Show-Error "Failed to set lock screen settings. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  lock screen settings set ✅ `n" -ForegroundColor Yellow
}

# Function to set the start menu to more pins, no recent apps, and no recommendations.
function Set-StartMenu {
    Write-Host "`n✨ Setting start menu settings... `n" -ForegroundColor Cyan

    try {
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name Start_Layout -value 1
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name Start_TrackDocs -value 0
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name Start_IrisRecommendations -value 0
    }
    catch {
        Show-Error "Failed to set start menu settings. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  start menu settings set ✅ `n" -ForegroundColor Yellow
}

# Function to remove the chat icon from the taskbar.
function Set-Taskbar {
    Write-Host "`n✨ Setting taskbar settings... `n" -ForegroundColor Cyan

    try {
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name TaskbarMn -value 0
    }
    catch {
        Show-Error "Failed to set taskbar settings. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  taskbar settings set ✅ `n" -ForegroundColor Yellow
}

# Function to set the following personalization settings: background, color, lockscreen, start, and taskbar.
function Set-Personalization {
    Set-Background
    Set-Colors
    Set-Lockscreen
    Set-StartMenu
    Set-Taskbar
}

# Function to enhances video playback.
function Set-VideoPlayback {
    Write-Host "`n✨ Setting video playback settings... `n" -ForegroundColor Cyan

    try {
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\VideoSettings" -name EnableAutoEnhanceDuringPlayback -value 1
    }
    catch {
        Show-Error "Failed to set video playback settings. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  video playback settings set ✅ `n" -ForegroundColor Yellow
}

# Function to set the following apps settings: video playback.
function Set-Apps {
    Set-VideoPlayback
}

# Function to set the timezone to Eastern Standard Time.
function Set-Time {
    param (
        [string]$TimeZone = "Eastern Standard Time"
    )

    Write-Host "`n✨ Setting timezone... `n" -ForegroundColor Cyan

    try {
        Set-TimeZone -Name $TimeZone
    }
    catch {
        Show-Error "Failed to set timezone. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  timezone set ✅ `n" -ForegroundColor Yellow
}

# Function to set the following system settings: time.
function Set-Time-Language {
    Set-Time
}

# Function to change the mouse pointer to a custom lime colored cursor.
function Set-Mouse-Pointer {
    param (
        [bool]$Shadow = $true
    )

    Write-Host "`n✨ Setting mouse pointer... `n" -ForegroundColor Cyan

    try {
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name Appstarting -value "$env:AppData\Local\Microsoft\Windows\Cursors\busy_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name Arrow -value "$env:AppData\Local\Microsoft\Windows\Cursors\arrow_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name Crosshair -value "$env:AppData\Local\Microsoft\Windows\Cursors\cross_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name Hand -value "$env:AppData\Local\Microsoft\Windows\Cursors\link_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name Help -value "$env:AppData\Local\Microsoft\Windows\Cursors\helpsel_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name IBeam -value "$env:AppData\Local\Microsoft\Windows\Cursors\ibeam_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name No -value "$env:AppData\Local\Microsoft\Windows\Cursors\unavail_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name NWPen -value "$env:AppData\Local\Microsoft\Windows\Cursors\pen_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name Person -value "$env:AppData\Local\Microsoft\Windows\Cursors\person_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name Pin -value "$env:AppData\Local\Microsoft\Windows\Cursors\pin_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name SizeAll -value "$env:AppData\Local\Microsoft\Windows\Cursors\move_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name SizeNESW -value "$env:AppData\Local\Microsoft\Windows\Cursors\nesw_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name SizeNS -value "$env:AppData\Local\Microsoft\Windows\Cursors\ns_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name SizeNWSE -value "$env:AppData\Local\Microsoft\Windows\Cursors\nwse_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name SizeWE -value "$env:AppData\Local\Microsoft\Windows\Cursors\ew_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name UpArrow -value "$env:AppData\Local\Microsoft\Windows\Cursors\up_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name Wait -value "$env:AppData\Local\Microsoft\Windows\Cursors\wait_eoa.cur"
        Set-ItemProperty -path "HKCU:\Control Panel\Cursors" -name CursorBaseSize -value 32
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Accessibility" -name CursorColor -value 65471
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Accessibility" -name CursorType -value 6
        [SysParamsInfo]::UpdateCursor($Shadow)
    }
    catch {
        Show-Error "Failed to set mouse pointer settings. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  mouse pointer set ✅ `n" -ForegroundColor Yellow
}

# Function to set the following accessibility settings: mouse pointer.
function Set-Accessibility {
    Set-Mouse-Pointer
}

# Function to set the following windows settings: system, personalization, apps, time, and accessibility.
function Set-Windows-Settings {
    Set-System
    Set-Personalization
    Set-Apps
    Set-Time-Language
    Set-Accessibility
}

# Function to set and optimize network settings.
function Set-Network-Settings {
    param (
        [string]$CongestionControlAlgorithm = "bbr2"
    )
    Write-Host "`n✨ Setting network... `n" -ForegroundColor Cyan

    # set congestion control algorithm
    try {
        netsh int tcp set supplemental Template=Internet CongestionProvider=$CongestionControlAlgorithm
        netsh int tcp set supplemental Template=Datacenter CongestionProvider=$CongestionControlAlgorithm
        netsh int tcp set supplemental Template=Compat CongestionProvider=$CongestionControlAlgorithm
        netsh int tcp set supplemental Template=DatacenterCustom CongestionProvider=$CongestionControlAlgorithm
        netsh int tcp set supplemental Template=InternetCustom CongestionProvider=$CongestionControlAlgorithm
    }
    catch {
        Show-Error "Failed to set congestion control algorithm. Error: $_"
        exit 1
    }

    # set mtu to 1500
    try {
        netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent
        netsh interface ipv6 set subinterface "Ethernet" mtu=1500 store=persistent
        netsh interface ipv4 set subinterface "Wi-Fi" mtu=1500 store=persistent
        netsh interface ipv6 set subinterface "Wi-Fi" mtu=1500 store=persistent
    }
    catch {
        Show-Error "Failed to set mtu. Error: $_"
        exit 1
    }

    # set general tcp settings
    try {
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name DefaultTTL -value 64
        Set-NetTCPSetting -SettingName internet -AutoTuningLevelLocal Normal
        Set-NetTCPSetting -SettingName internet -ScalingHeuristics Disabled
        Set-NetTCPSetting -SettingName internet -Timestamps Disabled
        Set-NetTCPSetting -SettingName internet -MaxSynRetransmissions 2
        Set-NetTCPSetting -SettingName internet -NonSackRttResiliency Disabled
        Set-NetTCPSetting -SettingName internet -InitialRto 2000
        Set-NetTCPSetting -SettingName internet -MinRto 300
        
        Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled
        Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled
        Set-NetOffloadGlobalSetting -Chimney Disabled

        Disable-NetAdapterLso -Name "*"
        Enable-NetAdapterChecksumOffload -Name "*"
    }
    catch {
        Show-Error "Failed to set general tcp settings. Error: $_"
        exit 1
    }

    # set max connections per server
    try {
        Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_MAXCONNECTIONSPER1_0SERVER" -name explorer.exe -value 10
        Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_MAXCONNECTIONSPERSERVER" -name explorer.exe -value 10
    }
    catch {
        Show-Error "Failed to set max connections per server. Error: $_"
        exit 1
    }

    # set host resolution priority
    try {
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -name LocalPriority -value 4
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -name HostsPriority -value 5
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -name DnsPriority -value 6
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -name NetbtPriority -value 7
    }
    catch {
        Show-Error "Failed to set host resolution priority. Error: $_"
        exit 1
    }

    # set dynamic port allocation
    try {
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name MaxUserPort -value 65534
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name TcpTimedWaitDelay -value 30
    }
    catch {
        Show-Error "Failed to set dynamic port allocation. Error: $_"
        exit 1
    }

    # set network qos
    try {
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -name NonBestEffortLimit -value 0
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" -name "Do not use NLA" -value 1
    }
    catch {
        Show-Error "Failed to set network qos. Error: $_"
        exit 1
    }

    # set network throttling index
    try {
        Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -name NetworkThrottlingIndex -value 4294967295
        Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -name SystemResponsiveness -value 0
    }
    catch {
        Show-Error "Failed to set network throttling index. Error: $_"
        exit 1
    }

    # set network memory allocation
    try {
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -name LargeSystemCache -value 1
        Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -name Size -value 3
    }
    catch {
        Show-Error "Failed to set network memory allocation. Error: $_"
        exit 1
    }

    Write-Host "`n  -◯  network set ✅ `n" -ForegroundColor Yellow
}

# Function to install adguard home and set the adblocking dns.
function Install-AdGuardHome {
    param (
        [string]$AdguardHomePath = "$env:OneDrive\Documents\Code\AdGuardHome\AdGuardHome.exe"
    )

    Write-Host "`n✨ Installing adguard home... `n" -ForegroundColor Cyan

    try {
        Start-Process -FilePath $AdguardHomePath -ArgumentList "-s install"
        Set-DNSClientServerAddress "Ethernet" -ServerAddresses ("127.0.0.1")
        Set-DNSClientServerAddress "Ethernet" -ServerAddresses ("::1")
        Set-DNSClientServerAddress "Wi-Fi" -ServerAddresses ("127.0.0.1")
        Set-DNSClientServerAddress "Wi-Fi" -ServerAddresses ("::1")
        Clear-DnsClientCache
    }
    catch {
        Show-Error "Failed to install AdGuard Home. Error: $_"
    }

    Write-Host "`n  -◯  adguard home installed ✅ `n" -ForegroundColor Yellow
}

# Function to install basic developer tools.
function Install-Dev-Tools {
    $softwareList = @(
    # terminal tools
        "Microsoft.WindowsTerminal"
        "Microsoft.PowerShell"
        "JanDeDobbeleer.OhMyPosh"
    # visual C++ redistributables
        "Microsoft.VCRedist.2015+.x86"
        "Microsoft.VCRedist.2015+.x64"
        "Microsoft.VCRedist.2013.x86"
        "Microsoft.VCRedist.2013.x64"
        "Microsoft.VCRedist.2012.x86"
        "Microsoft.VCRedist.2012.x64"
        "Microsoft.VCRedist.2010.x86"
        "Microsoft.VCRedist.2010.x64"
        "Microsoft.VCRedist.2008.x86"
        "Microsoft.VCRedist.2008.x64"
    # IDEs
        "Microsoft.VisualStudio.2022.Community"
        "Microsoft.VisualStudioCode"
        "Google.AndroidStudio"
    # git tools
        "Git.Git"
        "GitHub.GitHubDesktop"
        "GitHub.GitLFS"
    # programming languages
        "Python.Python.3.12"
        "Rustlang.Rust.MSVC"
        "Rustlang.Rustup"
    # game development and 3D tools
        "Unity.UnityHub"
        "BlenderFoundation.Blender"
        "9NBLGGH5FV99" # Paint 3D
        "9NBLGGH42THS" # 3D Viewer
    # dev home
        "Microsoft.DevHome"
    # Add more software to install here
    )

    Write-Host "`n✨ Installing dev tools... `n" -ForegroundColor Cyan

    try {
        foreach ($software in $softwareList) {
            winget install -e --id $software --accept-source-agreements --accept-package-agreements
        }
    }
    catch {
        Show-Error "Failed to install software. Error: $_"
    }

    Write-Host "`n  -◯  dev tools installed ✅ `n" -ForegroundColor Yellow
}

# Function to set the windows terminal settings
function Set-Terminal {
    param (
        [string]$SettingsFile = "$env:OneDrive\Documents\WindowsTerminal\settings.json"
    )

    Write-Host "`n✨ Setting terminal... `n" -ForegroundColor Cyan

    try {
        Remove-Item -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Force
        New-Item -ItemType HardLink -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Value $SettingsFile -Force
    }
    catch {
        Show-Error "Failed to set terminal settings. Error: $_"
    }

    Write-Host "`n  -◯  terminal set ✅ `n" -ForegroundColor Yellow
}

# Function to install MATLAB
function Install-MATLAB {
    param (
        [string]$InstallerPath = "$env:OneDrive\Documents\Code\MATLAB\R2023a\setup.exe",
        [string]$InstallerInputFile = "$env:OneDrive\Documents\Code\MATLAB\R2023a\installer_input.txt"
    )

    Write-Host "`n✨ Installing MATLAB... `n" -ForegroundColor Cyan

    try {
        Start-Process -FilePath $InstallerPath -ArgumentList "-inputFile $InstallerInputFile"
    }
    catch {
        Show-Error "Failed to install MATLAB. Error: $_"
    }

    Write-Host "`n  -◯  MATLAB installed ✅ `n" -ForegroundColor Yellow
}

# Function to install gpu software
function Install-GPU-Software {
    $softwareList = @(
    # NVIDIA software
        "9NF8H0H7WMLT" # NVIDIA Control Panel
        "Nvidia.GeForceExperience"
        "Nvidia.PhysX"
    # MSI Afterburner
        "Guru3D.Afterburner"
    # Add more software to install here
    )
    
    Write-Host "`n✨ Installing GPU software... `n" -ForegroundColor Cyan

    try {
        foreach ($software in $softwareList) {
            winget install -e --id $software --accept-source-agreements --accept-package-agreements
        }
    }
    catch {
        Show-Error "Failed to install GPU software. Error: $_"
    }

    Write-Host "`n  -◯  GPU software installed ✅ `n" -ForegroundColor Yellow
}

# Function to install productivity software
function Install-Productivity-Software {
    $softwareList = @(
    # microsoft office and grammarly
        "Microsoft.Office"
        "Grammarly.Grammarly.Office"
    # tableu
        "Tableau.Desktop"
    # firefox
        "Mozilla.Firefox"
    # communication software
        "SlackTechnologies.Slack"
        "Zoom.Zoom"
    # pc manager
        "Microsoft.PCManager"
    # logitech software
        "Logitech.OptionsPlus"
        "Logitech.UnifyingSoftware"
    # printer software
        "9WZDNCRFHWLH" # HP Smart
    # poweruser tools
        "QL-Win.QuickLook"
        "Microsoft.PowerToys"
        "AutoHotkey.AutoHotkey"
    # adblockers
        "Adguard.Adguard"
    # Add more software to install here
    )
    
    Write-Host "`n✨ Installing productivity software... `n" -ForegroundColor Cyan

    try {
        foreach ($software in $softwareList) {
            winget install -e --id $software --accept-source-agreements --accept-package-agreements
        }
    }
    catch {
        Show-Error "Failed to install productivity software. Error: $_"
    }

    Write-Host "`n  -◯  productivity software installed ✅ `n" -ForegroundColor Yellow
}

# Function to import microsoft office registry settings
function Set-MicrosoftOffice {
    param (
        [string]$OfficeSettings = "$env:OneDrive\Documents\Code\Office\settings.reg"
    )

    Write-Host "`n✨ Setting microsoft office... `n" -ForegroundColor Cyan

    try {
        reg import $OfficeSettings
    }
    catch {
        Show-Error "Failed to import Microsoft Office settings. Error: $_"
    }

    Write-Host "`n  -◯  microsoft office set ✅ `n" -ForegroundColor Yellow
}

# Function to install media software
function Install-Media-Software {
    $softwareList = @(
    # image and video extensions
        "9PMMSR1CGPWG" # HEIF Image Extensions
        "9NCTDW2W1BH8" # Raw Image Extension
        "9PG2DK419DRG" # Webp Image Extensions
        "9MVZQVXJBQ9V" # AV1 Video Extension
        "9N4D0MSMP0PT" # VP9 Video Extensions
        "9N5TDP8VCMHS" # Web Media Extensions
    # sound software
        "9NHTLWTKFZNB" # Galaxy Buds
    # media players
        "VideoLAN.VLC"
        "HandBrake.HandBrake"
        "OBSProject.OBSStudio"
        "9P1J8S7CCWWT" # Clipchamp
    # Add more software to install here
    )

    Write-Host "`n✨ Installing media software... `n" -ForegroundColor Cyan

    try {
        foreach ($software in $softwareList) {
            winget install -e --id $software --accept-source-agreements --accept-package-agreements
        }
    }
    catch {
        Show-Error "Failed to install media software. Error: $_"
    }

    Write-Host "`n  -◯  media software installed ✅ `n" -ForegroundColor Yellow   
}

# Function to install adobe creative cloud
function Install-Adobe-Creative-Cloud {
    param (
        [string]$AdobeSetupPath = "$env:OneDrive\Documents\Code\Adobe\setup.exe"
    )

    $softwareList = @(
        # adobe acrobat 64-bit
            "Adobe.Acrobat.Reader.64-bit"
        # Add more software to install here
        )

    Write-Host "`n✨ Installing adobe creative cloud... `n" -ForegroundColor Cyan

    try {
        Start-Process -FilePath $AdobeSetupPath
        foreach ($software in $softwareList) {
            winget install -e --id $software --accept-source-agreements --accept-package-agreements
        }
    }
    catch {
        Show-Error "Failed to install Adobe Creative Cloud. Error: $_"
    }

    Write-Host "`n  -◯  Adobe Creative Cloud installed ✅ `n" -ForegroundColor Yellow
}

# Function to remind about remaining manual installs.
function Install-Remaining-Software {
    Write-Host "`n⚠️  Remember you still have to intall: `n" -ForegroundColor Cyan
    Write-Host "  📌 Dolby Access" -ForegroundColor Red
    Write-Host "  📌 Unity `n" -ForegroundColor Red
}

# Main function
function Main {
    Set-Windows-Settings
    Set-Network-Settings
    Install-AdGuardHome
    Install-Dev-Tools
    Set-Terminal
    Install-MATLAB
    Install-GPU-Software
    Install-Productivity-Software
    Set-MicrosoftOffice
    Install-Media-Software
    Install-Adobe-Creative-Cloud
    Install-Remaining-Software

    Write-Host "`n🎉 Script completed successfully! `n" -ForegroundColor Cyan

    # Prompt for a restart
    $restartChoice = $(Write-Host "A restart is required to apply some settings. Do you want to restart now?" -ForegroundColor Red -NoNewLine) + $(Write-Host " (Y/N): " -NoNewLine; Read-Host)
    if ($restartChoice -eq "Y") {
        Restart-Computer -Force
    }
}

# Execute the main function
Main
