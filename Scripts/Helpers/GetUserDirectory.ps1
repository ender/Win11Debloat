# Returns the directory path inside the Default user profile, exits script if path can't be found
function GetUserDirectory {
    param (
        $fileName = "",
        $exitIfPathNotFound = $true
    )

    $defaultProfilePath = Get-DefaultUserProfilePath
    if ($defaultProfilePath) {
        $userPath = if ([string]::IsNullOrWhiteSpace($fileName)) {
            $defaultProfilePath
        }
        else {
            Join-Path $defaultProfilePath $fileName
        }

        if ((Test-Path -LiteralPath $userPath) -or ((Test-Path -LiteralPath $defaultProfilePath -PathType Container) -and (-not $exitIfPathNotFound))) {
            return $userPath
        }
    }

    Write-Error "Unable to find the Default user profile directory"
    AwaitKeyToExit
}
