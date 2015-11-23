Function Invoke-PSDeployment {
    <#
    .SYNOPSIS
        Invoke a deployment

    .DESCRIPTION
        Invoke a deployment

        Takes output from Get-PSDeployment, or a deployment yml path.

        Runs deployment scripts depending on each deployment's type.

        If a deployment is not found, we continue processing other deployments.

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
    [cmdletbinding( DefaultParameterSetName = 'Map',
                    SupportsShouldProcess = $True,
                    ConfirmImpact='High' )]
    Param(
        [parameter( ValueFromPipeline = $True,
                    ParameterSetName='Map',
                    Mandatory = $True)]
        [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
        [psobject]$Deployment,

        [validatescript({Test-Path -Path $_ -PathType Leaf -ErrorAction Stop})]
        [parameter( ParameterSetName='File',
                    Mandatory = $True)]
        [string[]]$Path,

        [Hashtable]$DeploymentParameters,

        [validatescript({Test-Path -Path $_ -PathType Leaf -ErrorAction Stop})]
        [string]$PSDeployTypePath = $(Join-Path $PSScriptRoot PSDeploy.yml),

        [switch]$Force    
    )
    Begin
    {
        # This script reads a deployment YML, deploys files or folders as defined
        Write-Verbose "Running Invoke-PSDeployment with ParameterSetName '$($PSCmdlet.ParameterSetName)' and params: $($PSBoundParameters | Out-String)"
        if($PSBoundParameters.ContainsKey('Path'))
        {
            # Create a map for deployments
            Try
            {
                #Resolve relative paths... Thanks Oisin! http://stackoverflow.com/a/3040982/3067642
                $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
                
                # Debating whether to make this a terminating error.
                # Stop all deployments because one is misconfigured?
                # I'm going with Copy-Item precedent.
                # Not terminating, so try catch is superfluous. Feel free to make this strict...
                $Deployment = Get-PSDeployment -Path $Path
            }
            Catch
            {
                Throw "Error retrieving deployments from '$Path':`n$_"
            }
        }        

        $RejectAll = $false            
        $ConfirmAll = $false  
    }
    Process
    {
        Write-Verbose "Deployments:`n$($Deployment | Out-String)"

        if( ($Force -and -not $WhatIf) -or
            $PSCmdlet.ShouldProcess( "Processed the deployment '$($Deployment.DeploymentName -join ", ")'",            
                                    "Process the deployment '$($Deployment.DeploymentName -join ", ")'?",            
                                    "Processing deployment" ))            
        {
            if($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to deploy '$($Deployment.DeploymentName -join ", ")'?", "Deploying '$($Deployment.DeploymentName -join ", ")'", [ref]$ConfirmAll, [ref]$RejectAll))
            {
                #Get definitions, and deployments in this particular yml
                $DeploymentDefs = Get-PSDeploymentScript
                $TheseDeploymentTypes = @( $Deployment.DeploymentType | Sort -Unique )

                #Build up hash, we call each deploymenttype script for applicable deployments
                $ToDeploy = @{}
                foreach($DeploymentType in $TheseDeploymentTypes)
                {
                    $DeploymentScript = $DeploymentDefs.$DeploymentType
                    if(-not $DeploymentScript)
                    {
                        Write-Error "DeploymentType $DeploymentType is not defined in PSDeploy.yml"
                        continue
                    }
                    $TheseDeployments = @( $Deployment | Where-Object {$_.DeploymentType -eq $DeploymentType})
                    
                    #Define params for the script
                    #Each deployment type can have a hashtable to splat.
                    if($PSBoundParameters.ContainsKey('DeploymentParameters') -and $DeploymentParameters.ContainsKey($DeploymentType))
                    {
                        $params = $DeploymentParameters.$DeploymentType
                    }
                    else
                    {
                        $params = @{}
                    }
                    
                    if($PSBoundParameters.ContainsKey('Verbose'))
                    {
                        $Params.Add('Verbose',[System.Management.Automation.SwitchParameter]::Present)
                    }

                    $Params.Add('Deployment', $TheseDeployments)

                    Write-Verbose "Processing '$($TheseDeployments.count)' $DeploymentType deployments"

                    #Run the associated script, splat the parameters
                    & $DeploymentScript @params
                }
            }
        }
    }
}