Configuration Install-SMAWebPrereqs {
#Based this off xSCSMA from PowerShell Gallery, https://www.powershellgallery.com/packages/xSCSMA/1.5.0.0
#The 1.5.0.0 version has a few issues and I just wanted to at least have something to configure prerequisites for SMA web service.

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

            WindowsFeature "Web-Basic-Auth"
            {
                Ensure = "Present"
                Name = "Web-Basic-Auth"
            }

            WindowsFeature "Web-Url-Auth"
            {
                Ensure = "Present"
                Name = "Web-Url-Auth"
            }

            WindowsFeature "Web-Windows-Auth"
            {
                Ensure = "Present"
                Name = "Web-Windows-Auth"
            }

            WindowsFeature "Web-Asp-Net45"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net45"
            }

            WindowsFeature "NET-WCF-HTTP-Activation45"
            {
                Ensure = "Present"
                Name = "NET-WCF-HTTP-Activation45"
            }
        }
    
}
