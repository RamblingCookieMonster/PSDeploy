Function DependingOn {
    <#
    .SYNOPSIS
        Specify dependencies for a By block

    .DESCRIPTION
        Specify dependencies for a By block.

        IMPORTANT: This controls the order of operations. It does not prevent further execution o items if a dependency fails.

        This is not intended to be used anywhere but in a *.PSDeploy.ps1 file. It is included here for intellisense support

    .PARAMETER ScriptBlock
        ScriptBlock Dependency for By Block

    .PARAMETER DeploymentName
        One or more Deployment names that we will depend upon.

        Keep in mind if you name your 'By' block, the final DeploymentName will be:

            DeploymentName-ByName

    .EXAMPLE

        # This is a complete PSDeploy.ps1 example including a By function

        Deploy DeployMyModule {
            By FileSystem {
                FromSource 'MyModule'
                To 'C:\sc\MyModule'
                WithOptions @{
                    Mirror = $True
                }
                DependingOn DeployMyModule-Tasks   # <<<<<<
            }

            By FileSystem Tasks {
                FromSource 'Tasks'
                To 'C:\sc\Tasks'
            }
        }

        # This illustrates using two of the same DeploymentTypes, with different options and details.
        # We specify a name to ensure uniqueness of the resulting DeploymentName: DeployMyModule and DeployMyModule-Tasks
        # The deployments are processed based on dependencies.  Tasks will be deployed first.
        # This would deploy the folder 'MyModule' to C:\sc\MyModule. It would mirror (i.e. remove items that are not in the source)
        # This would deploy the folder Tasks to C:\sc\Tasks, without mirroring.

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
        Tagged

    .LINK
        WithOptions

    .LINK
        Get-PSDeployment

    .LINK
        Get-PSDeploymentType

    .LINK
        Get-PSDeploymentScript
    #>
    [cmdletbinding()]
    param(
        [parameter( Position = 0)]
        [string[]]$DeploymentName,

        [parameter( Position = 1)]
        [scriptblock]$ScriptBlock
    )

    $Dependencies = [pscustomobject]@{
        DeploymentName = $DeploymentName
        ScriptBlock = $ScriptBlock
    }

    $Script:ThisBy.Dependencies = $Dependencies
}