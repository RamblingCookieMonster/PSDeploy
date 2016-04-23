<#
    .SYNOPSIS
        Support deployments by handling simple tasks.

    .DESCRIPTION
        Support deployments by handling simple tasks.

        You can use a Task in two ways:

        As a scriptblock:

            By Task {
                "Run some deployment code in this scriptblock!"
            }

        As a script:

            By Task {
                FromSource "Path\To\SomeDeploymentScript.ps1"
            }

    .PARAMETER Deployment
        Deployment to process
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
        . "$($task.Source)" @param
    }
}