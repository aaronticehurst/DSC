configuration JoinMemberToDomain
{
    [cmdletbinding()]
    param([parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [pscredential]$Credential
    )

    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xComputerManagement
    Import-DSCResource -ModuleName xNetworking

    Node $AllNodes.Where{$_.Role -eq "Member"}.Nodename

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

        xWaitForADDomain DscForestWait {
            DomainName = $ConfigurationData.DomainData.DomainName
            DomainUserCredential = $Credential
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[xDNSServerAddress]SetDNS"
        }

        xComputer DomainXJoin {
            Name = $node.Nodename
            DomainName = $ConfigurationData.DomainData.DomainName
            Credential = $Credential
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }
    }
}

