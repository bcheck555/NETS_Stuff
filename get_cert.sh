#!/bin/bash
read -p "Enter password for private key: " certPass
#ssh log01.idc.local 'del c:\temp\cert\*.*; c:\NETS\SysInternals\psexec -s -nobanner powershell c:\temp\CertTool.ps1 rh02 idc.local d:\splunk\bin' $certPass 'c:\temp\cert'
ssh -K log01.idc.local 'del c:\temp\cert\*.*; powershell c:\temp\CertTool.ps1 rh02 idc.local d:\splunk\bin' $certPass 'c:\temp\cert'
scp log01.idc.local:c:/temp/cert/*.pfx .
ls *.pfx
