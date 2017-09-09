<#
    .SYNOPSIS
        Deploys an IISSite using Powershell

    .DESCRIPTION
        Deploys an IISSite using Powershell
    
        By IISSite MyWebsite {
            To .\wwwroot
            WithOptions @{
                name = "SiteName"
                bindings = @(
                    @{protocol="http"; bindingInformation="*:80:www.myurl.com" }
                    @{protocol="https"; bindingInformation="*:443:www.myurl.com" }
                    )
            }
        }

        To: Is the root path of the Website to deploy using IIS, currently only one target is supported

    .PARAMETER Deployment
        Deployment to process

    .PARAMETER Name
        Name of the Site under which it will be listed in IIS

    .PARAMETER AppPool
        AppPool to be used for this site in IIS, will be created if it does not exist. But it is recommend to use the extra 
        Deployment Type IISAppPool to setup a AppPool with specific settings.

    .PARAMETER Bindings
        Bindings under which this Site should be reachable
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory=$true, Position=1)]
    [string]  $Name     = $null,    

    [Parameter(Mandatory=$false, Position=2)]
    [string]  $AppPool  = "DefaultAppPool",

    [Parameter(Mandatory=$false, Position=3)]
    [Object[]]$Bindings = $null
)

<#
    Creates an IIS website and sets the configuration
#>
function Create-IISWebsite
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $name     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $root     = $null,

        [string]  $appPool  = "DefaultAppPool",
        [Object[]]$bindings = $null
    )
    
    begin
    {
        # IIS Directory Settings
        [string]$iisSite = "IIS:\Sites\$($name)\"
    }
    
    process
    {
        Write-Verbose "Creating IIS Website: $name"
        
        if($bindings -ne $null)
        {
            New-Item $iisSite -Type Site -Bindings $bindings -PhysicalPath $root
        }
        else
        {
            New-Item $iisSite -Type Site -PhysicalPath $root
        }
        
        Set-ItemProperty $iisSite -Name ApplicationPool -Value $appPool
    }
    
    End {}
}

<#
    Removes the IIS Website installation for the given site name.
    The application pool gets only removed if the -appPoolName parameter is supplied.
#>
function Remove-IISWebsite
{
    param(                
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name    = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$root    = $null
    )
    
    begin
    {
        # IIS Directory Settings
        [string]$iisSite = "IIS:\Sites\$($name)"
    }
    
    process
    {
        # Remove Website
        if(Test-Path $iisSite)
        {
            Write-Verbose "Deleting IIS Website: $name"
            
            Remove-Website $name
        }
    }
    
    End {}
}


foreach($site in $Deployment)
{
    if (!(Get-Module WebAdministration))
    {
        ## Load it nested, and we'll automatically remove it during clean up.
        Import-Module WebAdministration -ErrorAction Stop
        Sleep 2 #see http://stackoverflow.com/questions/14862854/powershell-command-get-childitem-iis-sites-causes-an-error
    }

    [string]$iisPoolPath = "IIS:\AppPools\$($AppPool)\"

    if(!(Test-Path $iisPoolPath))
    {
        Write-Verbose "AppPool $name does not exist, it will be created with default settings. For special settings please use IISAppPool as individual Deployment Type"
        # Workaround to call the IISAppPool creation from within this Deployment type $Deployment is forwarded but not processed.
        . $PSScriptRoot\IISAppPool.ps1 -Deployment $Deployment -Name $AppPool
    }

    $root = $site.Targets[0]

    Remove-IISWebsite -name $Name -root $root
    Create-IISWebsite -name $Name -root $root -bindings $Bindings -appPool $AppPool
}