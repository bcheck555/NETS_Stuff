param (
    [Parameter()][string]$hostName = $env:COMPUTERNAME,
    [Parameter()][string]$domainName = $env:USERDNSDOMAIN,
    [Parameter()][string]$bindDN,
    [Parameter()][string]$bindDNPass,
    [Parameter()][string]$certPass,
    [Parameter()][string]$installPath = "D:\Splunk",
    [Parameter()][string]$CaChain = "CAChain.pem",
    [Parameter()][string]$dbPath = "E:\Splunk\var\lib\splunk"
)
if ($bindDN -eq $null -or $bindDN -eq "") {
    $bindDN = Read-Host -Prompt "Enter distinguished name for LDAP account:"
}
if ($bindDNPass -eq $null -or $bindDNPass -eq "") {
    $bindDNPass = Read-Host -Prompt "Enter a password for LDAP account:"
}
if ($certPass -eq $null -or $certPass -eq "") {
    $certPass = Read-Host -Prompt "Enter a password for the private key:"
}
$tempPath = "C:\Temp"
$binPath = "$installPath\bin"
$etcPath = "$installPath\etc"
$certPath = "$etcPath\auth\mycerts"
$confPath = "$etcPath\system\local"

#Config
if (!(Test-Path -Path $certPath -PathType Container)) {
    New-Item -ItemType "directory" -Path $certPath
}

Copy-Item $tempPath\$caChain $certPath\$caChain

& $tempPath\CertTool.ps1 $hostName $domainName $binPath $certPass $certPath

#####BEGIN authentication.conf
#####Creates new file
$confFile = "authentication.conf"
$configData = "
[splunk_auth]
minPasswordLength = 15
minPasswordUppercase = 1
minPasswordLowercase = 1
minPasswordSpecial = 1
minPasswordDigit = 1

[authentication]
authSettings = NETS
authType = LDAP

[roleMap_NETS]
admin = Splunk Admins
can_delete = Splunk Admins
user = Splunk Users

[NETS]
SSLEnabled = 1
anonymous_referrals = 0
bindDN = $bindDN
bindDNpassword = $bindDNPass
charset = utf8
emailAttribute = mail
enableRangeRetrieval = 0
groupBaseDN = OU=Admin Groups,DC=IDC,DC=LOCAL
groupMappingAttribute = dn
groupMemberAttribute = member
groupNameAttribute = cn
host = DC01.IDC.LOCAL
nestedGroups = 0
network_timeout = 20
pagelimit = -1
port = 636
realNameAttribute = cn
sizelimit = 1000
timelimit = 15
userBaseDN = OU=Admins,DC=IDC,DC=LOCAL
###Password
#userNameAttribute = samaccountname
###Token
userNameAttribute = userprincipalname
"
Set-Content -Path $confPath\$confFile -Value $configData -Force
#####END authentication.conf

#####BEGIN indexes.conf
#####Creates new file
$confFile = "indexes.conf"
$configData = "
[default]

[linux]
homePath = `$SPLUNK_DB\`$_index_name\db
coldPath = `$SPLUNK_DB\`$_index_name\colddb
thawedPath = `$SPLUNK_DB\`$_index_name\thaweddb
frozenTimePeriodInSecs = 31536000
enableDataIntegrityControl = true
enableTsidxReduction = true

[wincerts]
homePath = `$SPLUNK_DB\`$_index_name\db
coldPath = `$SPLUNK_DB\`$_index_name\colddb
thawedPath = `$SPLUNK_DB\`$_index_name\thaweddb
frozenTimePeriodInSecs = 31536000
enableDataIntegrityControl = true
enableTsidxReduction = true

[windows]
homePath = `$SPLUNK_DB\`$_index_name\db
coldPath = `$SPLUNK_DB\`$_index_name\colddb
thawedPath = `$SPLUNK_DB\`$_index_name\thaweddb
frozenTimePeriodInSecs = 31536000
enableDataIntegrityControl = true
enableTsidxReduction = true

[wineventlog]
homePath = `$SPLUNK_DB\`$_index_name\db
coldPath = `$SPLUNK_DB\`$_index_name\colddb
thawedPath = `$SPLUNK_DB\`$_index_name\thaweddb
frozenTimePeriodInSecs = 31536000
enableDataIntegrityControl = true
enableTsidxReduction = true

#[winiislog]
#homePath = `$SPLUNK_DB\`$_index_name\db
#coldPath = `$SPLUNK_DB\`$_index_name\colddb
#thawedPath = `$SPLUNK_DB\`$_index_name\thaweddb
#frozenTimePeriodInSecs = 31536000
#enableDataIntegrityControl = true
#enableTsidxReduction = true

#[winsqllog]
#homePath = `$SPLUNK_DB\`$_index_name\db
#coldPath = `$SPLUNK_DB\`$_index_name\colddb
#thawedPath = `$SPLUNK_DB\`$_index_name\thaweddb
#frozenTimePeriodInSecs = 31536000
#enableDataIntegrityControl = true
#enableTsidxReduction = true
"
Set-Content -Path $confPath\$confFile -Value $configData -Force
#####END indexes.conf

#####BEGIN inputs.conf
#####Creates new file
$confFile = "inputs.conf"
$configData = "
[default]
host = $hostName

[splunktcp-ssl:9997]
disabled = 0

[SSL]
serverCert = $certPath\LOG01_Splunk2.pem
sslPassword = $certPass
requireClientCert = true

[script://`$SPLUNK_HOME\bin\scripts\splunk-wmi.path]
disabled = 0
"
Set-Content -Path $confPath\$confFile -Value $configData -Force
#####END inputs.conf

#####BEGIN server.conf
#####Creates new file
$confFile = "server.conf"
$configData = "
[general]
serverName = $hostName
trustedIP = 127.0.0.1

[sslConfig]
serverCert = $certPath\LOG01_Splunk2.pem
sslPassword = $certPass
sslRootCAPath = $certPath\CAChain.pem
sslVerifyServerCert = true

[lmpool:auto_generated_pool_download-trial]
description = auto_generated_pool_download-trial
peers = *
quota = MAX
stack_id = download-trial

[lmpool:auto_generated_pool_forwarder]
description = auto_generated_pool_forwarder
peers = *
quota = MAX
stack_id = forwarder

[lmpool:auto_generated_pool_free]
description = auto_generated_pool_free
peers = *
quota = MAX
stack_id = free
"
Set-Content -Path $confPath\$confFile -Value $configData -Force
#####END server.conf

#####BEGIN serverclass.conf
#####Creates new file
$confFile = "serverclass.conf"
$configData = "
[serverClass:Universal Forwarders - WIN]
blacklist.0 = log01
machineTypesFilter = windows-x64
restartSplunkd = true
whitelist.0 = *

[serverClass:Universal Forwarders - WIN:app:IndexerConfig]
restartSplunkd = true
stateOnClient = enabled

[serverClass:Universal Forwarders - WIN:app:Splunk_TA_Windows]
restartSplunkd = true
stateOnClient = enabled

[serverClass:Universal Forwarders - RHEL]
machineTypesFilter = linux-x86_64
whitelist.0 = *

[serverClass:Universal Forwarders - RHEL:app:IndexerConfig]

[serverClass:Universal Forwarders - RHEL:app:Splunk_TA_nix]
restartSplunkd = true

[serverClass:Universal Forwarders - WIN:app:IndexerConfig_win]
restartSplunkd = true

[serverClass:Universal Forwarders - RHEL:app:IndexerConfig_rhel]
restartSplunkd = true

[serverClass:Universal Forwarders - WIN:app:TA-windows-certificate-store]
restartSplunkd = true

[serverClass:Universal Forwarders - WIN:app:TA-windows-firewall-status-check]
restartSplunkd = true
"
Set-Content -Path $confPath\$confFile -Value $configData -Force
#####END serverclass.conf

#####BEGIN web.conf
#####Modifies existing file
#####Check to see if changes are already made, if so, skip.
$confFile = "web.conf"
$content = Get-Content $confPath\$confFile
$configData = ""
if (!( $content -like "*SCRIPT MODIFIED*" )) {
    $configData = "
[settings]
enableSplunkWebSSL = 1
serverCert = $certPath\$hostName`_Splunk.pem
privKeyPath = $certPath\$hostName`_Splunk.key
sslPassword = $certPass
###TOKEN
requireClientCert = true
sslRootCAPath = $certPath\$caChain
enableCertBasedUserAuth = true
SSOMode = permissive
trustedIP = 127.0.0.1
allowSsoWithoutChangingServerConf = 1
certBasedUserAuthMethod = PIV
###SCRIPT MODIFIED###
"
}
Add-Content -Path $confPath\$confFile -Value $configData
#####END web.conf

#####BEGIN splunk-launch.conf
$confFile = "splunk-launch.conf"
$configData = "
SPLUNK_HOME=$installPath
SPLUNK_SERVER_NAME=Splunkd
PYTHONHTTPSVERIFY=0
PYTHONUTF8=1
SPLUNK_DB=$dbPath
"
Set-Content -Path $etcPath\$confFile -Value $configData -Force
#####END splunk-launch.conf

Start-Sleep -Seconds 10
& $binPath\splunk.exe stop
Start-Sleep -Seconds 10
& $binPath\splunk.exe start