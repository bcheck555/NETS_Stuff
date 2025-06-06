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
###Splunk Checklist V-221632
minPasswordLength = 15
###
###Splunk Checklist V-221629
minPasswordUppercase = 1
###
###Splunk Checklist V-221630
minPasswordLowercase = 1
###
###Splunk Checklist V-221633
minPasswordSpecial = 1
###
###Splunk Checklist V-221631
minPasswordDigit = 1
###
constantLoginTime = 0.000
enablePasswordHistory = 0
expireAlertDays = 15
###Splunk Checklist V-221634
expirePasswordDays = 60
###
expireUserAccounts = 0
forceWeakPasswordChange = 0
###Splunk Checklist V-221941
lockoutAttempts = 3
lockoutThresholdMins = 15
###
lockoutMins = 30
lockoutUsers = 1
###Splunk Checklist V-221635
passwordHistoryCount = 24
###
verboseLoginFailMsg = 1

[authentication]
authSettings = NETS
authType = LDAP

[roleMap_NETS]
admin = Splunk Admins
can_delete = Splunk Admins
user = Splunk Users

[NETS]
###Splunk Checklist V-221609
SSLEnabled = 1
port = 636
###
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

#####BEGIN health.conf
#####Creates new file
$confFile = "health.conf"
$configData = "
[alert_action:email]
###Splunk Checklist V-221625
disabled = 0
action.to = siatsstechnicalsupportteam@stfltd.com
action.cc = siatsstechnicalsupportteam@stfltd.com
###
"
Set-Content -Path $confPath\$confFile -Value $configData -Force
#####END health.conf

#####BEGIN indexes.conf
#####Creates new file
$confFile = "indexes.conf"
$configData = "
[default]
###Splunk Checklist V-246917
frozenTimePeriodInSecs = 31536000
###
###Splunk Checklist V-221613
enableDataIntegrityControl = true
###
###Reduce indexes after 30 days
enableTsidxReduction = true
timePeriodInSecBeforeTsidxReduction = 2592000

[linux]
homePath = `$SPLUNK_DB\`$_index_name\db
coldPath = `$SPLUNK_DB\`$_index_name\colddb
thawedPath = `$SPLUNK_DB\`$_index_name\thaweddb

[wineventlog]
homePath = `$SPLUNK_DB\`$_index_name\db
coldPath = `$SPLUNK_DB\`$_index_name\colddb
thawedPath = `$SPLUNK_DB\`$_index_name\thaweddb
"
Set-Content -Path $confPath\$confFile -Value $configData -Force
#####END indexes.conf

#####BEGIN inputs.conf
#####Creates new file
$confFile = "inputs.conf"
$configData = "
[default]
host = $hostName

###Splunk Checklist V-221608
[splunktcp-ssl:9997]
disabled = 0
###

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
###Splunk Checklist V-221938
sessionTimeout = 15m
###

[kvstore]
sslKeysPath = C:\Temp\cert\LOG01_Splunk2.pem
sslKeysPassword = $certPass
caCertFile = $certPath\CAChain.pem

[sslConfig]
serverCert = $certPath\LOG01_Splunk2.pem
sslPassword = $certPass
sslRootCAPath = $certPath\CAChain.pem
sslVerifyServerCert = true

[diskUsage]
###Splunk Checklist V-221625 (25% of drive)
minFreeSpace =  30000
###

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

[serverClass:Universal Forwarders - WIN:app:Splunk_TA_Windows]
restartSplunkd = true

[serverClass:Universal Forwarders - WIN:app:IndexerConfig_win]
restartSplunkd = true

[serverClass:Universal Forwarders - NIX]
machineTypesFilter = linux-x86_64
restartSplunkd = true
whitelist.0 = *

[serverClass:Universal Forwarders - NIX:app:IndexerConfig_rhel]
restartSplunkd = true

[serverClass:Universal Forwarders - NIX:app:Splunk_TA_nix]
restartSplunkd = true

[serverClass:Universal Forwarders - NIX:app:IndexerConfig_nix]
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
###Splunk Checklist V-221607
enableSplunkWebSSL = 1
###
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
###Splunk Checklist V-221931
login_content = <script>function DoDBanner() {alert(`"You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.\nBy using this IS (which includes any device attached to this IS), you consent to the following conditions:\n-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.\n-At any time, the USG may inspect and seize data stored on this IS.\n-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.\n-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.\n-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.`");}DoDBanner();</script>
###
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
###Splunk Checklist V-221600
SPLUNK_FIPS=1
###
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