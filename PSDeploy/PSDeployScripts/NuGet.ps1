<#
    .SYNOPSIS
        Deploys a module to a NuGet-based repository like the PowerShell Gallery.

    .DESCRIPTION
        Deploys a module to a NuGet-based repository like the PowerShell Gallery. Can also be used to deploy to a private
        instance of PowerShell Gallery or to a generic NuGet-based repository.

    .PARAMETER Deployment
        Deployment to run
        
    .PARAMETER ApiKey
    
    .PARAMETER IconUri
   
    .PARAMETER LicenseUri
    
    .PARAMETER Name
    
    .PARAMETER ProjectUri
    
    .PARAMETER ReleaseNotes
    
    .PARAMETER Version
    
    .PARAMETER Tags
#>
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory)]
    [securestring]$ApiKey,
    
    [string]$IconUri,
    
    [string]$LicenseUri,
    
    [string]$Name,
    
    [string]$ProjectUri,
    
    [string]$ReleaseNotes,
    
    [string]$Version,
    
    [hashtable]$Tags
)

foreach($Deploy in $Deployment) {
    
    
}