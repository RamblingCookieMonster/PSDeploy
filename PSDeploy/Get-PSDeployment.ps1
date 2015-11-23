﻿Function Get-PSDeployment {
    <#
    .SYNOPSIS
        Read a Deployment.yml file

    .DESCRIPTION
        Read a Deployment.yml file

        The resulting object contains these properties
            DeploymentSource  = Path to the deployment.yml
            DeploymentName    = Deployment name
            DeploymentAuthor  = Optional deployment author
            DeploymentType    = Type of deployment, must be defined in PSDeploy.yml
            DeploymentOptions = Options for this deploymenttype
            Source            = Path to source from the local machine
            SourceType        = Directory or file
            SourceExists      = Whether we can test path against the local source
            Targets           = One or more targets to deploy to.
            Raw               = Raw definition for this deployment, feel free to go wild.

        This is oriented around deployments from a Windows system.

        It's a poor schema that grew from a single use case.
        Included 'Raw', allowing you to do whatever you want : )

    .PARAMETER Path
        Path to deployment.yml to parse

    .PARAMETER DeploymentRoot
        Assumed root of the deployment.yml for relative paths. Default is the parent of deployment.yml

    .EXAMPLE
        Get-PSDeployment C:\Git\Module1\Deployments.yml

        # Get deployments from a yml file

    .EXAMPLE
        Get-PSDeployment -Path C:\Git\Module1\Deployments.yml, C:\Git\Module2\Deployments.yml |
            Invoke-PSDeployment -Force

        # Get deployments from two files, invoke deployment for all

    .LINK
        about_PSDeploy

    .LINK
        https://github.com/RamblingCookieMonster/PSDeploy

    .LINK
        Invoke-PSDeployment

    .LINK
        Get-PSDeploymentType

    .LINK
        Get-PSDeploymentScript

    #>
    [cmdletbinding(DefaultParameterSetName='Local')]
    Param(
        [validatescript({Test-Path -Path $_ -PathType Leaf -ErrorAction Stop})]
        [parameter(Mandatory = $True)]       
        [string[]]$Path,

        [string]$DeploymentRoot
    )

    #Resolve relative paths... Thanks Oisin! http://stackoverflow.com/a/3040982/3067642
    if($PSBoundParameters.ContainsKey('DeploymentRoot'))
    {
        $DeploymentRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DeploymentRoot)
    }

    # This parses a deployment YML
    foreach($DeploymentFile in $Path)
    {
        #Resolve relative paths... Thanks Oisin! http://stackoverflow.com/a/3040982/3067642
        $DeploymentFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DeploymentFile)

        if(-not $DeploymentRoot)
        {
            $DeploymentRoot = Split-Path $DeploymentFile -parent
        }

        if(-not (Test-Path $DeploymentRoot -PathType Container))
        {
            Write-Error "Skipping '$DeploymentFile', could not validate DeploymentRoot '$DeploymentRoot'"
        }

        $Deployments = Import-Yaml -Fullname $DeploymentFile
    
        $DeploymentMap = foreach($DeploymentName in $($Deployments | Get-Member -MemberType NoteProperty | select -ExpandProperty Name))
        {
            $DeploymentObject = $Deployments.$DeploymentName
            $Author = $DeploymentObject.Author
            $DeploymentType = $DeploymentObject.DeploymentType
            $Options = $DeploymentObject.Options
            
            $Sources = @($DeploymentObject.Source)
            $Destinations = @($DeploymentObject.Destination)
    
            foreach($Source in $Sources)
            {
                
                #Determine the path to this source. Try absolute, fall back on relative
                if(Test-Path $Source -ErrorAction SilentlyContinue)
                {
                    $LocalSource = ( Resolve-Path $Source ).Path
                }
                else
                {
                    $LocalSource = Join-Path $DeploymentRoot $Source
                }

                $Exists = Test-Path $LocalSource
                if($Exists)
                {
                    $Item = Get-Item $LocalSource
                    if($Item.PSIsContainer)
                    {
                        $Type = 'Directory'
                    }
                    else
                    {
                        $Type = 'File'
                    }
                }

                [pscustomobject]@{
                    DeploymentFile = $DeploymentFile
                    DeploymentName = $DeploymentName
                    DeploymentAuthor = $Author
                    DeploymentType = $DeploymentType
                    DeploymentOptions = $Options
                    Source = $LocalSource
                    SourceType = $Type
                    SourceExists = $Exists
                    Targets = $Destinations
                    Raw = $DeploymentHash
                } 
            }
        }
    
        if( @($DeploymentMap.SourceExists) -contains $false)
        {
            Write-Error "Nonexistent Paths:`n`n$($DeploymentMap | Where {-not $_.SourceExists} | Format-List | Out-String)`n"
        }
    
        $DeploymentMap | Add-ObjectDetail -TypeName 'PSDeploy.Deployment'
    }
}