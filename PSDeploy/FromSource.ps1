# From is a reserved keyword...
Function FromSource {
    <#
    .SYNOPSIS
        Specify sources to deploy in a 'By' block of a PSDeploy.ps1

    .DESCRIPTION
        Specify sources to deploy in a 'By' block of a PSDeploy.ps1

        This is not intended to be used anywhere but in a *.PSDeploy.ps1 file. It is included here for intellisense support

        We can't use 'From,' given that Microsoft reserves this for future use as a keyword

    .PARAMETER Source
        One or more source items to deploy

    .PARAMETER DeploymentRoot
        If using relative paths, you can override the starting path.

        Defaults to your current path.

    .EXAMPLE

        # This is a complete PSDeploy.ps1 example including a By function

        Deploy DeployMyModule
            By FileSystem {
                FromSource 'MyModule'
                To 'C:\sc\'
                WithOptions @{
                    Mirror = $True
                }
            }
        }

        # This would deploy the folder 'MyModule' to C:\sc\MyModule. It would mirror (i.e. remove items that are not in the source)

    .EXAMPLE

        # This is a complete PSDeploy.ps1 example including a By function

        Deploy DeployMyModule
            By FileSystem {
                FromSource 'MyModule'
                To 'C:\sc\'
                WithOptions @{
                    Mirror = $True
                }
            }

            By FileSystem Tasks {
                FromSource 'Tasks'
                To 'C:\sc\'
            }
        }

        # This illustrates using two of the same DeploymentTypes, with different options and details.
        # We specify a name to ensure uniqueness of the resulting DeploymentName: DeployMyModule and DeployMyModule-Tasks
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
        [object[]]$Source,

        [parameter( Position = 1,
                    Mandatory = $false)]
        [string]$DeploymentRoot = (Get-Location).Path
    )

    $Script:ThisBy.Source = $Source
}