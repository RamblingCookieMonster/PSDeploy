#Requires -module AzureRM.Resources
<#
    .SYNOPSIS
        Deploy using Azure Resource Manager cmdlets.

    .DESCRIPTION
        Deploy using Azure Resource Manager.

        Runs in the current session (i.e. as the current user)

    .PARAMETER Deployment
        Deployment to run
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment
)

Write-Verbose "Starting ARM deployment with $($Deployment.count) sources"

foreach($Map in $Deployment)
{
    if($Map.SourceExists)
    {
        # In this case, Targets refers to a Resource Group
        $Targets = $Map.Targets
        foreach($Target in $Targets)
        {   
            # These parameters will always be present when following the scenario of deploying from a template file.
            $deploymentParameters = @{
                'ResourceGroupName' = $Target
                'TemplateFile' = $Map.Source
            }
            
            # There are additional parameters to consider.
            # Parameter files should probably always exist but there might be cases where a template is very simple and someone wants the deployment to prompt for input.
            foreach ($option in $Map.DeploymentOptions.Keys) {
                $deploymentParameters.Add($option,$Map.DeploymentOptions.$option)
            }
                                    
            # Not sure this should handle RG creation.  Staging for now.
            # Resource groups are seperate from deployments.  Verify the target exists.
            <#
            $ResourceGroup = Get-AzureRmResourceGroup -Name $Target -ErrorAction 'SilentlyContinue'
            if (!$ResourceGroup) {$ResourceGroup = New-AzureRmResourceGroup -Name $Target -Location $Map.DeploymentOptions.ResourceGroupLocation}
            #>
            
            # The deployment actually happens here
            Write-Verbose "Deploying template '$($Map.Source)' to '$Target'"
            New-AzureRmResourceGroupDeployment @deploymentParameters
        }
    }
}