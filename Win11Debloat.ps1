[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$Silent,
    [string]$LogPath,
    [switch]$RunDefaults,
    [switch]$RunDefaultsLite,
    [switch]$RunSavedSettings,
    [string]$Config,
    [string]$Apps,
    [switch]$RemoveApps,
    [switch]$RemoveGamingApps,
    [switch]$RemoveHPApps,
    [switch]$ForceRemoveEdge,
    [switch]$DisableDVR,
    [switch]$DisableGameBarIntegration,
    [switch]$EnableWindowsSandbox,
    [switch]$EnableWindowsSubsystemForLinux,
    [switch]$DisableTelemetry,
    [switch]$DisableSearchHistory,
    [switch]$DisableFastStartup,
    [switch]$DisableBitlockerAutoEncryption,
    [switch]$DisableModernStandbyNetworking,
    [switch]$DisableStorageSense,
    [switch]$DisableUpdateASAP,
    [switch]$PreventUpdateAutoReboot,
    [switch]$DisableDeliveryOptimization,
    [switch]$DisableBing,
    [switch]$DisableStoreSearchSuggestions,
    [switch]$DisableSearchHighlights,
    [switch]$DisableDesktopSpotlight,
    [switch]$DisableLockscreenTips,
    [switch]$DisableSuggestions,
    [switch]$DisableLocationServices,
    [switch]$DisableFindMyDevice,
    [switch]$DisableEdgeAds,
    [switch]$DisableBraveBloat,
    [switch]$DisableSettings365Ads,
    [switch]$DisableSettingsHome,
    [switch]$ShowHiddenFolders,
    [switch]$ShowKnownFileExt,
    [switch]$HideDupliDrive,
    [switch]$EnableDarkMode,
    [switch]$DisableTransparency,
    [switch]$DisableAnimations,
    [switch]$TaskbarAlignLeft,
    [switch]$CombineTaskbarAlways, [switch]$CombineTaskbarWhenFull, [switch]$CombineTaskbarNever,
    [switch]$CombineMMTaskbarAlways, [switch]$CombineMMTaskbarWhenFull, [switch]$CombineMMTaskbarNever,
    [switch]$MMTaskbarModeAll, [switch]$MMTaskbarModeMainActive, [switch]$MMTaskbarModeActive,
    [switch]$HideSearchTb, [switch]$ShowSearchIconTb, [switch]$ShowSearchLabelTb, [switch]$ShowSearchBoxTb,
    [switch]$HideTaskview,
    [switch]$DisableStartRecommended,
    [switch]$DisableStartAllApps, [switch]$StartAllAppsCategory, [switch]$StartAllAppsGrid, [switch]$StartAllAppsList,
    [switch]$DisableStartPhoneLink,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableClickToDo,
    [switch]$DisableAISvcAutoStart,
    [switch]$DisablePaintAI,
    [switch]$DisableNotepadAI,
    [switch]$DisableEdgeAI,
    [switch]$DisableWidgets,
    [switch]$HideChat,
    [switch]$EnableEndTask,
    [switch]$EnableLastActiveClick,
    [switch]$ClearStart,
    [string]$ReplaceStart,
    [switch]$RevertContextMenu,
    [switch]$DisableDragTray,
    [switch]$DisableMouseAcceleration,
    [switch]$DisableStickyKeys,
    [switch]$DisableWindowSnapping,
    [switch]$DisableSnapAssist,
    [switch]$DisableSnapLayouts,
    [switch]$HideTabsInAltTab, [switch]$Show3TabsInAltTab, [switch]$Show5TabsInAltTab, [switch]$Show20TabsInAltTab,
    [switch]$HideHome,
    [switch]$HideGallery,
    [switch]$ExplorerToHome,
    [switch]$ExplorerToThisPC,
    [switch]$ExplorerToDownloads,
    [switch]$ExplorerToOneDrive,
    [switch]$AddFoldersToThisPC,
    [switch]$HideOnedrive,
    [switch]$Hide3dObjects,
    [switch]$HideMusic,
    [switch]$HideIncludeInLibrary,
    [switch]$HideGiveAccessTo,
    [switch]$HideShare,
    [switch]$ShowDriveLettersFirst,
    [switch]$ShowDriveLettersLast,
    [switch]$ShowNetworkDriveLettersFirst,
    [switch]$HideDriveLetters
)

# Check if script is running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If script is not running as administrator ask user if they want to allow it
if (-not $isAdmin) {
    Write-Host "Win11Debloat must be run as Administrator." -ForegroundColor Red

    $choice = Read-Host "Restart as Administrator? (y/n)"

    if ($choice -match '^[Yy]$') {
        $elevatedArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath)

        foreach ($paramName in $PSBoundParameters.Keys) {
            $paramValue = $PSBoundParameters[$paramName]

            if ($paramValue -is [System.Management.Automation.SwitchParameter]) {
                if ($paramValue.IsPresent) {
                    $elevatedArgs += "-$paramName"
                }
            }
            else {
                $elevatedArgs += "-$paramName"
                $elevatedArgs += "$paramValue"
            }
        }

        if ($MyInvocation.UnboundArguments.Count -gt 0) {
            $elevatedArgs += $MyInvocation.UnboundArguments
        }

        Start-Process powershell -ArgumentList $elevatedArgs -Verb RunAs
    }
    exit
}

# Define script-level variables & paths
$script:Version = "2026.06.24"
$configPath = Join-Path $PSScriptRoot 'Config'
$logsPath = Join-Path $PSScriptRoot 'Logs'

$script:AppsListFilePath = Join-Path $configPath 'Apps.json'
$script:DefaultSettingsFilePath = Join-Path $configPath 'DefaultSettings.json'
$script:FeaturesFilePath = Join-Path $configPath 'Features.json'
$script:SavedSettingsFilePath = Join-Path $configPath 'LastUsedSettings.json'
$script:DefaultLogPath = Join-Path $logsPath 'Win11Debloat.log'
$script:RegfilesPath = Join-Path $PSScriptRoot 'Regfiles'
$script:AssetsPath = Join-Path $PSScriptRoot 'Assets'

$script:ControlParams = 'WhatIf', 'Confirm', 'Verbose', 'Debug', 'LogPath', 'Silent', 'RunDefaults', 'RunDefaultsLite', 'RunSavedSettings', 'Config'

# Check if current powershell environment is limited by security policies
if ($ExecutionContext.SessionState.LanguageMode -ne "FullLanguage") {
    Write-Error "Win11Debloat is unable to run on your system, powershell execution is restricted by security policies"
    Write-Output "Press any key to exit..."
    $null = [System.Console]::ReadKey()
    Exit
}

Clear-Host

# Ensure required Windows command paths are present in PATH for this session.
$system32Path = "$env:SystemRoot\System32"
if ($env:PATH -notmatch "(?i)(^|;)$([regex]::Escape($system32Path))(?=;|$)") {
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot;" + $env:PATH
    Write-Warning "System32 path was missing from PATH environment variable, it has been added for this session."
}

# Display ASCII art launch logo in CLI
Write-Host ""
Write-Host ""
Write-Host "                   " -NoNewline; Write-Host "      ^" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "     / \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "    /   \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "   /     \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  / ===== \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host "  ---  " -ForegroundColor White -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host " ( O ) " -ForegroundColor DarkCyan -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host "  ---  " -ForegroundColor White -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |       |" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host " /|       |\" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "/ |       | \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |  " -ForegroundColor DarkGray -NoNewline; Write-Host "'''" -ForegroundColor Red -NoNewline; Write-Host "  |" -ForegroundColor DarkGray -NoNewline; Write-Host "    *" -ForegroundColor Yellow
Write-Host "                   " -NoNewline; Write-Host "    (" -ForegroundColor Yellow -NoNewline; Write-Host "'''" -ForegroundColor Red -NoNewline; Write-Host ") " -ForegroundColor Yellow -NoNewline; Write-Host "   *  *" -ForegroundColor DarkYellow
Write-Host "                   " -NoNewline; Write-Host "    ( " -ForegroundColor DarkYellow -NoNewline; Write-Host "'" -ForegroundColor Red -NoNewline; Write-Host " )   " -ForegroundColor DarkYellow -NoNewline; Write-Host "*" -ForegroundColor Yellow
Write-Host ""
Write-Host "             Win11Debloat is launching..." -ForegroundColor White
Write-Host "                Keep this window open" -ForegroundColor DarkGray
Write-Host ""
Write-Host ""

# Log script output to 'Win11Debloat.log' at the specified path
if ($LogPath -and (Test-Path $LogPath)) {
    Start-Transcript -Path (Join-Path $LogPath 'Win11Debloat.log') -Append -IncludeInvocationHeader -Force | Out-Null
}
else {
    Start-Transcript -Path $script:DefaultLogPath -Append -IncludeInvocationHeader -Force | Out-Null
}

# Check if the device is domain-joined and warn the user (Group Policy may override changes)
try {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($null -ne $computerSystem -and $computerSystem.PartOfDomain) {
        Write-Warning "This machine is domain-joined. Group Policy may override changes made by Win11Debloat."
    }
}
catch { }

# Check if script has all required files
if (-not ((Test-Path $script:DefaultSettingsFilePath) -and (Test-Path $script:AppsListFilePath) -and (Test-Path $script:RegfilesPath) -and (Test-Path $script:AssetsPath) -and (Test-Path $script:FeaturesFilePath))) {
    Write-Error "Win11Debloat is unable to find required files, please ensure all script files are present"
    Write-Output ""
    Write-Output "Press any key to exit..."
    $null = [System.Console]::ReadKey()
    Exit
}

# Load feature info from file
$script:Features = @{}
try {
    $featuresData = Get-Content -Path $script:FeaturesFilePath -Raw | ConvertFrom-Json
    foreach ($feature in $featuresData.Features) {
        if ([string]::IsNullOrWhiteSpace([string]$feature.FeatureId) -or [string]::IsNullOrWhiteSpace([string]$feature.Label) -or [string]::IsNullOrWhiteSpace([string]$feature.ApplyText)) {
            Write-Warning "Feature '$($feature.FeatureId)' is missing a FeatureId, Label, or ApplyText in Features.json and will be skipped."
            continue
        }
        $script:Features[$feature.FeatureId] = $feature
    }
}
catch {
    Write-Error "Failed to load feature info from Features.json file"
    Write-Output ""
    Write-Output "Press any key to exit..."
    $null = [System.Console]::ReadKey()
    Exit
}

# Check if WinGet is installed & if it is, check if the version is at least v1.4
try {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $script:WingetInstalled = $true
    }
    else {
        $script:WingetInstalled = $false
    }
}
catch {
    Write-Error "Unable to determine if WinGet is installed, winget command failed: $_"
    $script:WingetInstalled = $false
}

# Show WinGet warning that requires user confirmation, Suppress confirmation if Silent parameter was passed
if (-not $script:WingetInstalled -and -not $Silent) {
    Write-Warning "WinGet is not installed or outdated, this may prevent Win11Debloat from removing certain apps"
    Write-Output ""
    Write-Output "Press any key to continue anyway..."
    $null = [System.Console]::ReadKey()
}



##################################################################################################################
#                                                                                                                #
#                                                FUNCTION IMPORTS                                                #
#                                                                                                                #
##################################################################################################################

# App removal functions
. "$PSScriptRoot/Scripts/AppRemoval/ForceRemoveEdge.ps1"
. "$PSScriptRoot/Scripts/AppRemoval/RemoveApps.ps1"
. "$PSScriptRoot/Scripts/AppRemoval/GetInstalledAppsViaWinget.ps1"
. "$PSScriptRoot/Scripts/AppRemoval/Test-AppInWingetList.ps1"

# CLI functions
. "$PSScriptRoot/Scripts/CLI/AwaitKeyToExit.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLILastUsedSettings.ps1"  
. "$PSScriptRoot/Scripts/CLI/ShowCLIAppSelection.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLIDefaultModeAppRemovalOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLIDefaultModeOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLIAppRemoval.ps1"
. "$PSScriptRoot/Scripts/CLI/ShowCLIMenuOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/PrintPendingChanges.ps1"
. "$PSScriptRoot/Scripts/CLI/PrintHeader.ps1"

# Features functions
. "$PSScriptRoot/Scripts/Features/InvokeChanges.ps1"
. "$PSScriptRoot/Scripts/Features/StoreSearchSuggestions.ps1"
. "$PSScriptRoot/Scripts/Features/TelemetryScheduledTasks.ps1"
. "$PSScriptRoot/Scripts/Features/WindowsOptionalFeatures.ps1"
. "$PSScriptRoot/Scripts/Features/ImportRegistryFile.ps1"
. "$PSScriptRoot/Scripts/Features/ReplaceStartMenu.ps1"

# File I/O functions
. "$PSScriptRoot/Scripts/FileIO/LoadJsonFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/SaveToFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/SaveSettings.ps1"
. "$PSScriptRoot/Scripts/FileIO/LoadSettings.ps1"
. "$PSScriptRoot/Scripts/FileIO/ValidateAppslist.ps1"
. "$PSScriptRoot/Scripts/FileIO/LoadAppsFromFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/LoadAppsDetailsFromJson.ps1"
. "$PSScriptRoot/Scripts/FileIO/LoadAppPresetsFromJson.ps1"

# Helper functions
. "$PSScriptRoot/Scripts/Helpers/AddParameter.ps1"
. "$PSScriptRoot/Scripts/Helpers/DefaultUserHive.ps1"
. "$PSScriptRoot/Scripts/Helpers/CheckModernStandbySupport.ps1"
. "$PSScriptRoot/Scripts/Helpers/GenerateAppsList.ps1"
. "$PSScriptRoot/Scripts/Helpers/ImportConfigToParams.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-RegFileOperations.ps1"
. "$PSScriptRoot/Scripts/Helpers/GetUserDirectory.ps1"
. "$PSScriptRoot/Scripts/Helpers/GetUserName.ps1"
. "$PSScriptRoot/Scripts/Helpers/RegistryPathHelpers.ps1"
. "$PSScriptRoot/Scripts/Helpers/ApplyRegistryRegFile.ps1"

# Threading functions
. "$PSScriptRoot/Scripts/Threading/Invoke-NonBlocking.ps1"



##################################################################################################################
#                                                                                                                #
#                                                  SCRIPT START                                                  #
#                                                                                                                #
##################################################################################################################



# Get current Windows build version
$WinVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild

# Win11Debloat always targets the Default user profile hive, so that every user account
# created after this image is sysprep-generalized inherits the applied tweaks.
if ([int]$WinVersion -lt 22000) {
    Write-Error "Win11Debloat requires Windows 11 (build 22000 or later) because it always targets the Default user profile hive"
    AwaitKeyToExit
}

if (-not (Get-DefaultUserProfilePath)) {
    Write-Error "Unable to find the Default user profile directory (C:\Users\Default)"
    AwaitKeyToExit
}

# Check if the machine supports Modern Standby, this is used to determine if the DisableModernStandbyNetworking option can be used
$script:ModernStandbySupported = CheckModernStandbySupport

$script:Params = $PSBoundParameters
$script:UndoParams = @{}

# Add default Apps parameter when RemoveApps is requested and Apps was not explicitly provided
if ((-not $script:Params.ContainsKey("Apps")) -and $script:Params.ContainsKey("RemoveApps")) {
    $script:Params.Add('Apps', 'Default')
}

$controlParamsCount = 0

# Count how many control parameters are set, to determine if any changes were selected by the user during runtime
foreach ($Param in $script:ControlParams) {
    if ($script:Params.ContainsKey($Param)) {
        $controlParamsCount++
    }
}

# Hide progress bars for app removal, as they block Win11Debloat's output
if (-not ($script:Params.ContainsKey("Verbose"))) {
    $ProgressPreference = 'SilentlyContinue'
}
else {
    Write-Host "Verbose mode is enabled"
    Write-Output ""
    Write-Output "Press any key to continue..."
    $null = [System.Console]::ReadKey()

    $ProgressPreference = 'Continue'
}

# Remove LastUsedSettings.json file if it exists and is empty
if ((Test-Path $script:SavedSettingsFilePath) -and ([String]::IsNullOrWhiteSpace((Get-content $script:SavedSettingsFilePath)))) {
    Remove-Item -Path $script:SavedSettingsFilePath -recurse
}

# Change script execution based on provided parameters or user input
if ((-not $script:Params.Count) -or $RunDefaults -or $RunDefaultsLite -or $RunSavedSettings -or $Config -or ($controlParamsCount -eq $script:Params.Count)) {
    if ($RunDefaults -or $RunDefaultsLite) {
        ShowCLIDefaultModeOptions
    }
    elseif ($RunSavedSettings) {
        if (-not (Test-Path $script:SavedSettingsFilePath)) {
            PrintHeader 'Custom Mode'
            Write-Error "Unable to find LastUsedSettings.json file, no changes were made"
            AwaitKeyToExit
        }

        ShowCLILastUsedSettings
    }
    elseif ($Config) {
        try {
            ImportConfigToParams -ConfigPath $Config -CurrentBuild $WinVersion -ExpectedVersion '1.0'
        }
        catch {
            Write-Error "$_"
            AwaitKeyToExit
        }

        if (-not $Silent) {
            PrintHeader 'Custom Mode'
            PrintPendingChanges
            PrintHeader 'Custom Mode'
        }
    }
    else {
        $Mode = ShowCLIMenuOptions
    }

    # Add execution parameters based on the mode
    switch ($Mode) {
        # Default mode, loads defaults and app removal options
        '1' { 
            ShowCLIDefaultModeOptions
        }

        # App removal, remove apps based on user selection
        '2' {
            ShowCLIAppRemoval
        }

        # Load last used options from the "LastUsedSettings.json" file
        '3' {
            ShowCLILastUsedSettings
        }
    }
}
else {
    PrintHeader 'Configuration'
}

# If the number of keys in ControlParams equals the number of keys in Params then no modifications/changes were selected
#  or added by the user, and the script can exit without making any changes.
if (($controlParamsCount -eq $script:Params.Keys.Count) -or ($script:Params.Keys.Count -eq 1 -and $script:Params.Keys -contains 'Apps')) {
    Write-Output "The script completed without making any changes."
    AwaitKeyToExit
}

# Execute all selected/provided parameters using the consolidated function, with the
# Default user profile hive mounted for the duration so registry changes are baked into it
$mountedDefaultHive = $false
try {
    if (-not $script:Params.ContainsKey("WhatIf")) {
        Mount-DefaultUserHive
        $mountedDefaultHive = $true
    }
    Invoke-AllChanges
}
catch {
    Write-Error "$_"
    AwaitKeyToExit
}
finally {
    if ($mountedDefaultHive) {
        Dismount-DefaultUserHive
    }
}

Write-Output ""
Write-Output ""
Write-Output ""
Write-Output "Script completed! Please check above for any errors."

AwaitKeyToExit
