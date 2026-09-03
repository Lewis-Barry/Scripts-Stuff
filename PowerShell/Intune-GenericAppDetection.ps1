$n="AppName"
$s='HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'|%{Get-ItemProperty $_ -EA 0}|?{$_.DisplayName -like "*$n*"}|select -f 1
$u='HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'|%{Get-ItemProperty $_ -EA 0}|?{$_.DisplayName -like "*$n*"}|select -f 1
$d="$env:LOCALAPPDATA\Programs\*","$env:LOCALAPPDATA\*","$env:APPDATA\*"|%{Get-Item $_ -EA 0}|?{$_.Name -like "*$n*"}|select -f 1
if($s){Write-Host "$($s.DisplayName) is installed (system-wide).";exit 0}
elseif($u){Write-Host "$($u.DisplayName) is installed (per-user).";exit 2}
elseif($d){Write-Host "$($d.Name) found in $($d.FullName) (per-user).";exit 2}
else{Write-Host "$n is NOT installed.";exit 1}
