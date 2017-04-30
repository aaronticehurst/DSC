# A configuration to Create High Availability Domain Controller 
# You must know the local 'admninistrator' password of the servers to be made into dc's
# The replica dc's should have their primary dns pointed to the primary dc before beginning so they can discover the new domain
# All the servers need to have the xActiveDirectory dsc resource module copied the to c:\Program Files\WindowsPowerShell\Modules folder


configuration NewDomain
{
    [cmdletbinding()]
    param([parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [pscredential]$Credential
    )

    Import-DscResource -ModuleName xActiveDirectory
    Import-DSCResource -ModuleName xNetworking
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    $domainCred = $Credential   
    $safemodeAdministratorCred = $Credential  
    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename

    {
        LocalConfigurationManager {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true  
            CertificateID = $Node.ThumbPrint        
        }   

        xDNSServerAddress SetDNS {
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
            Address = $Node.DNSAddress
        }

        WindowsFeature ADDSInstall {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        WindowsFeature ADTools {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }

        xADDomain FirstDS {
            DomainName = $ConfigurationData.DomainData.DomainName
            DomainAdministratorCredential = $domaincred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DependsOn = "[WindowsFeature]ADDSInstall"

        }

        xWaitForADDomain DscForestWait {
            DomainName = $ConfigurationData.DomainData.DomainName
            DomainUserCredential = $domaincred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[xADDomain]FirstDS"
        }

       

    }

    Node $AllNodes.Where{$_.Role -eq "Replica DC"}.Nodename
    {

        LocalConfigurationManager {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true  
            CertificateID = $Node.ThumbPrint             
        }   
        xDNSServerAddress SetDNS {
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
            Address = $Node.DNSAddress
        }
        WindowsFeature ADDSInstall {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        WindowsFeature ADTools {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }

        xWaitForADDomain DscForestWait {
            DomainName = $ConfigurationData.DomainData.DomainName
            DomainUserCredential = $domaincred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomainController SecondDC {
            DomainName = $ConfigurationData.DomainData.DomainName
            DomainAdministratorCredential = $domaincred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }
    }
}

