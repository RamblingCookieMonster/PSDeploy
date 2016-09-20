Function Deploy {
    <#
    .SYNOPSIS
        Specify deployment details in a PSDeploy.ps1

    .DESCRIPTION
        Specify deployment details in a PSDeploy.ps1

        You may specify multiple Deploy blocks in a single PSDeploy.ps1, as long as their names are unique.

        This is not intended to be used anywhere but in a *.PSDeploy.ps1 file. It is included here for intellisense support

    .PARAMETER Name
        A name for the deployment in a PSDeploy.ps1 file.

        If not specified, we generate and use a GUID.

        Get-PSDeployment will generate a new GUID each run,
        if you need to refer to the deployment in any consistent way,
        be sure to name it with this parameter.

    .PARAMETER Script
        Details on the deployment. You can include the following functions inside your Deploy scriptblock:
            - By: Deployment definitions for a particular DeploymentType

    .EXAMPLE

        # This is a complete PSDeploy.ps1 example including a By function

        Deploy DeployMyModule {
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

        Deploy DeployMyModule {
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
        DependingOn

    .LINK
        Get-PSDeployment

    .LINK
        Get-PSDeploymentType

    .LINK
        Get-PSDeploymentScript
    #>
    [cmdletbinding(DefaultParameterSetName = 'NoName')]
    param(
        [parameter( ParameterSetName = 'Name',
                    Position = 0,
                    Mandatory = $False)]
        [string]$Name,

        [parameter( ParameterSetName = 'Name',
                    Position = 1,
                    Mandatory = $True)]
        [parameter( ParameterSetName = 'NoName',
                    Position = 0,
                    Mandatory = $True)]
        [scriptblock]$Script

    )
    if($PSCmdlet.ParameterSetName -eq 'NoName')
    {
        [string]$Name = $( [guid]::NewGuid().Guid )
    }
    $Script:ThisDeployment = @{
        DeploymentName = $Name
    }

    . $Script
}