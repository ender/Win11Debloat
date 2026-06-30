# Shows the CLI app removal menu and prompts the user to select which apps to remove.
function ShowCLIAppRemoval {
    PrintHeader "App Removal"

    $selectedApps = ShowCLIAppSelection

    if ($selectedApps) {
        Write-Output "You have selected $($selectedApps.Count) apps for removal"
        AddParameter 'RemoveApps'
        AddParameter 'Apps' ($selectedApps -join ',')

        SaveSettings

        # Suppress prompt if Silent parameter was passed
        if (-not $Silent) {
            Write-Output ""
            Write-Output ""
            Write-Output "Press enter to remove the selected apps or press CTRL+C to quit..."
            Read-Host | Out-Null
            PrintHeader "App Removal"
        }
    }
    else {
        Write-Host "Selection was cancelled, no apps have been removed" -ForegroundColor Red
        Write-Output ""
    }
}