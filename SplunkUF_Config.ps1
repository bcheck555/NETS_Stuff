param (
    [Parameter()][string]$hostName = $env:COMPUTERNAME,
    [Parameter()][string]$domainName = $env:USERDNSDOMAIN,
    [Parameter()][string]$indexer = "log01.idc.local",
    [Parameter()][string]$certPass,
    [Parameter()][string]$installPath = "C:\Program Files\SplunkUniversalForwarder",
    [Parameter()][string]$CaChain = "CAChain.pem"
)
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

& $tempPath\CertTool.ps1 $hostName $domainName $binPath $certPass $certPath
Copy-Item $tempPath\CertTool.ps1 $certPath
Copy-Item $tempPath\$caChain $certPath\$caChain

#####BEGIN deploymentclient.conf
#####Creates new file
$confFile = "deploymentclient.conf"
$configData = "
[target-broker:deploymentServer]
targetUri = $indexer`:8089
"
Set-Content -Path $confPath\$confFile -Value $configData -Force
#####END deploymentclient.conf

#####BEGIN server.conf
#####Creates new file
$confFile = "server.conf"
$configData = "
[general]
serverName = $hostName

[sslConfig]
serverCert = $certPath\$hostname`_Splunk2.pem
sslPassword = $certPass
sslRootCAPath = $certPath\$caChain
useClientSSLCompression = true
sslVerifyServerCert = true

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

& sc.exe failure SplunkForwarder reset=86400 actions=restart/110000/restart/220000/restart/300000