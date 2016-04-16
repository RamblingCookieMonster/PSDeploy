<#
    .SYNOPSIS
        Execute scripts described in psdeploy files

    .DESCRIPTION
        Support deployments by handling simple tasks.

    .PARAMETER Deployment
        Name for the work that will be performed.
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment
)

Write-Verbose "Executing $($Deployment.count) tasks"

foreach($task in $Deployment)
{
    if($task.SourceExists)
    {
        $param = $task.DeploymentOptions
        & "$($task.Source)" @param
    }
}