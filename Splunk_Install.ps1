#Unblock-File c:\temp\*.ps1
#https://docs.splunk.com/Documentation/Splunk/9.4.1/Installation/InstallonWindowsviathecommandline

$hostName = ($env:COMPUTERNAME).ToUpper()
$domainName = ($env:USERDNSDOMAIN).ToUpper()
$adminUser = "admin"
$adminPass = Read-Host -Prompt "Enter a password for splunk admin:"
$bindDN = "CN=Splunk LDAP,OU=Service Accounts,DC=IDC,DC=LOCAL"
$bindDNPass = Read-Host -Prompt "Enter a password for LDAP account:"
$certPass = Read-Host -Prompt "Enter a password for the private key:"
#$url = "https://download.splunk.com/products/splunk/releases/9.4.1/windows"
$file = "splunk-9.4.1-e3bdab203ac8-windows-x64.msi"
$tempPath = "C:\Temp"
$installPath = "D:\Splunk"
#$binPath = "$installPath\bin"
#$confPath = "$installPath\etc\system\local"
#$certPath = "$installPath\etc\auth\mycerts"
$caChain = "CAChain.pem"
$arguments = "/i `"$tempPath\$file`" " +
  "AGREETOLICENSE=Yes " +
  "INSTALLDIR=`"$installPath`" " +
  "SPLUNKD_PORT=8089 " +
  "WEB_PORT=8000 " +
  "WINEVENTLOG_APP_ENABLE=0 " +
  "WINEVENTLOG_SEC_ENABLE=0 " +
  "WINEVENTLOG_SYS_ENABLE=0 " +
  "WINEVENTLOG_FWD_ENABLE=0 " +
  "WINEVENTLOG_SET_ENABLE=0 " +
  "REGISTRYCHECK_U=0 " +
  "REGISTRYCHECK_BASELINE_U=0 " +
  "REGISTRYCHECK_LM=0 " +
  "REGISTRYCHECK_BASELINE_LM=0 " +
  "WMICHECK_CPUTIME=0 " +
  "WMICHECK_LOCALDISK=0 " +
  "WMICHECK_FREEDISK=0 " +
  "WMICHECK_MEMORY=0 " +
  "LOGON_USERNAME=`"`" " +
  "LOGON_PASSWORD=`"`" " +
  "SPLUNK_APP=`"`" " +
  "FORWARD_SERVER=`"`" " +
  "DEPLOYMENT_SERVER=`"`" " +
  "LAUNCHSPLUNK=0 " +
  "INSTALL_SHORTCUT=1 " +
  "SPLUNKUSERNAME=$adminUser " +
  "SPLUNKPASSWORD=$adminPass " +
  "MINPASSWORDLEN=15 " +
  "MINPASSWORDDIGITLEN=1 " +
  "MINPASSWORDLOWERCASELEN=1 " +
  "MINPASSWORDUPPERCASELEN=1 " +
  "MINPASSWORDSPECIALCHARLEN=1 " +
  "GENRANDOMPASSWORD=0 " +
  "/passive"
$ProgressPreference = 'SilentlyContinue'   #Speeds up IWR ¯\_(ツ)_/¯

#Install
if (!(Test-Path -Path $tempPath -PathType Container)) {
    New-Item -ItemType "directory" -Path $tempPath
}
#Invoke-WebRequest -Uri $url\$file -OutFile $tempPath\$file
Start-Process msiexec.exe -ArgumentList $arguments -Wait

& $tempPath\Splunk_Config.ps1 $hostName $domainName $bindDN $bindDNPass $certPass $installPath $caChain

& $tempPath\Splunk_AppsConfig.ps1 $adminUser $adminPass

Add-MpPreference -ExclusionPath $installPath