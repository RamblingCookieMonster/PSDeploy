<#
    .SYNOPSIS
        Deploys a script to a PowerShell repository like the PowerShell Gallery.

    .DESCRIPTION
        Deploys a script to a PowerShell repository like the PowerShell Gallery.

        This only supports publishing items that do not already have a PSScriptInfo header.
        We might support this down the line when Update-ScriptFileInfo is fixed.

        Notes on how we define the PSScriptInfo header based on your WithOptions parameters and other info:
           * If you specify a WithOptions parameter, that takes precedence over an existing publication
           * If you do not specify a WithOptions parameter and have previously published this,
             we query and re-use data from the existing published script
           * In a few special cases (required fields), we will generate initial data if you
             do not include it in WithOptions or have an existing published script:
                 GUID - We create a new GUID
                 VERSION - we set to 1.0.0
                 AUTHOR - We set to Unknown
                 DESCRIPTION - We set to the file name (e.g. if I publish Open-IseFunction.ps1, DESCRIPTION=Open-ISEFunction)

    .PARAMETER Deployment
        Deployment to run

        Source is the path of the module to deploy.
        Target is a valid PSRepository name. Defaults to PSGallery

    .PARAMETER ApiKey
        API Key used to authenticate to PowerShell repository.
    
    .PARAMETER VERSION
        VERSION for script info
        
        We set to 1.0.0 if you don't include it here or in a previously published version

        Note that you need to bump this for a successful publish, you can't overwrite an existing version

    .PARAMETER GUID
        GUID for script info

        We create a new one if you don't include it here or in a previously published version

    .PARAMETER AUTHOR
        AUTHOR for script info

        We set to unknown if you don't include it here or in a previously published version

    .PARAMETER DESCRIPTION
        DESCRIPTION for script info

        We set to the basename of your script if you don't include it here or in a previously published version

    .PARAMETER COMPANYNAME
        COMPANYNAME for script info

    .PARAMETER COPYRIGHT
        COPYRIGHT for script info

    .PARAMETER TAGS
        TAGS for script info

    .PARAMETER LICENSEURI
        LICENSEURI for script info

    .PARAMETER PROJECTURI
        PROJECTURI for script info

    .PARAMETER ICONURI
        ICONURI for script info

    .PARAMETER EXTERNALMODULEDEPENDENCIES
        EXTERNALMODULEDEPENDENCIES for script info

    .PARAMETER REQUIREDSCRIPTS
        REQUIREDSCRIPTS for script info

    .PARAMETER EXTERNALSCRIPTDEPENDENCIES
        EXTERNALSCRIPTDEPENDENCIES for script info

    .PARAMETER RELEASENOTES
        RELEASENOTES for script info
#>
[cmdletbinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory)]
    [string]$ApiKey
)

# We make the assumption that WithOptions may be updated by the user or build process. It takes precedence.
function Pick-Precedence {
    [cmdletbinding()]
    param(
        $Name,
        $PSGalleryOutput = $Existing
    )

    $WithOptionsValue = $null
    $WithOptionsValue = $Deploy.DeploymentOptions.$Name
    $ExistingValue = $null
    $ExistingValue = $PSGalleryOutput.$Name
    if($WithOptionsValue)
    {
        $WithOptionsValue
    }
    else
    {
        $ExistingValue
    }
}

foreach($deploy in $Deployment) {
    if(-not $deploy.Targets)
    {
        #Default to the PSGallery
        $deploy.Targets = @('PSGallery')
    }
    foreach($target in $deploy.Targets) {
        Write-Verbose -Message "Starting deployment [$($deploy.DeploymentName)] to PowerShell repository [$Target]"

        # Validate that $target has been setup as a valid PowerShell repository
        $validRepo = Get-PSRepository -Name $target -Verbose:$false -ErrorAction SilentlyContinue
        if (-not $validRepo) {
            throw "[$target] has not been setup as a valid PowerShell repository."
        }

        # Check gallery for existing. We don't want a new GUID every time...
        $Name = ( Get-Item $Deploy.source -ErrorAction Stop ).BaseName
        $Existing = $null
        $Existing = @( Find-Script -Name $Name -Repository $Target )
        if ($Existing.Count -gt 1)
        {
            Write-Error "We found more than one script matching $Name.  Did you include a wildcard?"
            continue
        }
        elseif($Existing.Count -eq 1)
        {
            # guid is in the additionalmetadata hash
            $Existing[0] | Add-Member -MemberType NoteProperty -Name GUID -Value $Existing.AdditionalMetadata['GUID']
        }

        # Extract deployment options / header values. Not all of these are props.
        $AllNodes = echo VERSION GUID AUTHOR COMPANYNAME COPYRIGHT,
                         TAGS LICENSEURI PROJECTURI ICONURI,
                         EXTERNALMODULEDEPENDENCIES, REQUIREDSCRIPTS,
                         EXTERNALSCRIPTDEPENDENCIES, RELEASENOTES, DESCRIPTION

        foreach($item in $AllNodes)
        {
            $value = $null
            $value = Pick-Precedence -Name $Item -PSGalleryOutput $Existing
            Set-Variable -Name $Item -Value $value
        }

        # Items that might be blank on new scripts, that we need filled out
        if(-not $GUID)
        {
            $GUID = [GUID]::NewGuid().Guid
        }
        if(-not $VERSION)
        {
            $VERSION = '1.0.0'
        }
        if(-not $AUTHOR)
        {
            $AUTHOR = 'Unknown'
        }
        if(-NOT $DESCRIPTION)
        {
            $DESCRIPTION = $Name
        }

        # Build up the header
        $Header = "<#PSScriptInfo`r`n"
        $Nodes = echo VERSION GUID AUTHOR DESCRIPTION COMPANYNAME COPYRIGHT TAGS LICENSEURI PROJECTURI,
             ICONURI EXTERNALMODULEDEPENDENCIES REQUIREDSCRIPTS EXTERNALSCRIPTDEPENDENCIES RELEASENOTES
      
        foreach($item in $Nodes)
        {
            $Value = $null
            If($Value = Get-Variable -Name $item -ValueOnly -ErrorAction SilentlyContinue)
            {
                $header += ".$item`r`n    $Value`r`n"
            }
        }

        $header += "#>`r`n"

        # Write the header, publish
        $SourceContent = Get-Content $Deploy.Source -Raw
        Set-Content $Deploy.Source -Value "$Header$SourceContent" -Force

        # Start building params
        $Params = @{
            Path = $Deploy.Source
            Repository = $Target
            NugetApiKey = $Deploy.DeploymentOptions.ApiKey
            Verbose = $VerbosePreference
        }

        Publish-Script @params
    }
}
