function CheckIfInstalled {
    param (
        [string]$Name
    )
    # Check registry paths for installed programs (HKLM for system-wide installs)
    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    # Use -ErrorAction to silently continue if paths don't exist
    $app = $paths | ForEach-Object {
        Get-ItemProperty $_ -ErrorAction SilentlyContinue
    } | Where-Object { $_.DisplayName -like "*$Name*" } | Select-Object -First 1

    if ($app) {
        Write-Host "$($app.DisplayName) is installed."
        exit 0
    }
    else {
        Write-Host "$Name is NOT installed."
        exit 1
    }
}

CheckIfInstalled -Name "AppName"
