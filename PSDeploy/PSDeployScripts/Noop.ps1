<#
    .SYNOPSIS
        Display variables that a deployment script would receive.

        Used for testing and validation.

    .DESCRIPTION
        Display variables that a deployment script would receive.

        Used for testing and validation.

    .PARAMETER Deployment
        Deployment to process

    .PARAMETER StringParameter
        An example parameter that does nothing
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [string[]]$StringParameter
)

Write-Verbose "Starting noop run with $($Deployment.count) sources"

[pscustomobject]@{
    PSBoundParameters = $PSBoundParameters
    Deployment = $Deployment
    GetVariable = (Get-Variable)
    ENV = Get-Childitem ENV:
}