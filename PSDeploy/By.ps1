Function By {
    <#
    .SYNOPSIS
        Specify details about the DeploymentType for deployments defined in a PSDeploy.ps1

    .DESCRIPTION
        Specify details about the DeploymentType for deployments defined in a PSDeploy.ps1

        This is not intended to be used anywhere but in a *.PSDeploy.ps1 file. It is included here for intellisense support

    .PARAMETER DeploymentType
        The type of deployment you are defining. For example, a FileSystem deployment.

        See Get-PSDeploymentType for a list of valid deployment types.

    .PARAMETER Name
        An optional name for the deployment in this 'By' block.

        This would be needed if you wanted more than one 'By' block for a single DeploymentType.

        This is tacked on to the Deploy Name: DeployName-ByName.

    .PARAMETER Script
        Details on the deployment. You can include the following functions inside your By:
            - FromSource:  The item(s) you are deploying. Required.
            - To:          The target(s) you are deploying to. Required.
            - WithOptions:   Any DeploymentType specific options

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
        [parameter( Position = 0,
                    Mandatory = $True)]
        [string]$DeploymentType,

        [parameter( ParameterSetName = 'Name',
                    Position = 1,
                    Mandatory = $False)]
        [string]$Name,

        [parameter( ParameterSetName = 'NoName',
                    Position = 1,
                    Mandatory = $true)]
        [parameter( ParameterSetName = 'Name',
                    Position = 2,
                    Mandatory = $true)]
        [ScriptBlock]$Script
    )

    $Script:ThisBy = [pscustomobject]@{
        DeploymentName = $null
        DeploymentType = $null
        Source = $null
        Targets = $null
        DeploymentOptions = $null
        Tags = $null
        Dependencies = $null
        PreScript = $null
        PostScript = $null
    }

    if( $PSCmdlet.ParameterSetName -eq 'Name')
    {
        $Name = "$($Script:ThisDeployment.DeploymentName)-$Name"
    }
    else
    {
        $Name = $Script:ThisDeployment.DeploymentName
    }

    $Namespace = @( $Script:Deployments | Where {$_.DeploymentType -eq $DeploymentType -and $_.Name -eq $Name} )
    if($Namespace.Count -gt 0)
    {
        Write-Error "Could not add 'By $Name', please ensure your 'By' blocks have a unique name within their DeploymentType."
    }
    else
    {
        $Script:ThisBy.DeploymentName = $Name
        $Script:ThisBy.DeploymentType = $DeploymentType

        # Determine if task is calling FromSource (ps1 task type) or jut an arbitrary scriptblock (scriptblock task type)
        $CommandDetails = $script.ast.FindAll(
            {$args[0] -is [System.Management.Automation.Language.CommandAst]},
            $true
        )
        $Commands = Foreach($Command in $CommandDetails)
        {
            Try
            {
                $Command.CommandElements[0].SafeGetValue()
            }
            Catch
            {
            }
        }

        # If this is a scriptblock (not calling fromsource), add scriptblock to DeploymentSource to call later...
        if($DeploymentType -eq 'Task' -and $Commands -notcontains 'FromSource')
        {
            Write-Verbose "Adding script to source: $($Script | Out-String)"
            $Script:ThisBy.Source = $Script
        }
        else
        {
            . $Script
        }

        # One might imagine a case where a deployment has a source or a target but not both.
        # So... Don't stop them if one or the other is missing.
        if($null -eq $Script:ThisBy.Source)
        {
            Write-Verbose "Missing Source for By '$($ThisBy.DeploymentName)'"
        }
        if($null -eq $Script:ThisBy.Targets)
        {
            Write-Verbose "Missing Targets for By '$($ThisBy.DeploymentName)'"
        }

        try
        {
            [void]$Script:Deployments.Add($Script:ThisBy)
        }
        catch
        {
            Write-Error "Failed to generate deployment: $($Script:ThisBy | Out-String)"
            Throw $_
        }
        Remove-Variable -Name ThisBy -Scope Script -Confirm:$False -Force
    }
}