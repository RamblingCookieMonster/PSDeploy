Function WithPostScript {
    <#
    .SYNOPSIS
        Specify a script to run after the deployment in a By block

    .DESCRIPTION
        Specify a script to run after the deployment in a By block

        Keep in mind:
          * This runs in the current scope using dot sourcing
          * A FromSource with multiple sources will generate multiple deployments. In that scenario, this script will run for each of those deployments.
          * This is not implemented for yaml deployments

        This is not intended to be used anywhere but in a *.PSDeploy.ps1 file. It is included here for intellisense support

    .PARAMETER ScriptBlock
        One or more scriptblocks to execute after the deployment

    .PARAMETER Path
        One or more script files to execute after the deployment

    .EXAMPLE

        # This is a complete PSDeploy.ps1 example including a By function

        Deploy DeployMyModule
            By FileSystem {
                FromSource 'MyModule'
                To 'C:\sc\MyModule'
                Tagged Prod, Module
                WithPreScript {
                    "Set up a thing"
                    "Do another thing"
                }
            }

            By FileSystem Tasks {
                FromSource 'Tasks'
                To 'C:\sc\Tasks'
                Tagged Prod
                WithPostScript {
                    "Tear down a thing"
                }
            }
        }

        # This illustrates using two of the same DeploymentTypes, with different options and details.
        # We specify a name to ensure uniqueness of the resulting DeploymentName: DeployMyModule and DeployMyModule-Tasks
        # This would deploy the folder 'MyModule' to C:\sc\MyModule. It would mirror (i.e. remove items that are not in the source)
        # This would deploy the folder Tasks to C:\sc\Tasks, without mirroring.
        # This will run a setup script for the MyModule deployment.  You can include arbitrary PowerShell in this scriptblock
        # THis will run a teardown script for the Tasks deployment.

    .LINK
        about_PSDeploy

    .LINK
        about_PSDeploy_Definitions

    .LINK
        https://github.com/RamblingCookieMonster/PSDeploy

    .LINK
        Deploy

    .LINK
        By

    .LINK
        To

    .LINK
        FromSource

    .LINK
        WithOptions

    .LINK
        DependingOn

    .LINK
        Get-PSDeployment

    .LINK
        Get-PSDeploymentType

    .LINK
        Get-PSDeploymentScript
    #>
    [cmdletbinding()]
    param(
        [parameter( Position = 0,
                    ValueFromPipeline = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [scriptblock[]]$ScriptBlock,

        [parameter( Position = 1 )]
        [validatescript({Test-Path $_})]
        [string[]]$Path
    )
    begin
    {
        $ScriptsToProcess = New-Object System.Collections.ArrayList
        if($PSBoundParameters.ContainsKey('Path'))
        {
            foreach($dir in $Path)
            {
                $sb = [scriptblock]::Create( $(Get-Content $ScriptFile -Raw) )
            }
            $Pair = [pscustomobject]@{
                ScriptBlock = $sb
                SkipOnError = $null
            }
            [void]$ScriptsToProcess.Add($pair)
        }
    }
    Process
    {
        foreach($sb in $ScriptBlock)
        {
            $Pair = [pscustomobject]@{
                ScriptBlock = $sb
                SkipOnError = $null
            }
            [void]$ScriptsToProcess.Add($pair)
        }
    }
    end
    {
        $Script:ThisBy.PostScript = @( $ScriptsToProcess )
    }
}