<#
    .EXAMPLE
    Add a new host to the host file
#>
configuration UpdateDSCServerHostFile
{
    param
    (
        [string[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking
    $h = 0

    Node $NodeName
    {
        Foreach ($Computer in $config.AllNodes.Where{$_.Role -match "DC" -or $_.Role -match "Member"}) {
            xHostsFile "HostEntry$h" {
                HostName = $Computer.Nodename
                IPAddress = $Computer.IPAddress
                Ensure = 'Present'
            }
            $h++
        }
     
    }
}
