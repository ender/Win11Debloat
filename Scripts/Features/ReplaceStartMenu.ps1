<#
    .SYNOPSIS
    Replaces the start menu layout for a single user.

    .DESCRIPTION
    Backs up the current start2.bin file (if it exists), then copies
    the specified template over it. When using the default template this clears
    all pinned apps from the start menu. Validates that the template file
    exists and has a .bin extension before proceeding.

    Credit: https://lazyadmin.nl/win-11/customize-windows-11-start-menu-layout/

    .PARAMETER startMenuBinFile
    The full path to the user's start2.bin file to replace.

    .PARAMETER startMenuTemplate
    Path to the .bin template file to apply. Defaults to the blank template
    bundled with the script (Assets/Start/start2.bin).

    .EXAMPLE
    ReplaceStartMenu -startMenuBinFile "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin"

    .EXAMPLE
    ReplaceStartMenu -startMenuBinFile "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin" -startMenuTemplate "C:\CustomLayout.bin"
#>
function ReplaceStartMenu {
    param (
        [Parameter(Mandatory)]
        [string]$startMenuBinFile,
        [string]$startMenuTemplate = "$script:AssetsPath\Start\start2.bin"
    )

    # Check if template bin file exists
    if (-not (Test-Path $startMenuTemplate)) {
        Write-Host "Error: Unable to replace start menu, template file not found" -ForegroundColor Red
        return
    }

    if ([IO.Path]::GetExtension($startMenuTemplate) -ne ".bin") {
        Write-Host "Error: Unable to replace start menu, template file is not a valid .bin file" -ForegroundColor Red
        return
    }

    $userName = GetStartMenuUserNameFromPath -StartMenuBinFile $startMenuBinFile

    if ($script:Params.ContainsKey("WhatIf")) {
        Write-Host "[WhatIf] Replace Start Menu for user $userName with template $startMenuTemplate" -ForegroundColor Cyan
        return
    }

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupFileName = "Win11Debloat-StartBackup-$timestamp.bak"
    $startMenuDir = Split-Path $startMenuBinFile -Parent
    $backupBinFile = Join-Path $startMenuDir $backupFileName

    if (Test-Path $startMenuBinFile) {
        # Backup current start menu file
        Copy-Item -Path $startMenuBinFile -Destination $backupBinFile -Force
        Write-Verbose "Start menu backup for user $userName saved to $backupFileName"
    }
    else {
        Write-Host "Unable to find original start2.bin file for user $userName, no backup was created for this user" -ForegroundColor Yellow
        New-Item -ItemType File -Path $startMenuBinFile -Force
    }

    # Copy template file
    Copy-Item -Path $startMenuTemplate -Destination $startMenuBinFile -Force

    Write-Host "Replaced start menu for user $userName"
}

<#
    .SYNOPSIS
    Returns the full path to the start menu bin file for the Default user profile.

    .DESCRIPTION
    Resolves the path to the start2.bin file inside the Default user profile,
    so changes are inherited by every user account created after this image
    is sysprep-generalized.

    .EXAMPLE
    GetStartMenuBinPathForUser
#>
function GetStartMenuBinPathForUser {
    return (GetUserDirectory -fileName "AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin" -exitIfPathNotFound $false)
}

<#
    .SYNOPSIS
    Extracts the username from a start2.bin file path.

    .DESCRIPTION
    Parses a typical C:\Users\<UserName>\AppData\... path and returns the
    username portion. Returns 'unknown' if the path does not match the
    expected pattern.

    .PARAMETER StartMenuBinFile
    The full path to a start2.bin file.

    .EXAMPLE
    GetStartMenuUserNameFromPath -StartMenuBinFile "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin"
#>
function GetStartMenuUserNameFromPath {
    param(
        [string]$StartMenuBinFile
    )

    $resolvedUserName = [regex]::Match($StartMenuBinFile, '(?:Users\\)([^\\]+)(?:\\AppData)').Groups[1].Value
    if ([string]::IsNullOrWhiteSpace($resolvedUserName)) {
        return 'unknown'
    }

    return $resolvedUserName
}
