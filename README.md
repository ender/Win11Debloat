# Win11Debloat

[![GitHub Release](https://img.shields.io/github/v/release/ender/win11debloat?style=for-the-badge&label=Latest%20release)](https://github.com/ender/win11debloat/releases/latest)
[![Static Badge](https://img.shields.io/badge/Upstream%20Documentation-_?style=for-the-badge&logo=bookstack&color=grey)](https://github.com/Raphire/Win11Debloat/wiki/)

 Win11Debloat is a lightweight, easy to use PowerShell script that allows you to quickly declutter and customize your Windows experience, no installation required! You can use it to remove pre-installed apps, disable telemetry, remove intrusive interface elements and much more. No need to painstakingly go through all the settings yourself or remove apps one by one. Win11Debloat makes the process quick and easy!

This fork is a terminal-only build of Win11Debloat, intended for fully unattended/automated debloating: every tweak is driven entirely by command-line flags or a JSON config file ([`-Config`](#usage)), with no GUI. It is kept in sync with the upstream [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat) project via an automated pull request workflow. Please refer to the upstream [wiki](https://github.com/Raphire/Win11Debloat/wiki) for details on individual tweaks.

This fork always applies per-user tweaks to the **Default user profile hive** (`C:\Users\Default\NTUSER.DAT`), never to the current/invoking user's own profile. It's designed to be run once during Windows image preparation, from the built-in Administrator account in audit mode, before running `sysprep /generalize /oobe`. Every tweak gets baked into the Default profile, so every user account created after the sealed image is deployed inherits the applied settings automatically. The built-in Administrator's own profile is not modified, it's only the execution context used to apply the tweaks.

#### Did this script help you? Please consider buying me a cup of coffee to support my work

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M5C6UPC)

## Usage

> [!Warning]
> Great care went into making sure this script does not unintentionally break any OS functionality, but use at your own risk! If you run into any issues, please report them [here](https://github.com/ender/win11debloat/issues).

### Quick method

Download & run the script automatically via PowerShell.

1. Open PowerShell or Terminal as an administrator.
2. Copy and paste the command below into PowerShell:

```PowerShell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/ender/win11debloat/master/Scripts/Get.ps1")))
```

3. Wait for the script to automatically download and launch Win11Debloat.
4. Carefully read through and follow the on-screen instructions.

This method supports command-line parameters to customize the behaviour of the script. Please click [here](https://github.com/Raphire/Win11Debloat/wiki/Command%E2%80%90line-Interface#parameters) for more information.

### Traditional method

<details>
  <summary>Manually download & run the script.</summary><br/>

  1. [Download the latest version of the script](https://github.com/ender/win11debloat/releases/latest), and extract the .ZIP file to your desired location.
  2. Navigate to the Win11Debloat folder
  3. Double click the `Run.bat` file to start the script. NOTE: If the console window immediately closes and nothing happens, try the advanced method below.
  4. Accept the Windows UAC prompt to run the script as administrator, this is required for the script to function.
  5. Carefully read through and follow the on-screen instructions.
</details>

### Advanced method

<details>
  <summary>Manually download the script & run the script via PowerShell. Recommended for advanced users.</summary><br/>

  1. [Download the latest version of the script](https://github.com/ender/win11debloat/releases/latest), and extract the .ZIP file to your desired location.
  2. Open PowerShell or Terminal as an administrator.
  3. Temporarily enable PowerShell execution by entering the following command:

  ```PowerShell
  Set-ExecutionPolicy Unrestricted -Scope Process -Force
  ```

  4. In PowerShell, navigate to the directory where the files were extracted. Example: `cd c:\Win11Debloat`
  5. Now run the script by entering the following command:

  ```PowerShell
  .\Win11Debloat.ps1
  ```

  6. Carefully read through and follow the on-screen instructions.

  This method supports command-line parameters to customize the behaviour of the script. Please click [here](https://github.com/Raphire/Win11Debloat/wiki/Command%E2%80%90line-Interface#parameters) for more information.
</details>

### Examples

See the [`examples`](./examples) folder for sample `-Config` files, an
`autounattend.xml` snippet for running Win11Debloat automatically in Audit
Mode before sysprep, and an Ansible playbook for driving it from an
image-build pipeline.

## Features

Below is an overview of the key features and functionality offered by Win11Debloat. You can visit the [the wiki](https://github.com/Raphire/Win11Debloat/wiki) for more details.

> [!Tip]
> All of the changes made by Win11Debloat can easily be reverted and almost all of the apps can be reinstalled through the Microsoft Store. You can visit [the wiki](https://github.com/Raphire/Win11Debloat/wiki/Reverting-Changes) for more information on reverting changes.

#### App Removal

- Remove a wide variety of preinstalled apps. Click [here](https://github.com/Raphire/Win11Debloat/wiki/App-Removal) for more info.

#### Privacy & Suggested Content

- Disable telemetry, diagnostic data, activity history, app-launch tracking & targeted ads.
- Disable tips, tricks, suggestions & ads across Windows, the lock screen and Microsoft Edge.
- Disable Windows location services, app location access and Find My Device location tracking.
- Hide Microsoft 365 ads on the Settings 'Home' page, or hide the 'Home' page entirely.

#### AI Features

- Disable & remove Microsoft Copilot, Windows Recall and Click to Do.
- Prevent AI service (WSAIFabricSvc) from starting automatically.
- Disable AI Features in Edge, Paint and Notepad.

#### System

- Disable the Drag Tray for sharing & moving files.
- Restore the old Windows 10 style context menu.
- Turn off Enhance Pointer Precision, also known as mouse acceleration.
- Disable the Sticky Keys keyboard shortcut.
- Disable Storage Sense automatic disk cleanup.
- Disable fast start-up to ensure a full shutdown.
- Disable BitLocker automatic device encryption.
- Disable network connectivity during Modern Standby to reduce battery drain.

#### Windows Update

- Prevent Windows from getting updates as soon as they're available.
- Prevent automatic restarts after updates while signed in.
- Disable sharing of downloaded updates with other PCs, also known as Delivery Optimization.

#### Appearance

- Enable dark mode for system and apps.
- Disable transparency, animations and visual effects.

#### Start Menu & Search

- Customize the start menu by removing pinned apps, hiding recommendations, and customizing the 'All Apps' section.
- Disable the Phone Link mobile devices integration in the start menu.
- Disable Bing web search & Copilot integration and Microsoft Store app suggestions in Windows search.

#### Taskbar

- Change taskbar alignment.
- Customize or hide taskbar buttons like the search bar, taskview and more.
- Disable widgets on the taskbar & lock screen.
- Enable the 'End Task' option in the taskbar right click menu to quickly force-close apps.
- Enable the 'Last Active Click' behavior in the taskbar app area. This allows you to repeatedly click on an application's icon in the taskbar to switch focus between the open windows of that application.
- Customize how app buttons are shown on the taskbar.

#### File Explorer

- Change the default location that File Explorer opens to.
- Show file extensions for known file types.
- Show hidden files, folders and drives.
- Hide the Home, Gallery or OneDrive section from the File Explorer navigation pane.
- Hide duplicate removable drive entries from the File Explorer navigation pane, so only the entry under 'This PC' remains.
- Add all common folders (Desktop, Downloads, etc.) back to 'This PC' in File Explorer.
- Change drive letter position or visibility in File Explorer.

#### Multi-tasking

- Disable window snapping.
- Disable Snap Assist and Snap Layout suggestions when dragging or snapping windows.
- Change whether tabs are shown when snapping windows or pressing Alt+Tab.

#### Optional Windows Features

- Enable Windows Sandbox, a lightweight desktop environment for safely running applications in isolation.
- Enable Windows Subsystem for Linux which allows you to run a Linux environment directly on Windows.

#### Other

- Disable Xbox Game Bar integration & game/screen recording. This also disables `ms-gamingoverlay`/`ms-gamebar` popups if you uninstall the Xbox Game Bar.
- Disable bloat in Brave browser (AI, Crypto, News, etc.)

## Contributing

We welcome contributions of all kinds! Please see our [Contributing Guidelines](.github/CONTRIBUTING.md) for detailed instructions on how to get started and best practices for contributing.

## License

Win11Debloat is licensed under the MIT license. See the LICENSE file for more information.
