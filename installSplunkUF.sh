#!/bin/bash
read -p "Enter password for private key: " certPass
sshHost="log01"
hostName=`hostname`
#hostName=${hostName^^}
domain="idc.local"
certPath="/opt/splunkforwarder/etc/auth/mycerts"
confPath="/opt/splunkforwarder/etc/system/local"
sudo tar xvzf splunkforwarder-9.4.1-e3bdab203ac8-linux-amd64.tgz -C /opt
sudo mkdir /opt/splunkforwarder/etc/auth/mycerts
ssh -K checkb@"$sshHost.$domain" 'del c:\temp\cert\*.*; powershell c:\temp\CertTool.ps1 ' $hostName $domain ' d:\splunk\bin ' $certPass ' c:\temp\cert '
scp checkb@"$sshHost.$domain:c:/temp/cert/*Splunk2.pem" .
scp checkb@"$sshHost.$domain:c:/temp/CAChain.pem" .

sudo echo "
[target-broker:deploymentServer]
targetUri = log01.idc.local:8089 
" > ./deploymentclient.conf

sudo echo "
[general]
serverName = $hostName

[sslConfig]
serverCert = "$certPath/${hostName^^}\_Splunk2.pem"
sslPassword = $certPass
sslRootCAPath = "$certPath/CAChain.pem"
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
" > ./server.conf

sudo cp ./*.pem $certPath
sudo cp ./*.conf $confPath

sudo chown -R splunkfwd:splunkfwd /opt/splunkforwarder
sudo firewall-cmd --policy="RH02-out" --permanent --add-rich-rule 'rule priority="-21798" family="ipv4" destination address="10.18.87.253/32" port port="8089" protocol="tcp" accept'
sudo firewall-cmd --policy="RH02-out" --permanent --add-rich-rule 'rule priority="-21798" family="ipv4" destination address="10.18.87.253/32" port port="9997" protocol="tcp" accept'
sudo /opt/splunkforwarder/bin/splunk start
