<#

.SYNOPSIS
    Gets all webfarms hosted on a given ARR. If servers are added in webfarm by their IP address, script replaces
    old IP address of the server with the new IP address.

.DESCRIPTION
    This script should be used in conjuction with IISARRTierFailover.ps1 runbook. 


.INPUTS
    old and new IP address of IIS server.Example of IPAddressMApping : 198.10.0.1,10.0.0.1
    
.OUTPUTS
    None.
  

.NOTE
    The script is for Azure classic portal only.   

     Author: sakulkar@microsoft.com

#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$IPAddressMapping
)
try
{
    $dll=[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
    #Get the manager and config object
    $mgr = new-object Microsoft.Web.Administration.ServerManager
    $conf = $mgr.GetApplicationHostConfiguration()

    #Get the webFarms section
    $section = $conf.GetSection("webFarms")
    $webFarms = $section.GetCollection()

    $temp = $IPAddressMapping.Split(",")
    $oldIpAddress = $temp[0]
    $newIpAddress = $temp[1]

    foreach ($webFarm in $webFarms)
    {
        $famrName= $webFarm.GetAttributeValue("name");
        #Get the servers in the farm
        $servers = $webFarm.GetCollection()

        foreach($server in $servers)
        {
            $IPAddress= $server.GetAttributeValue("address")
            if($IPAddress.Equals($oldIpAddress))
            {
                Stop-Service w3svc;

                cd $pathVariable

                try
                {
                    .\appcmd set config -section:webFarms /"[name='$farmName'].[address='$oldIpAddress'].address:$newIpAddress" /commit:apphost
                }
                catch
                {
                    throw("Unable to update Server farm")
                }

                Start-Service w3svc
            }
        }
    }
}
catch
{
    Start-Service w3svc
    $ErrorMessage = $_.Exception.Message
    throw($ErrorMessage)
}