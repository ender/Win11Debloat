# Prints the header for the script
function PrintHeader {
    param (
        $title
    )

    $fullTitle = " Win11Debloat Script - $title (User: $(GetUserName))"

    Clear-Host
    Write-Host "-------------------------------------------------------------------------------------------"
    Write-Host $fullTitle
    Write-Host "-------------------------------------------------------------------------------------------"
}