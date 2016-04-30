<#
    .SYNOPSIS
        Deploys a module to a PowerShell repository like the PowerShell Gallery.

    .DESCRIPTION
        Deploys a module to a PowerShell-based repository like the PowerShell Gallery. Can also be used to deploy to a private
        instance of PowerShell Gallery.

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

foreach($Deploy in $Deployment) {
    
    foreach($target in $Deploy.Targets) {
        Write-Verbose -Message "Starting deployment [$($Deploy.DeploymentName)] to PowerShell reposotory [$Target]"
                       
        # Validate that $target has been setup as a valid PowerShell repository
        $validRepo = Get-PSRepository -Name $target -ErrorAction SilentlyContinue        
        if (-not $validRepo) {
            throw "$target has not been setup as a valid PowerShell repository."
        } 

        # Publish-Module params       
        $params = @{
            Repository = $target
            NuGetApiKey = $ApiKey
            Verbose = $VerbosePreference
        }        
        
        # The source could be a path to a module or just the name of a module.
        # In the case of a name, Publish-Module will search for the module in $env:PSModulePath
        # and will use the first one it finds. This may not me what you want. You may be better
        # off specifying an explicit path or combine the module name with a version number.
        if (Test-Path -Path $Deploy.Source) {        
            $params.Path = $Deploy.Source
        } else {
            $params.Name = $Deploy.Source
        }
        
        Publish-Module @params
    }
}