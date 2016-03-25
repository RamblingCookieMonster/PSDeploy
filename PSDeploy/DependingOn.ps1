Function DependingOn {
    <#
    .SYNOPSIS
        Specify dependencies for a By block

    .DESCRIPTION
        Specify dependencies for a By block.

        This is not intended to be used anywhere but in a *.PSDeploy.ps1 file. It is included here for intellisense support

    .PARAMETER Dependencies
        One or more Deployment names that we will depend upon.

        Keep in mind if you name your 'By' block, the final DeploymentName will be:

            DeploymentName-ByName

    .EXAMPLE

        # This is a complete PSDeploy.ps1 example including a By function

        Deploy DeployMyModule
            By FileSystem {
                FromSource 'MyModule'
                To 'C:\sc\'
                WithOptions @{
                    Mirror = $True
                }
                DependingOn DeployMyModule-Tasks
            }

            By FileSystem Tasks {
                FromSource 'Tasks'
                To 'C:\sc\'
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
        https://github.com/RamblingCookieMonster/PSDeploy

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
                    Mandatory = $True)]
        [string[]]$Dependencies
    )

    $Script:ThisBy.Dependencies = $Dependencies
}