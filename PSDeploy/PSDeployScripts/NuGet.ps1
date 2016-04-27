<#
    .SYNOPSIS
        Deploys a module to a NuGet-based repository like the PowerShell Gallery.

    .DESCRIPTION
        Deploys a module to a NuGet-based repository like the PowerShell Gallery. Can also be used to deploy to a private
        instance of PowerShell Gallery or to a generic NuGet-based repository.

    .PARAMETER Deployment
        Deployment to run
        
    .PARAMETER ApiKey
        API Key used to authenticate to NuGet repository.
    
    .PARAMETER IconUri
        Specifies the URL of an icon for the module
   
    .PARAMETER LicenseUri
        Specifies the URL of licensing terms for the module you want to publish.    
    
    .PARAMETER ProjectUri
        Specifies the URL of a webpage about this project.
    
    .PARAMETER ReleaseNotes
        Specifies a string containing release notes or comments that you want to be available to users of this version of the module.
    
    .PARAMETER Version
        The exact version of a single module to publish.
        
    .PARAMETER Tags
        Adds one or more tags to the module that you are publishing.
#>
[cmdletbinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory)]
    [string]$ApiKey
    
    #[string]$IconUri,
    
    #[string]$LicenseUri,
    
    #[string]$ProjectUri,
    
    #[string]$ReleaseNotes,
        
    #[string]$RequiredVersion,
    
    #[string[]]$Tags
)

foreach($Deploy in $Deployment) {
    
    foreach($target in $Deploy.Targets) {
        Write-Verbose -Message "Starting deployment [$($Deploy.DeploymentName)] to NuGet reposotory [$Target]"
                       
        # Validate that $target has been setup as a valid PowerShell repository
        $validRepo = Get-PSRepository -Name $target -ErrorAction SilentlyContinue        
        if (-not $validRepo) {
            throw "$target has not been setup as a valid PowerShell repository."
        } 

        # Publish-Module params       
        $params = @{
            Repository = $target
            NuGetApiKey = $ApiKey
            Verbose = $true #<-- Testing
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
        
        # Add extra params if needed
        # if ($PSBoundParameters.ContainsKey('IconUri')) { $params.IconUri = $IconUri }
        # if ($PSBoundParameters.ContainsKey('LicenseUri')) { $params.LicenseUri = $LicenseUri }
        # if ($PSBoundParameters.ContainsKey('ProjectUri')) { $params.ProjectUri = $ProjectUri }
        # if ($PSBoundParameters.ContainsKey('ReleaseNotes')) { $params.ReleaseNotes = $ReleaseNotes }
        # if ($PSBoundParameters.ContainsKey('RequiredVersion')) { $params.RequiredVersion = $RequiredVersion }
        
        # The PowerShell Gallery doesn't seem to support tags with spaces in them.
        # Let's produce a warning if we find any of those                       
        # if ($PSBoundParameters.ContainsKey('Tags')) {
        #     foreach ($tag in $tags) {
        #        if ($tag -match '`s') {
        #           Write-Warning -Message 'Tags with spaces are not supported on the PowerShell Gallery. Please remove the spaces from tags.'
        #        }
        #     }
        # }

        Publish-Module @params
    }
}