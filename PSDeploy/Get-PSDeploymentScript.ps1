Function Get-PSDeploymentScript {
    <#
    .SYNOPSIS
        Get deployment types and associated scripts

    .DESCRIPTION
        Get deployment types and associated scripts

        Checks PSDeploy.yml,
        verifies deployment scripts exist,
        returns a hashtable of these.

    .EXAMPLE
        Get-PSDeploymentScript

        Name              Value                                                                                                                                                                                                                 
        ----              -----                                                                                                                                                                                                                 
        Filesystem        C:\Path\To\PSDeploy\PSDeployScripts\Filesystem.ps1                                                                                                                                                      
        FilesystemRemote  C:\Path\To\PSDeploy\PSDeployScripts\FilesystemRemote.ps1

    .LINK
        about_PSDeploy

    .LINK
        Invoke-PSDeployment

    .LINK
        Get-PSDeployment

    .LINK
        Get-PSDeploymentType
    #>
    [cmdletbinding()]
    param()

    # Abstract out reading the yaml and verifying scripts exist
    $DeploymentDefinitions = ConvertFrom-Yaml -Path $(Join-Path $PSScriptRoot PSDeploy.yml)

    $DeployHash = @{}
    foreach($DeploymentType in $DeploymentDefinitions.Keys)
    {
        #Determine the path to this script
        $Script =  $DeploymentDefinitions.$DeploymentType.Script
        if(Test-Path $Script)
        {
            $ScriptPath = $Script
        }
        else
        {
            # account for missing ps1
            $ScriptPath = Join-Path $PSScriptRoot "PSDeployScripts\$($Script -replace ".ps1$").ps1"
        }

        if(test-path $ScriptPath)
        {
            $DeployHash.$DeploymentType = $ScriptPath
        }
        else
        {
            Write-Error "Could not find path '$ScriptPath' for deployment $DeploymentType. Origin: $($DeploymentDefinitions.$DeploymentType.Script)"
        }
    }

    $DeployHash
}