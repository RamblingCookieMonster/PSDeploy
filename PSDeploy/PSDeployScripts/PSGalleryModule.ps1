<#
    .SYNOPSIS
        Deploys a module to a PowerShell repository like the PowerShell Gallery.

    .DESCRIPTION
        Deploys a module to a PowerShell-based repository like the PowerShell Gallery. Can also be used to deploy to a private
        instance of PowerShell Gallery or to any nuget-based repository.

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER ApiKey
        API Key used to authenticate to PowerShell repository.
#>
[cmdletbinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory)]
    [string]$ApiKey
)

foreach($deploy in $Deployment) {
    if(-not $deploy.targets)
    {
        $deploy.targets = @('PSGallery')
    }

    foreach($target in $deploy.Targets) {
        Write-Verbose -Message "Starting deployment [$($deploy.DeploymentName)] to PowerShell repository [$Target]"

        # Validate that $target has been setup as a valid PowerShell repository
        $validRepo = Get-PSRepository -Name $target -Verbose:$false -ErrorAction SilentlyContinue
        if (-not $validRepo) {
            throw "[$target] has not been setup as a valid PowerShell repository."
        }

        # Publish-Module supports specifying either the name of a module or the path to a module.        
        # Since PSDeploy validates that the value specified in 'FromSource' is a valid path before
        # invoking the deployment script, we don't support specifying just the module name as that
        # would cause PSDeploy to throw an error when validating the value in FromSouce. For this 
        # deployment script, only the path to the module root is supported.
        $params = @{
            Path = $deploy.Source
            Repository = $target
            NuGetApiKey =  $deploy.DeploymentOptions.ApiKey
            Verbose = $VerbosePreference
        }

        Publish-Module @params
    }
}
