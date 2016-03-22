Function Tag {
    <#
    .SYNOPSIS
        Specify tags for deployments in a 'By' block

    .DESCRIPTION
        Specify tags for deployments in a 'By' block

        This is not intended to be used anywhere but in a *.PSDeploy.ps1 file. It is included here for intellisense support

    .PARAMETER Tags
        One or more tags for a deployment

    .EXAMPLE

        # This is a complete PSDeploy.ps1 example including a By function

        Deploy DeployMyModule
            By FileSystem {
                FromSource 'MyModule'
                To 'C:\sc\'
                Tag Prod, Module
                WithOptions @{
                    Mirror = $True
                }
            }

            By FileSystem Tasks {
                FromSource 'Tasks'
                To 'C:\sc\'
                Tag Prod, Script
            }
        }

        # This illustrates using two of the same DeploymentTypes, with different options and details.
        # We specify a name to ensure uniqueness of the resulting DeploymentName: DeployMyModule and DeployMyModule-Tasks
        # This would deploy the folder 'MyModule' to C:\sc\MyModule. It would mirror (i.e. remove items that are not in the source)
        # This would deploy the folder Tasks to C:\sc\Tasks, without mirroring.

        # Tags are provided for each.  If Invoke-PSDeploy or Get-PSDeployment are called with -Tags, only the associated deployments would go through.

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
        [string[]]$Tags
    )

    $Script:ThisBy.Tags = $Tags
}