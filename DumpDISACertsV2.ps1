#https://learn.microsoft.com/en-us/archive/msdn-technet-forums/b4e479fd-48b7-4659-ac02-6e7eadd1bdda
$url = "http://dl.cyber.mil/pki-pke/zip"
$file = "unclass-certificates_pkcs7_DoD.zip"
$certFile = "Certificates_PKCS7_v5_14_DoD.pem.p7b"
$certDir = "Certificates_PKCS7_v5_14_DoD"
$basePath = "c:\temp"
$dodChain = "DoD_Chain.pem"
$ProgressPreference = 'SilentlyContinue'   #Speeds up IWR ¯\_(ツ)_/¯
$openSSL = "d:\splunk\bin\openssl.exe"

if (!(Test-Path -Path $basePath -PathType Container)) {
    New-Item -ItemType "directory" -Path $basePath
}

#IWR not working currently, corrupt file...¯\_(ツ)_/¯
#Invoke-WebRequest -Uri $url/$file -OutFile $basePath\$file

Expand-Archive -Path $basePath\$file -DestinationPath $basePath -Force

$content = & $openSSL pkcs7 -inform PEM -in $basePath\$certDir\$certFile -print_certs

foreach ($line in $content) {
    $line
    if ($line -like "*subject*") {
        $fileName = $line.Split('=')[6]
        if (Test-Path -Path $basePath\$fileName.cer) {
            Remove-Item $basePath\$fileName.cer
        }
    }
    $line >> $basePath\$fileName.cer
}
if (Test-Path -Path $basePath\$dodChain) {
    Remove-Item $basePath\$dodChain
}
Get-Content -Path c:\temp\*.cer | Add-Content -Path c:\temp\DoD_Chain.pem -Encoding utf8