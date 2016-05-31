Function WithOptions {
    <#
    .SYNOPSIS
        Specify options for a DeploymentType

    .DESCRIPTION
        Specify options for a DeploymentType.  This includes both DeploymentOptions and DeploymentParameters.

        These are passed directly to the DeploymentType script in two was:
            - They are splatted against the script*
            - The are included in the $Deployment.DeploymentOptions property

        * If a parameter is not valid, it is removed before splatting, but still available in DeploymentOptions

        See Get-PSDeploymentType for details on different DeploymentTypes,
        and Get-PSDeploymentType -DeploymentType <Type> -ShowHelp to see the parameters they accept

        This is not intended to be used anywhere but in a *.PSDeploy.ps1 file. It is included here for intellisense support

    .PARAMETER Options
        Accepts a hashtable of options

    .EXAMPLE

        # This is a complete PSDeploy.ps1 example including a By function

        Deploy DeployMyModule
            By FileSystem {
                FromSource 'MyModule'
                To 'C:\sc\MyModule'
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
                To 'C:\sc\MyModule'
                WithOptions @{
                    Mirror = $True
                }
            }

            By FileSystem Tasks {
                FromSource 'Tasks'
                To 'C:\sc\Tasks'
            }
        }

        # This illustrates using two of the same DeploymentTypes, with different options and details.
        # We specify a name to ensure uniqueness of the resulting DeploymentName: DeployMyModule and DeployMyModule-Tasks
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
                    Mandatory = $True,
                    ValueFromPipeline = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [System.Collections.Hashtable]$Options
    )
    begin
    {
        $All = @{}
    }
    Process
    {
        $All += $Options
    }
    end
    {
        $Script:ThisBy.DeploymentOptions = $All
    }
}