# Returns the path to the Default user profile directory (C:\Users\Default), or $null if not found
function Get-DefaultUserProfilePath {
    $rootPaths = @(
        (Join-Path $env:SystemDrive 'Users')
        (Split-Path -Path $env:USERPROFILE -Parent)
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

    foreach ($rootPath in $rootPaths) {
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
            continue
        }

        $defaultProfilePath = Join-Path $rootPath 'Default'
        if (Test-Path -LiteralPath $defaultProfilePath -PathType Container) {
            return $defaultProfilePath
        }
    }

    return $null
}

# Mounts the Default user's NTUSER.DAT hive at HKEY_USERS\Default, so registry
# changes can be baked into the hive template every new user profile is created from
function Mount-DefaultUserHive {
    $defaultProfilePath = Get-DefaultUserProfilePath
    if (-not $defaultProfilePath) {
        throw "Unable to find the Default user profile directory."
    }

    $hiveDatPath = Join-Path $defaultProfilePath 'NTUSER.DAT'
    if (-not (Test-Path -LiteralPath $hiveDatPath)) {
        throw "Unable to find the Default user hive at '$hiveDatPath'."
    }

    $global:LASTEXITCODE = 0
    reg load 'HKU\Default' "$hiveDatPath" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to load the Default user hive '$hiveDatPath' (exit code: $LASTEXITCODE)."
    }
}

function Dismount-DefaultUserHive {
    # Release any lingering .NET registry handles before unloading, otherwise
    # 'reg unload' can fail with "process is using the file"
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    $global:LASTEXITCODE = 0
    reg unload 'HKU\Default' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to unload the Default user hive (exit code: $LASTEXITCODE). It may remain mounted under HKEY_USERS\Default until the next reboot."
    }
}
