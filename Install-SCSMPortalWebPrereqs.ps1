Configuration Install-SCSMPortalWebPrereqs {

param (
[string[]]$Computername
)
Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
Node $Computername 

        {
            WindowsFeature "Web-WebServer"
            {
                Ensure = "Present"
                Name = "Web-WebServer"
            }

            WindowsFeature "Web-ASP"
            {
                Ensure = "Present"
                Name = "Web-ASP"
            }

            WindowsFeature "Web-Asp-Net45"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net45"
            }

            WindowsFeature "Web-Basic-Auth"
            {
                Ensure = "Present"
                Name = "Web-Basic-Auth"
            }

            WindowsFeature "Web-Windows-Auth"
            {
                Ensure = "Present"
                Name = "Web-Windows-Auth"
            }  
                      
             WindowsFeature "Web-Net-Ext45"
            {
                Ensure = "Present"
                Name = "Web-Net-Ext45"
            }

             WindowsFeature "Web-Mgmt-Tools"
            {
                Ensure = "Present"
                Name = "Web-Mgmt-Tools"
            }

             WindowsFeature "Web-Mgmt-Console"
            {
                Ensure = "Present"
                Name = "Web-Mgmt-Console"
            }

             WindowsFeature "NET-WCF-HTTP-Activation45"
            {
                Ensure = "Present"
                Name = "NET-WCF-HTTP-Activation45"
            }

        }
    
}