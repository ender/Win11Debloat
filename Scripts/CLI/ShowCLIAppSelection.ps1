<#
    .SYNOPSIS
    Prompts the user to manually pick apps to remove from a numbered CLI list.

    .DESCRIPTION
    Prints every app defined in Apps.json with an index number and a marker
    for apps selected by default, then asks the user to enter a comma
    separated list of numbers to remove. Returns the flattened list of
    AppId strings for the chosen apps, or $null if the user cancels.

    .EXAMPLE
    $selectedApps = ShowCLIAppSelection
#>
function ShowCLIAppSelection {
    $apps = @(LoadAppsDetailsFromJson -InitialCheckedFromJson)

    if ($apps.Count -eq 0) {
        Write-Host "No apps are available to select from Apps.json" -ForegroundColor Red
        return $null
    }

    Write-Host ""
    Write-Host "Available apps (* = removed by default):" -ForegroundColor Yellow
    for ($i = 0; $i -lt $apps.Count; $i++) {
        $marker = if ($apps[$i].IsChecked) { '*' } else { ' ' }
        Write-Host (" {0,3}) {1} {2}" -f ($i + 1), $marker, $apps[$i].DisplayName)
    }

    Write-Host ""
    $selection = Read-Host "Enter the numbers of the apps you want to remove, separated by commas (e.g. 1,3,5), or leave blank to cancel"

    if ([string]::IsNullOrWhiteSpace($selection)) {
        return $null
    }

    $selectedAppIds = @()
    foreach ($entry in ($selection -split ',')) {
        $entry = $entry.Trim()
        if ($entry.Length -eq 0) { continue }

        $index = 0
        if (-not [int]::TryParse($entry, [ref]$index) -or $index -lt 1 -or $index -gt $apps.Count) {
            Write-Host "Ignoring invalid entry '$entry'" -ForegroundColor Yellow
            continue
        }

        $selectedAppIds += $apps[$index - 1].AppId
    }

    $selectedAppIds = @($selectedAppIds | Select-Object -Unique)

    if ($selectedAppIds.Count -eq 0) {
        Write-Host "No valid apps were selected" -ForegroundColor Red
        return $null
    }

    return $selectedAppIds
}
