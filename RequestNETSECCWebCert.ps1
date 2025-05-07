param (
    [Parameter()][string]$hostName = $env:COMPUTERNAME,
    [Parameter()][string]$domainName = $env:USERDNSDOMAIN,
    [Parameter()][string]$binPath = "C:\Program Files\SplunkUniversalForwarder\bin",
    [Parameter()][string]$certPass,
    [Parameter()][string]$certPath
)
$hostName = $hostName.ToUpper()
if ($certPath -eq $null -or $certPath -eq "") {
    $certPath = (Get-Location).Path
}
if ($binPath -eq $null -or $binPath -eq "") {
    $binPath = Read-Host -Prompt "Enter path to bin folder:"
}
if ($certPass -eq $null -or $certPass -eq "") {
    $certPass = Read-Host -Prompt "Enter a password for the private key:"
}
$passSecure = ConvertTo-SecureString $certPass -AsPlainText -Force
#$binPsexec = "C:\SIATSS\Apps\SysInternals\psexec.exe"
$caServer = "dc01.idc.local\IDC-DC01-CA"
$certStore = "Cert:\LocalMachine\My"
$infFile = "RequestPolicy.inf"
$reqFile = "$hostName`_Splunk.req"
$crtFile = "$hostName`_Splunk.crt"
$pfxFile = "$hostName`_Splunk.pfx"
$keyFile = "$hostName`_Splunk.key"
$pemFile = "$hostName`_Splunk.pem"
$p_pFile = "$hostName`_Splunk2.pem"
$certTemplate = "NETSECCWeb"
#$certTemplate = "NETSRSAWeb"

if (!(Test-Path -Path $certPath -PathType Container)) {
    New-Item -ItemType "directory" -Path $certPath
}

Write-Output @"
[Version] 
Signature="$Windows NT$"
[NewRequest]
Subject = "CN=$hostName.$domainName"
Exportable = TRUE
KeySpec = 1

;UNCOMMENT for ECDH cert.
ProviderName="Microsoft Software Key Storage Provider"
KeyLength = 384
KeyAlgorithm = ECDH_P384

;UNCOMMENT for RSA cert.
;ProviderName="Microsoft RSA SChannel Cryptographic Provider"
;RequestType = PKCS10
;KeyLength = 2048
;KeyUsage = 0xA0
;MachineKeySet = TRUE

[Extensions]
; If your client operating system is Windows Server 2008, Windows Server 2008 R2, Windows Vista, or Windows 7
; SANs can be included in the Extensions section by using the following text format. Note 2.5.29.17 is the OID for a SAN extension.

2.5.29.17 = "{text}"
_continue_ = "dns=$hostName&"
_continue_ = "dns=$hostName.$domainName&"

[RequestAttributes]
;Because SSL/TLS does not require a Subject name when a SAN extension is included, the certificate Subject name can be empty.
;If you are using another protocol, verify the certificate requirements.
Subject = "CN=$hostName.$domainName"  ; Remove to use an empty Subject name.
CertificateTemplate = "$certTemplate"  ; Modify for your environment by using the LDAP common name of the template.
;Required only for enterprise CAs.
"@ > $certPath\$infFile

###Create req file
certreq -new $certPath\$infFile $certPath\$reqFile
###Submit req file
$request = certreq -submit -config $caServer $certPath\$reqFile $certPath\$crtFile
###Approve req
#certutil -config $caServer -resubmit $request.split("`n ")[1]
###Retrieve cert
do {
    Remove-Item $certPath\$hostName`_Splunk.rsp
    Write-Host "Pausing 60 seconds. Please issue certificate request:" $request.split("`n ")[1]
    Start-Sleep -Seconds 60
    certreq -config $caServer -retrieve $request.split("`n ")[1] $certPath\$crtFile
    }
    until (Test-Path -Path $certPath\$crtFile -PathType Leaf)
###Import cert to store
$import = Import-Certificate -FilePath "$certPath\$crtFile" -CertStoreLocation $certStore
###Export cert and key
Get-ChildItem -Path $certStore | Where-Object {$_.Thumbprint -eq $import.Thumbprint} | Export-PfxCertificate -FilePath "$certPath\$pfxFile" -Password $passSecure

###Convert for Splunk
& $binPath\openssl.exe pkcs12 -in "$certPath\$pfxFile" -passin pass:$certPass -passout pass:$certPass -clcerts -nokeys -out "$certPath\$pemFile"
& $binPath\openssl.exe pkcs12 -in "$certPath\$pfxFile" -passin pass:$certPass -passout pass:$certPass -nocerts -out "$certPath\$keyFile"

###Strip out the fucking attributes
foreach ($filePath in ("$certPath\$pemFile","$certPath\$keyFile")) {
    $fileContent = Get-Content $filePath
    $targetString = "-----BEGIN"
    $lineNumber = ($fileContent | Select-String $targetString).LineNumber
    if ($lineNumber) {
        $fileContent | Select-Object -Skip ($lineNumber - 1) | Set-Content -Path $filePath
    } else {
        Write-Host "Target string not found in file."
    }
}

Set-Content -Path $certPath\$p_pFile -Value (Get-Content -Path $certPath\$pemFile) -Force
Add-Content -Path $certPath\$p_pFile -Value (Get-Content -Path $certPath\$keyFile)
