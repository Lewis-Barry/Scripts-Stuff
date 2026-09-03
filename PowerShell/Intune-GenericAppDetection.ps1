$n="APPNAME"
$p="*$n*"
$k='\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$s=$k|%{gp "HKLM:$_" -EA 0}|?{$_.DisplayName -like $p}|select -f 1
$u=$k|%{gp "HKCU:$_" -EA 0}|?{$_.DisplayName -like $p}|select -f 1
$l=$env:LOCALAPPDATA
$d="$l\Programs\*","$l\*","$env:APPDATA\*"|%{gi $_ -EA 0}|?{$_.Name -like $p}|select -f 1
if($s){Write-Host "$($s.DisplayName) is installed (system-wide).";exit 0}
elseif($u){Write-Host "$($u.DisplayName) is installed (per-user).";exit 2}
elseif($d){Write-Host "$($d.Name) found in $($d.FullName) (per-user).";exit 2}
else{Write-Host "$n is NOT installed.";exit 1}
