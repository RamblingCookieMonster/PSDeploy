Function Invoke-PSDeploy {
    <#
    .SYNOPSIS
        Invoke PSDeploy

    .DESCRIPTION
        Invoke PSDeploy

        Searches for .PSDeploy.ps1 files in the current and nested paths,
        and invokes their deployment

        See Get-Help about_PSDeploy for more information.

    .PARAMETER Path
        Path to a specific PSDeploy.ps1 file, or to a folder that we recursively search for *.PSDeploy.ps1 files

        Defaults to the current path

    .PARAMETER Tags
        Only invoke deployments that are tagged with all of the specified Tags (-and, not -or)

    .PARAMETER PSDeployTypePath
        Specify a PSDeploy.yml file that maps DeploymentTypes to their scripts.

        This defaults to the PSDeploy.yml in the PSDeploy module folder

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

        # Add later. Pass on to Invoke-PSDeployment.
        [validatescript({Test-Path -Path $_ -PathType Leaf -ErrorAction Stop})]
        [string]$PSDeployTypePath = $(Join-Path $PSScriptRoot PSDeploy.yml),

        [string[]]$Tags,

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
        if($PSBoundParameters.ContainsKey('PSDeployTypePath'))
        {
            $InvokePSDeploymentParams.add('PSDeployTypePath',$PSDeployTypePath)
        }

        $TagParam = @{}
        if($PSBoundParameters.ContainsKey('Tags'))
        {
            $TagParam.Add('Tags',$Tags)
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

        $PSDeployParams = @{Path = $DeploymentFiles}
        if($PSBoundParameters.ContainsKey('Tags'))
        {
            $TagParam.Add('Tags',$Tags)
        }
        Get-PSDeployment @PSDeployParams | Invoke-PSDeployment @InvokePSDeploymentParams
    }
}