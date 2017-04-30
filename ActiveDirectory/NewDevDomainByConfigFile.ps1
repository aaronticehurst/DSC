#requires -RunAsAdministrator
#requires -module PSDesiredStateConfiguration
#requires -module xActiveDirectory
#requires -module xNetworking
#requires -module xComputerManagement

[cmdletbinding()]
param(
      
    [parameter(Mandatory = $True,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 8)]
    [pscredential]$Credential
)

#Taken from https://msdn.microsoft.com/en-us/powershell/dsc/securemof
# note: These steps need to be performed in an Administrator PowerShell session
$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256
# export the private key certificate
$mypwd = $credential.Password
$cert | Export-PfxCertificate -FilePath "$env:temp\DscPrivateKey.pfx" -Password $mypwd -Force
# remove the private key certificate from the node but keep the public key certificate
$cert | Export-Certificate -FilePath "$env:temp\DscPublicKey.cer" -Force
$cert | Remove-Item -Force
Import-Certificate -FilePath "$env:temp\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My

#Configure config data
#Add on the fly generated certificate encryption configuration to config data

$b = Get-content $PSScriptRoot\NewDevDomainByConfigFile.psd1 -Raw
$c = $b -split '\n'| 
    Foreach-Object {
    $_ 
    if ($_ -match 'AllNodes = @\(') {
        
        @"
@{
       NodeName = '*'
       PSDscAllowPlainTextPassword = "$False"
       RetryCount = 30
       RetryIntervalSec = 30
       CertificateFile = "$env:temp\DscPublicKey.cer"
       ThumbPrint = "$($cert.Thumbprint)"
   },
"@   
    }
} 

$Config = Invoke-Expression ($c | out-string)

#Configure DSC server host file to be able to find the future domain controllers
. .\UpdateDSCServerHostFile.ps1
UpdateDSCServerHostFile -configurationData $config 
Start-DscConfiguration .\updateDSCServerHostFile\ -Wait -Verbose -Force

#On DSC server
#Set DSC server to be able to connect to non domain joined host
set-item wsman:\localhost\Client\TrustedHosts -value * -Force

#Copy DSC modules to new servers:

foreach ($server in ($config.AllNodes.nodename | Where-Object {$_ -ne '*'})) {
    $Session = New-PSSession -ComputerName $server -Authentication Negotiate -Credential $Credential
    Write-Output "Copying modules to $server"
    Copy-Item -Path "C:\Program Files\WindowsPowerShell\Modules\x*" -Recurse -Destination "C:\Program Files\WindowsPowerShell\Modules" -ToSession $session -Force
    Write-Output "Copying Certificate to $server"
    copy-item -path "$env:temp\DscPrivateKey.pfx" -Destination "C:\windows\temp\" -ToSession $session -Force

    Invoke-Command {
        Write-Output "Importing certificate on $env:COMPUTERNAME"
        Import-PfxCertificate -FilePath "c:\Windows\temp\DscPrivateKey.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $USING:mypwd > $null
    } -Session $Session

    Get-PSSession -Name $Session.Name | Remove-PSSession
}


#Build new domain controllers mof file
. .\NewDomain.ps1
NewDomain -configurationData $config -Credential $Credential 

Set-DSCLocalConfigurationManager -Path $PSScriptRoot\NewDomain -Verbose -Credential $Credential 
Start-DscConfiguration -Wait -Force -Verbose -Path $PSScriptRoot\NewDomain -Credential $Credential 

#Join members to domain
If ($Config.AllNodes | Where-Object {$_.role -eq "Member"}) {
    . .\JoinMemberToDomain.ps1
    JoinMemberToDomain -configurationData $Config -Credential $Credential

    Set-DSCLocalConfigurationManager -Path $PSScriptRoot\JoinMemberToDomain -Verbose -Credential $Credential 
    Start-DscConfiguration -Wait -Force -Verbose -Path $PSScriptRoot\JoinMemberToDomain -Credential $Credential 
}

#Clean up local encryption Certificate
Get-ChildItem Cert:\LocalMachine\My\| Where-Object {$_.Thumbprint -eq $cert.Thumbprint } | Remove-Item