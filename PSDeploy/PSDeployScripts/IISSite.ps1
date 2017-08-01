<#
    .SYNOPSIS
        Support deployments by handling simple tasks.

    .DESCRIPTION
        Support deployments by handling simple tasks.

        You can use a Task in two ways:

        As a scriptblock:

            By Task {
                "Run some deployment code in this scriptblock!"
            }

        As a script:

            By Task {
                FromSource "Path\To\SomeDeploymentScript.ps1"
            }

    .PARAMETER Deployment
        Deployment to process
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,
    [string]  $name     = $null,    
    [string]  $appPool  = "DefaultAppPool",
    [Object[]]$bindings = $null
)

<#
    Creates an IIS website and sets the configuration
#>
function Create-IISWebsite
{
    param(
        [string]  $name     = $null,
        [string]  $root     = $null,
        [string]  $appPool  = "DefaultAppPool",
        [Object[]]$bindings = $null
    )
    
    begin
    {
    
        if(-not $name) { throw "Empty site name, Argument -Name is missing"        }
        if(-not $root) { throw "Empty website root path, Argument -Root is missing"}
        
        
        # SETTINGS
        
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
        # Website Settings
        [string]$name    = $null,
        [string]$root    = $null
    )
    
    begin
    {
        if(-not $name) { throw "Empty site name, Argument -Name is missing"        }
        if(-not $root) { throw "Empty website root path, Argument -Root is missing"}
        
        
        # SETTINGS
        
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
    # TODO: Multiple Targets
    # TODO: Remote Machines
    $root = $site.Targets[0]
    Remove-IISWebsite -name $name -root $root
    Create-IISWebsite -name $name -root $root -bindings $bindings
}