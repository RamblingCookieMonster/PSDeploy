Function Get-PSDeploymentType {
    <#
    .SYNOPSIS
        Get deployment types and related information

    .DESCRIPTION
        Get deployment types and related information

        Checks PSDeploy.yml for deployment types,
        verifies deployment scripts exist,
        gets help content for deployment scripts,
        returns various info on each deployment type

    .PARAMETER DeploymentType
        Optionally limite to this DeploymentType

        Accepts wildcards

    .PARAMETER ShowHelp
        Show help content for specified deployment types

    .EXAMPLE
        Get-PSDeploymentType -DeploymentType FileSystem -ShowHelp

        Show help for the FileSystem deployment type.

    .EXAMPLE
        Get-PSDeploymentType

            DeploymentType    Description                                      DeploymentScript                                 HelpContent
            --------------    -----------                                      ----------------                                 -----------
            Filesystem        Uses the current session and Robocopy or Copy... C:\sc\stash\psdeploy\PSDeploy\PSDeployScripts... @{description=Sys...
            FilesystemRemote  Uses a PowerShell remoting endpoint and Roboc... C:\sc\stash\psdeploy\PSDeploy\PSDeployScripts... @{description=Sys...

        # Get deployment types

    .EXAMPLE
        Get-PSDeploymentType -Path \\Path\To\Central\PSDeploy.yml

            DeploymentType    Description                                      DeploymentScript                               HelpContent
            --------------    -----------                                      ----------------                               -----------
            Filesystem        Uses the current session and Robocopy or Copy... \\Path\To\Central\Scripts\Filesystem.ps1       @{description=Sys...
            FilesystemRemote  Uses a PowerShell remoting endpoint and Roboc... \\Path\To\Central\Scripts\FilesystemRemote.ps1 @{description=Sys...
            OtherDeployment   Some made up deployment type!                    \\Path\To\Central\Scripts\OtherDeployment.ps1  @{description=Sys...

        # Get deployment types from a central spot

    .LINK
        about_PSDeploy

    .LINK
        https://github.com/RamblingCookieMonster/PSDeploy

    .LINK
        Invoke-PSDeployment

    .LINK
        Get-PSDeployment

    .LINK
        Get-PSDeploymentScript

    .LINK
        Invoke-PSDeploy
    #>
    [cmdletbinding()]
    param(
        [validatescript({Test-Path $_ -PathType Leaf -ErrorAction Stop})]
        [string]$Path = $(Join-Path $PSScriptRoot PSDeploy.yml),
        [string]$DeploymentType = '*',
        [switch]$ShowHelp
    )

    # Abstract out reading the yaml and verifying scripts exist
    $DeploymentDefinitions = ConvertFrom-Yaml -Path $(Join-Path $PSScriptRoot PSDeploy.yml)

    foreach($Type in ($DeploymentDefinitions.Keys | Where {$_ -like $DeploymentType}))
    {
        #Determine the path to this script. Skip task deployments...
        $Script =  $DeploymentDefinitions.$Type.Script
        if($Script -ne '.')
        {
            if(Test-Path $Script)
            {
                $ScriptPath = $Script
            }
            else
            {
                # account for missing ps1
                $ScriptPath = Join-Path $PSScriptRoot "PSDeployScripts\$($Script -replace ".ps1$").ps1"
            }

            Try
            {
                $ScriptHelp = Get-Help $ScriptPath -Full -ErrorAction Stop
            }
            Catch
            {
                $ScriptHelp = "Error retrieving help: $_"
            }
        }
        if($ShowHelp)
        {
            $ScriptHelp
        }
        else
        {
            [pscustomobject]@{
                DeploymentType = $Type
                Description = $DeploymentDefinitions.$Type.Description
                DeploymentScript = $ScriptPath
                HelpContent = $ScriptHelp
            }
        }


    }


}