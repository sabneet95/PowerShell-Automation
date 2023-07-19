# PowerShell Automation Repository

This repository is dedicated to the implementation and exploration of PowerShell automation scripts.

## Table of Contents

1. [Introduction](#introduction)
2. [Synopsis](#synopsis)
3. [Description](#description)
4. [Prerequisites](#prerequisites)
5. [Functions](#functions)
    - [Test-Admin](#test-admin)
    - [Install-Winget](#install-winget)
    - [Test-Preqs](#test-prereqs)
    - [Set-DisplayScaling](#set-displayscaling)
    - [Set-PowerPlan](#set-powerplan)
    - [Set-Clipboard](#set-clipboard)
    - [Set-System](#set-system)
    - [Set-Background](#set-background)
    - [Set-Colors](#set-colors)
    - [Set-Lockscreen](#set-lockscreen)
    - [Set-StartMenu](#set-startmenu)
    - [Set-Taskbar](#set-taskbar)
    - [Set-Personalization](#set-personalization)
    - [Set-VideoPlayback](#set-videoplayback)
    - [Set-Apps](#set-apps)
    - [Set-Time](#set-time)
    - [Set-Time-Language](#set-time-language)
    - [Set-Mouse-Pointer](#set-mouse-pointer)
    - [Set-Accessibility](#set-accessibility)
    - [Set-Windows-Settings](#set-windows-settings)
    - [Set-Network-Settings](#set-network-settings)
    - [Install-AdGuardHome](#install-adguardhome)
    - [Install-Dev-Tools](#install-dev-tools)
    - [Set-Terminal](#set-terminal)
    - [Install-MATLAB](#install-matlab)
    - [Install-GPU-Software](#install-gpu-software)
    - [Install-Productivity-Software](#install-productivity-software)
6. [Usage](#usage)
7. [Contributing](#contributing)
8. [License](#license)

## 1. Introduction <a name="introduction"></a>

This script is designed to automate the configuration of system settings, software installation, and other customizations for Windows environments. The script is intended for use in Windows environments and requires administrative privileges to run successfully. It performs various tasks, including setting display scaling, power plan, clipboard settings, background image, accent colors, lock screen settings, start menu settings, taskbar settings, and more.

## 2. Synopsis <a name="synopsis"></a>

This script sets various system settings and installs software on Windows environments.


## 3. Description <a name="description"></a>

The script automates the process of configuring various system settings and installing software on Windows environments. It uses Windows PowerShell to interact with system APIs and make the necessary changes. The script checks for administrative privileges before proceeding, and it also checks if the "winget" package manager is installed. If "winget" is not found, it will download and install it.

The main functionalities of the script include:

- Setting display scaling for high-resolution displays.
- Setting the power plan to "Ultimate Performance" for maximum performance.
- Enabling clipboard history and cloud clipboard synchronization.
- Setting a custom wallpaper as the background image.
- Setting the accent color to Turf Green for a personalized appearance.
- Disabling tips and tricks on the lock screen.
- Configuring the start menu to show more pins, no recent apps, and no recommendations.
- Removing the chat icon from the taskbar.
- Enhancing video playback settings.
- Setting the timezone to Eastern Standard Time.
- Changing the mouse pointer to a custom lime-colored cursor.
- Installing and configuring AdGuard Home for ad-blocking DNS.
- Installing various developer tools and IDEs.
- Setting up the Windows Terminal with a custom configuration.
- Installing MATLAB and GPU-related software.
- Installing productivity software like Microsoft Office, Grammarly, Firefox, Slack, etc.

## 4. Prerequisites <a name="prerequisites"></a>

- The script is intended for use in Windows environments.
- Administrative privileges are required to run the script successfully.
- The script uses the "winget" package manager for software installation, which should be available on Windows 10 or later. If not available, the script will download and install it.

## 5. Functions <a name="functions"></a>

### Test-Admin <a name="test-admin"></a>

Checks if the current user has administrative privileges. If not, it will prompt the user to run the script with administrative rights.

### Install-Winget <a name="install-winget"></a>

Checks if the "winget" package manager is installed. If not, it will download the latest version from GitHub and install it.

### Test-Preqs <a name="test-prereqs"></a>

Checks the prerequisites before running the script. It calls the `Test-Admin` and `Install-Winget` functions.

### Set-DisplayScaling <a name="set-displayscaling"></a>

Sets the display scaling for high-resolution displays to provide a better user experience and prevent UI elements from appearing too small.

### Set-PowerPlan <a name="set-powerplan"></a>

Sets the power plan to "Ultimate Performance," maximizing the system's performance.

### Set-Clipboard <a name="set-clipboard"></a>

Enables clipboard history and syncing across devices for improved productivity.

### Set-System <a name="set-system"></a>

Sets various system settings, including display scaling, power plan, and clipboard settings.

### Set-Background <a name="set-background"></a>

Sets a custom wallpaper as the background image to personalize the desktop.

### Set-Colors <a name="set-colors"></a>

Sets the accent color to Turf Green, providing a personalized appearance.

### Set-Lockscreen <a name="set-lockscreen"></a>

Turns off tips and tricks on the lock screen for a cleaner look.

### Set-StartMenu <a name="set-startmenu"></a>

Configures the start menu to show more pins, no recent apps, and no recommendations.

### Set-Taskbar <a name="set-taskbar"></a>

Removes the chat icon from the taskbar for a cleaner look.

### Set-Personalization <a name="set-personalization"></a>

Sets various personalization settings, including background, accent color, lock screen, start menu, and taskbar settings.

### Set-VideoPlayback <a name="set-videoplayback"></a>

Enhances video playback settings to improve the viewing experience.

### Set-Apps <a name="set-apps"></a>

Sets various app-related settings, including video playback settings.

### Set-Time <a name="set-time"></a>

Sets the system timezone to Eastern Standard Time.

### Set-Time-Language <a name="set-time-language"></a>

Sets the system time settings.

### Set-Mouse-Pointer <a name="set-mouse-pointer"></a>

Changes the mouse pointer to a custom lime-colored cursor for better visibility.

### Set-Accessibility <a name="set-accessibility"></a>

Sets various accessibility settings, including the mouse pointer.

### Set-Windows-Settings <a name="set-windows-settings"></a>

Sets and optimizes various Windows settings, including system, personalization, apps, time, and accessibility.

### Set-Network-Settings <a name="set-network-settings"></a>

Sets and optimizes network settings, including congestion control algorithm, MTU, general TCP settings, and more.

### Install-AdGuardHome <a name="install-adguardhome"></a>

Installs AdGuard Home and sets it as the ad-blocking DNS for improved privacy and security.

### Install-Dev-Tools <a name="install-dev-tools"></a>

Installs basic developer tools, such as terminal tools, Visual C++ redistributables, IDEs, Git tools, programming languages, and game development and 3D tools.

### Set-Terminal <a name="set-terminal"></a>

Sets the Windows Terminal settings with a custom configuration for an enhanced terminal experience.

### Install-MATLAB <a name="install-matlab"></a>

Installs MATLAB using the provided setup file and installer input file for scientific and engineering computations.

### Install-GPU-Software <a name="install-gpu-software"></a>

Installs GPU-related software, such as the NVIDIA control panel, GeForce Experience, MSI Afterburner, and more, for optimal graphics performance.

### Install-Productivity-Software <a name="install-productivity-software"></a>

Installs productivity software, including Microsoft Office, Grammarly, Tableau, Firefox, Slack, Zoom, HP Smart, Microsoft PowerToys, AutoHotkey, and more.

## 6. Usage <a name="usage"></a>

To run the script, open a PowerShell window with administrative privileges and execute the script file. Make sure the script file is in the current directory or provide the full path if it's located elsewhere.

```powershell
.\WindowsConfigScript.ps1
```
## 7. Contributing <a name="contributing"></a>

If you would like to contribute to this repository, please follow these guidelines:

* Create an issue to discuss the changes you would like to make
* Fork the repository and make the changes
* Submit a pull request for review and merging
* Please make sure to update tests as appropriate

## 8. License <a name="license"></a>
This repository is licensed under the [MIT](https://choosealicense.com/licenses/mit/) License.

