<#
    .SYNOPSIS
    Removes one or more Windows app packages for all users on the system.

    .DESCRIPTION
    Iterates over the provided list of app identifiers and removes each one.
    The removal method (winget vs. Appx cmdlets) is determined per-app from
    Apps.json. Microsoft Edge is deferred to the end of the loop so that all
    winget attempts run before any force-remove prompt.
    After each winget removal, the system is checked to confirm whether the
    app is still installed before reporting an error.

    .PARAMETER appsList
    An array of app package identifiers to remove (e.g. 'Microsoft.BingNews').

    .EXAMPLE
    RemoveApps @('Microsoft.BingNews', 'Microsoft.BingWeather')

    .EXAMPLE
    RemoveApps -appsList (GenerateAppsList)
#>
function RemoveApps {
    param (
        $appslist
    )

    if ($script:Params.ContainsKey("WhatIf")) {
        foreach ($app in $appslist) {
            Write-Host "[WhatIf] Remove App Package: $app" -ForegroundColor Cyan
        }

        Write-Host ""
        return
    }

    $edgeIds = @('Microsoft.Edge', 'XPFFTQ037JWMHS')
    $edgeAppsInList = @()
    $wingetRemovedApps = @()

    Foreach ($app in $appsList) {
        # Microsoft Edge is handled after the loop to avoid duplicate removal attempts and allow fallback if winget fails
        if ($edgeIds -contains $app) {
            $edgeAppsInList += $app
            continue
        }

        Write-Host "Removing $app"

        if ((Get-AppRemovalMethod $app) -eq 'WinGet') {
            Remove-WinGetApp -app $app
            $wingetRemovedApps += $app
        }
        else {
            Remove-AppxApp -app $app
        }
    }

    # Remove Microsoft Edge
    if ($edgeAppsInList.Count -gt 0) {
        Remove-EdgeApp -edgeAppsInList $edgeAppsInList
    }

    # Check whether any winget-removed apps are still present, and report errors for each one.
    if ($wingetRemovedApps.Count -gt 0 -or $edgeAppsInList.Count -gt 0) {
        $postRemovalList = if ($script:WingetInstalled) { GetInstalledAppsViaWinget -TimeOut 10 -NonBlocking } else { $null }
        foreach ($app in $wingetRemovedApps) {
            if (Test-AppStillInstalled -appId $app -InstalledList $postRemovalList) {
                Write-Host "Unable to uninstall $app via WinGet" -ForegroundColor Red
            }
        }

        # Verify Edge separately (triggers its own force-remove path if still installed)
        $edgeStillInstalled = $false
        foreach ($edgeApp in $edgeAppsInList) {
            if (Test-AppStillInstalled -appId $edgeApp -InstalledList $postRemovalList) {
                $edgeStillInstalled = $true
                break
            }
        }
        if ($edgeStillInstalled) {
            Write-Host "Unable to uninstall Microsoft Edge via WinGet" -ForegroundColor Red
            Request-EdgeForceRemove
        }
    }

    Write-Host ""
}

<#
    .SYNOPSIS
    Uninstalls a non-Edge app via WinGet.

    .DESCRIPTION
    Runs winget uninstall for a single app. After uninstall, the system is
    checked to confirm whether the app is still present — winget output is
    not trusted on its own, as it sometimes reports failure after a
    successful removal. Edge apps are handled separately after the main loop.

    .PARAMETER app
    The WinGet package ID to uninstall (e.g. 'Microsoft.BingNews').
#>
function Remove-WinGetApp {
    param([string]$app)

    if (-not $script:WingetInstalled) {
        Write-Host "ERROR: WinGet is either not installed or is outdated, $app could not be removed" -ForegroundColor Red
        return
    }

    Invoke-NonBlocking -ScriptBlock {
        param($appId)
        winget uninstall --accept-source-agreements --disable-interactivity --id $appId
    } -ArgumentList $app
}

<#
    .SYNOPSIS
    Removes Microsoft Edge via WinGet (both AppIds), with fallback to force-remove.

    .DESCRIPTION
    Edge has multiple package IDs. Runs winget uninstall for each one.
    After all attempts, the system is checked to confirm whether Edge is
    still present. The force-remove prompt only appears if Edge remains
    installed — winget false positives are ignored.

    .PARAMETER edgeAppsInList
    The Edge AppIds that appear in the removal list (one or both).
#>
function Remove-EdgeApp {
    param([string[]]$edgeAppsInList)

    if (-not $script:WingetInstalled) {
        Write-Host "ERROR: WinGet is either not installed or is outdated, Microsoft Edge could not be removed" -ForegroundColor Red
        return
    }

    foreach ($edgeApp in $edgeAppsInList) {
        Write-Host "Removing $edgeApp"
        Invoke-NonBlocking -ScriptBlock {
            param($appId)
            winget uninstall --accept-source-agreements --disable-interactivity --id $appId
        } -ArgumentList $edgeApp
    }
}

<#
    .SYNOPSIS
    Removes an app for all users via Remove-AppxPackage / Remove-ProvisionedAppxPackage.

    .PARAMETER app
    The package identifier to remove (e.g. 'Clipchamp.Clipchamp').
#>
function Remove-AppxApp {
    param([string]$app)

    $appPattern = '*' + $app + '*'

    try {
        Invoke-NonBlocking -ScriptBlock {
            param($pattern)
            Get-AppxPackage -Name $pattern -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Continue
            Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $pattern } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
        } -ArgumentList $appPattern
    }
    catch {
        Write-Verbose "Something went wrong while trying to remove $($app): $_"
    }
}

<#
    .SYNOPSIS
    Checks whether an app package is still installed after a removal attempt.

    .DESCRIPTION
    Checks Get-AppxPackage across all users first (fast, no process launch),
    then falls back to a pre-fetched or live winget list for non-Appx packages.
    Uses Test-AppInWingetList which provides exact-match-first with substring
    fallback against the parsed winget objects.
    Returns $true if the app is still present, $false otherwise.

    .PARAMETER appId
    The package identifier to check (e.g. 'Microsoft.BingNews').

    .PARAMETER InstalledList
    Optional pre-fetched array of winget objects from GetInstalledAppsViaWinget.
    When provided, used directly; otherwise a live winget call is made.
#>
function Test-AppStillInstalled {
    param(
        [string]$appId,
        [object[]]$InstalledList
    )

    # Check Get-AppxPackage for all users first (fast, covers all Store apps).
    if (Get-AppxPackage -Name "$appId" -AllUsers -ErrorAction SilentlyContinue) {
        return $true
    }

    # Use the pre-fetched list if provided; otherwise fall back to a live winget call.
    if ($InstalledList) {
        return (Test-AppInWingetList -appId $appId -InstalledList $InstalledList)
    }

    if ($script:WingetInstalled) {
        $liveList = GetInstalledAppsViaWinget -TimeOut 10 -NonBlocking
        if (Test-AppInWingetList -appId $appId -InstalledList $liveList) {
            return $true
        }
    }
    else {
        Write-Warning "Unable to verify whether '$appId' is still installed (WinGet is unavailable)"
    }

    return $false
}

<#
    .SYNOPSIS
    Returns the removal method for an app identifier.

    .DESCRIPTION
    Parses Apps.json once (cached in script scope) to build a lookup of
    AppId -> RemovalMethod. Returns 'WinGet' if the app should be removed
    via winget, or 'Appx' if via Remove-AppxPackage. Defaults to 'Appx'
    for unknown IDs.

    .PARAMETER appId
    The package identifier (e.g. 'Clipchamp.Clipchamp').
#>
function Get-AppRemovalMethod {
    param([string]$appId)

    if (-not $script:AppRemovalMethodCache) {
        $script:AppRemovalMethodCache = @{}
        try {
            if (Test-Path $script:AppsListFilePath) {
                $appsJson = Get-Content -Path $script:AppsListFilePath -Raw | ConvertFrom-Json
                foreach ($appData in $appsJson.Apps) {
                    $rawMethod = $appData.RemovalMethod
                    $method = if ($rawMethod -and $rawMethod -eq 'WinGet') { 'WinGet' } else { 'Appx' }
                    if ($appData.AppId -is [array]) {
                        foreach ($id in $appData.AppId) { $script:AppRemovalMethodCache[$id.Trim()] = $method }
                    }
                    else {
                        $script:AppRemovalMethodCache[$appData.AppId.Trim()] = $method
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to load app removal methods from '$script:AppsListFilePath'. Defaulting unknown apps to Appx. Error: $_"
        }
    }

    if ($script:AppRemovalMethodCache.ContainsKey($appId)) {
        return $script:AppRemovalMethodCache[$appId]
    }
    return 'Appx'
}

<#
    .SYNOPSIS
    Prompts the user to forcefully remove Microsoft Edge when winget cannot uninstall it.

    .DESCRIPTION
    Only invoked after it has been confirmed that Edge is still present
    following all winget uninstall attempts. Prompts via Read-Host, and on
    confirmation, performs a force-remove of the Edge package.
#>
function Request-EdgeForceRemove {
    if ($(Read-Host -Prompt "Would you like to forcefully uninstall Microsoft Edge? NOT RECOMMENDED! (y/n)") -eq 'y') {
        Write-Host ""
        ForceRemoveEdge
    }
}
