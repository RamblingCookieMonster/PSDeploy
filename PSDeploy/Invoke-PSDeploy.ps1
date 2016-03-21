Function Invoke-PSDeploy {
    <#
    .SYNOPSIS
        Invoke PSDeploy

    .DESCRIPTION
        Invoke PSDeploy

        Searches for .PSDeploy.ps1 files in the current and nested paths,
        and invokes their deployment

        See Get-Help about_PSDeploy for more information.

    .PARAMETER Deployment
        Deployment object from Get-PSDeployment.

    .PARAMETER DeploymentFile
        Deployment file. We run Get-PSDeployment against it.

    .PARAMETER DeploymentParameters
        Hashtable of hashtables

        The first layer of keys are the deployment types
        These deployment types are assigned a hashtable of parameters

        So, pretend we have a FileSystemRemote deployement. Here's how we pass parameters:
        -DeploymentParameters @{
            FilesystemRemote = @{
                ComputerName = 'DeployFromThis'
                Credential = $CredentialForDeploy
                ConfigurationName = 'SomeSessionConfigToHit'
            }
        }

        In this case, any deployments of 'FilesystemRemote' type will use those parameters

        Why separate this out?
            What if I have a deployment that takes two sorts of parameters?
            What if I want to add a new deployment type without modifying this function?

        Okay, now what if we have two types, and want to fit it all on one line?
        - DeploymentParameters @{ FilesystemRemote=@{ComputerName = 'PC1'}; Filesystem=@{} }

    .PARAMETER Force
        Force deployment, skipping prompts and confirmation

    .EXAMPLE
        Invoke-PSDeployment -Path C:\Git\Module1\Deployments.yml

        # Run deployments from a deployment yml. You will be prompted on whether to deploy

    .EXAMPLE
        Get-PSDeployment -Path C:\Git\Module1\Deployments.yml, C:\Git\Module2\Deployments.yml |
            Invoke-PSDeployment -Force

        # Get deployments from two yml files, invoke their deployment, no prompting

    .EXAMPLE
        Invoke-PSDeployment -Path C:\Git\Module1\Deployments.yml -PSDeployTypePath \\Path\To\Central\PSDeploy.yml

        # Run deployments from a deployment yml. Use deployment type definitions from a central config.

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
    [cmdletbinding( SupportsShouldProcess = $True,
                    ConfirmImpact='High' )]
    Param(
        [parameter( ValueFromPipeline = $True,
                    ValueFromPipelineByPropertyName = $True)]
        [string[]]$Path = '.',

        [Hashtable]$DeploymentParameters,

        [validatescript({Test-Path -Path $_ -PathType Leaf -ErrorAction Stop})]
        [string]$PSDeployTypePath = $(Join-Path $PSScriptRoot PSDeploy.yml),

        [switch]$Force
    )
    Begin
    {
        # This script reads a deployment YML, deploys files or folders as defined
        Write-Verbose "Running Invoke-PSDeploy with ParameterSetName '$($PSCmdlet.ParameterSetName)' and params: $($PSBoundParameters | Out-String)"

        $RejectAll = $false
        $ConfirmAll = $false
        $DeploymentFiles = New-Object System.Collections.ArrayList

        $InvokePSDeploymentParams = @{}
        if($PSBoundParameters.ContainsKey('Confirm'))
        {
            $InvokePSDeploymentParams.add('Confirm',$Confirm)
        }
        if($PSBoundParameters.ContainsKey('Force'))
        {
            $InvokePSDeploymentParams.add('Force',$Force)
        }
    }
    Process
    {
        foreach( $PathItem in $Path )
        {
            # Create a map for deployments
            Try
            {
                # Debating whether to make this a terminating error.
                # Stop all deployments because one is misconfigured?
                # I'm going with Copy-Item precedent.
                # Not terminating, so try catch is superfluous. Feel free to make this strict...
                $DeploymentFiles.AddRange( @( Resolve-DeployScripts -Path $PathItem ) )
                if ($DeploymentFiles.count -gt 0)
                {
                    Write-Verbose "Working with $($DeploymentFiles.Count) deployment files:`n$($DeploymentFiles | Out-String)"
                }
                else
                {
                    Write-Warning "No *.PSDeploy.ps1 files found under '$PathItem'"
                }
            }
            Catch
            {
                Throw "Error retrieving deployments from '$PathItem':`n$_"
            }
        }

        Get-PSDeployment -Path $DeploymentFiles | Invoke-PSDeployment @InvokePSDeploymentParams

    }
}