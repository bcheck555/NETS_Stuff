#Unblock-File c:\temp\*.ps1
#https://docs.splunk.com/Documentation/Forwarder/9.4.1/Forwarder/InstallaWindowsuniversalforwarderfromaninstaller

$hostName = ($env:COMPUTERNAME).ToUpper()
$domainName = ($env:USERDNSDOMAIN).ToUpper()
$certPass = Read-Host -Prompt "Enter a password for the private key:"
#$url = "https://download.splunk.com/products/universalforwarder/releases/9.4.1/windows"
$file = "splunkforwarder-9.4.1-e3bdab203ac8-windows-x64.msi"
$tempPath = "C:\Temp"
$installPath = "C:\Program Files\SplunkUniversalForwarder"
$indexer = "log01.idc.local"
$arguments = "/i `"$tempPath\$file`" " +
  "AGREETOLICENSE=Yes " +
  "INSTALLDIR=`"$installPath`" " +
  "LOGON_USERNAME=`"`" " +
  "LOGON_PASSWORD=`"`" " +
  "RECEIVING_INDEXER=`"`" " +
  "DEPLOYMENT_SERVER=`"`" " +
  "LAUNCHSPLUNK=0 " +
  "SERVICESTARTTYPE=auto " +
  "MONITOR_PATH=`"`" " +
  "WINEVENTLOG_APP_ENABLE=0 " +
  "WINEVENTLOG_SEC_ENABLE=0 " +
  "WINEVENTLOG_SYS_ENABLE=0 " +
  "WINEVENTLOG_FWD_ENABLE=0 " +
  "WINEVENTLOG_SET_ENABLE=0 " +
  "CERTFILE=`"`" " +
  "ROOTCACERTFILE=`"`" " +
  "CERTPASSWORD= " +
  "CLONEPREP=0 " +
  "SET_ADMIN_USER=0 " +
  "SPLUNKUSERNAME= " +
  "SPLUNKPASSWORD= " +
  "MINPASSWORDLEN=15 " +
  "MINPASSWORDDIGITLEN=1 " +
  "MINPASSWORDLOWERCASELEN=1 " +
  "MINPASSWORDUPPERCASELEN=1 " +
  "MINPASSWORDSPECIALCHARLEN=1 " +
  "GENRANDOMPASSWORD=1 " +
  "USE_LOCAL_SYSTEM=1 " +
  "PRIVILEGEBACKUP=0 " +
  "PRIVILEGESECURITY=1 " +
  "PRIVILEGEIMPERSONATE=0 " +
  "GROUPPERFORMANCEMONITORUSERS=0 " +
  "/passive"
$ProgressPreference = 'SilentlyContinue'   #Speeds up IWR ¯\_(ツ)_/¯

#Install
if (!(Test-Path -Path $tempPath -PathType Container)) {
    New-Item -ItemType "directory" -Path $tempPath
}
#Invoke-WebRequest -Uri $url\$file -OutFile $tempPath\$file
Start-Process msiexec.exe -ArgumentList $arguments -Wait

#Config
& $tempPath\SplunkUF_Config.ps1 $hostName $domainName $indexer $certPass $installPath

net stop SplunkForwarder
Start-Sleep -Seconds 10
net start SplunkForwarder