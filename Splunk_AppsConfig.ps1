param (
    [Parameter()][string]$userAdmin,
    [Parameter()][string]$passAdmin
)
if ($userAdmin -eq $null -or $userAdmin -eq "") {
    $userAdmin = Read-Host -Prompt "Enter admin account username:"
}
if ($passAdmin -eq $null -or $passAdmin -eq "") {
    $passAdmin = Read-Host -Prompt "Enter a password for admin account:"
}
$adminUser = "Admin"
$appPath = "C:\temp\SplunkApps"
$appList = Get-ChildItem -Path $appPath\*.tgz
$installPath = "D:\Splunk"
$binPath = "$installPath\bin"

###Install Apps
foreach($app in $appList) {
    & $binPath\splunk.exe install app $app -auth ${adminUser}:${passAdmin}
}
###Deployment Apps
Copy-Item -Path d:\Splunk\etc\apps\Splunk_TA_Windows -Destination d:\Splunk\etc\deployment-apps -Recurse
Copy-Item -Path d:\Splunk\etc\apps\Splunk_TA_nix -Destination d:\Splunk\etc\deployment-apps -Recurse
Copy-Item -Path d:\Splunk\etc\apps\TA-windows-certificate-store -Destination d:\Splunk\etc\deployment-apps -Recurse
Copy-Item -Path d:\Splunk\etc\apps\TA-microsoft-windefender -Destination d:\Splunk\etc\deployment-apps -Recurse
Copy-Item -Path d:\Splunk\etc\apps\TA-windows-firewall-status-check -Destination d:\Splunk\etc\deployment-apps -Recurse

Expand-Archive -Path C:\Temp\SplunkApps\Splunk_TA_Windows.zip -DestinationPath d:\Splunk\etc\apps -Force
Expand-Archive -Path C:\Temp\SplunkApps\TA-microsoft-windefender.zip -DestinationPath d:\Splunk\etc\apps -Force
Expand-Archive -Path C:\Temp\SplunkApps\TA-windows-firewall-status-check.zip -DestinationPath d:\Splunk\etc\apps -Force

Expand-Archive -Path C:\Temp\SplunkApps\Splunk_TA_Windows.zip -DestinationPath d:\Splunk\etc\deployment-apps -Force
Expand-Archive -Path C:\Temp\SplunkApps\Splunk_TA_nix.zip -DestinationPath d:\Splunk\etc\deployment-apps -Force
Expand-Archive -Path C:\Temp\SplunkApps\IndexerConfig_win.zip -DestinationPath d:\Splunk\etc\deployment-apps -Force
Expand-Archive -Path C:\Temp\SplunkApps\IndexerConfig_nix.zip -DestinationPath d:\Splunk\etc\deployment-apps -Force
Expand-Archive -Path C:\Temp\SplunkApps\TA-windows-certificate-store.zip -DestinationPath d:\Splunk\etc\deployment-apps -Force
Expand-Archive -Path C:\Temp\SplunkApps\TA-microsoft-windefender.zip -DestinationPath d:\Splunk\etc\deployment-apps -Force
Expand-Archive -Path C:\Temp\SplunkApps\TA-windows-firewall-status-check.zip -DestinationPath d:\Splunk\etc\deployment-apps -Force

###Disable Secure Gateway
& $binPath\splunk.exe disable app splunk_secure_gateway -auth ${adminUser}:${passAdmin}

Start-Sleep -Seconds 10
& $binPath\splunk.exe stop
Start-Sleep -Seconds 10
& $binPath\splunk.exe start