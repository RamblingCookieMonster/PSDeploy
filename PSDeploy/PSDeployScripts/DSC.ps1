<#
    .SYNOPSIS
        Deploy configuration using PowerShell DSC

    .DESCRIPTION
        Deploy using PowerShell DSC.
        
        This script currently implements the PUSH method though it is conceivable that deploying
        to a PULL service would also be possible.

        Runs in the current session (i.e. as the current user)

    .PARAMETER Deployment
        Deployment to run
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,
    
    [switch]$Wait
)

Write-Verbose "Starting DSC deployment with $($Deployment.count) sources"

foreach($Map in $Deployment)
{
    if($Map.SourceExists)
    {
        # Targets refers to computers
        $Targets = $Map.Targets
        foreach($Target in $Targets)
        {   
            # Follow parameters for Start-DSCConfiguration
            $deploymentParameters = @{
                'ComputerName' = $Target
                'Path' = $Map.Source
            }
            
            # If indicated by the Wait switch, the console should not return until after the job has completed
            if ($Wait) {
                $deploymentParameters.Add('Wait',$true)
            }
                                    
            # Call native cmdlet
            Write-Verbose "Deploying template '$($Map.Source)' to '$Target'"
            Start-DSCCOnfiguration @deploymentParameters
        }
    }
}