Function Get-PSDeploymentScript {
    <#
    .SYNOPSIS
        Get deployment types and associated scripts

    .DESCRIPTION
        Get deployment types and associated scripts

        Checks PSDeploy.yml,
        verifies deployment scripts exist,
        returns a hashtable of these.

    .PARAMETER Path
        Path to PSDeploy.yml defining deployment types

        Defaults to PSDeploy.yml in the module root

    .EXAMPLE
        Get-PSDeploymentScript

        Name              Value
        ----              -----
        Filesystem        C:\Path\To\PSDeploy\PSDeployScripts\Filesystem.ps1
        FilesystemRemote  C:\Path\To\PSDeploy\PSDeployScripts\FilesystemRemote.ps1

    .EXAMPLE
        Get-PSDeploymentScript -Path \\Path\To\Central\PSDeploy.yml

        Name              Value
        ----              -----
        Filesystem        \\Path\To\Central\Scripts\Filesystem.ps1
        FilesystemRemote  \\Path\To\Central\Scripts\FilesystemRemote.ps1
        OtherDeployment   \\Path\To\Central\Scripts\OtherDeployment.ps1

    .LINK
        about_PSDeploy

    .LINK
        https://github.com/RamblingCookieMonster/PSDeploy

    .LINK
        Invoke-PSDeployment

    .LINK
        Get-PSDeployment

    .LINK
        Get-PSDeploymentType

    .LINK
        Invoke-PSDeploy
    #>
    [cmdletbinding()]
    param(
        [validatescript({Test-Path $_ -PathType Leaf -ErrorAction Stop})]
        [string]$Path = $(Join-Path $ModulePath PSDeploy.yml)
    )

    # Abstract out reading the yaml and verifying scripts exist
    $DeploymentDefinitions = ConvertFrom-Yaml -Path $Path
    $DefinitionPath = Split-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path) -Parent

    $DeployHash = @{}
    foreach($DeploymentType in $DeploymentDefinitions.Keys)
    {
        #Determine the path to this script
        $Script =  $DeploymentDefinitions.$DeploymentType.Script
        if(Test-Path $Script -ErrorAction SilentlyContinue)
        {
            $ScriptPath = $Script
        }
        else
        {
            # Search in the module's installed path as well as the PSDeploy.yml path if a custom one was defined
            foreach ($p in @($ModulePath, $DefinitionPath | Select-Object -Unique)) {
                # account for missing ps1
                $ScriptPath = [System.IO.Path]::Combine($p, "PSDeployScripts", $Script -replace ".ps1$") + ".ps1"
                if (Test-Path $ScriptPath) {
                    break
                }
            }
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
