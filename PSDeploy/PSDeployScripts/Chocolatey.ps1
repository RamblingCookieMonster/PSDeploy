<#
    .SYNOPSIS
        Deploys a package to a Chocolatey repository.

    .DESCRIPTION
        Deploys a Chocolatey package to a nuget-based repository like the Chocolatey Gallery. Can also be used to deploy to a private
        instance of Chocolatey simple server or to any nuget-based repository.

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER ApiKey
        API Key used to authenticate to Chocolatey repository.

    .PARAMETER Source
        The source we are pushing the package to. Use https://chocolatey.org/ to push to [community feed](https://chocolatey.org/packages).

    .PARAMETER Force
        Force the behavior. Do not use force during normal operation - it subverts some of the smart behavior for commands.

    .PARAMETER TimeOut
        CommandExecutionTimeout (in seconds) - The time to allow a command to finish before timing out. Overrides the default execution timeout in the configuration of 2700 seconds.


#>
[cmdletbinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory)]
    [string]$ApiKey,

    [switch]$Force,

    [int]$TimeOut
)

foreach($Deploy in $Deployment)
{
    # Getting the path to the Chocolatey executable from the environment variable Chocolatey sets.
    # If this variable doesn't exist, then Chocolatey may not be installed or is an older version.
    if($null -eq $env:ChocolateyInstall)
    {
        Throw "Chocolatey either isn't installed or an older version is being used. Can't find ChocolateyInstall environment variable."
    }
    $ChocolateyPath = $env:ChocolateyInstall + "\choco.exe"

    foreach($target in $deploy.Targets)
    {
        Write-Verbose -Message "Starting deployment [$($deploy.DeploymentName)] to Chocolatey repository [$Target]"

        if([string]::IsNullOrEmpty($ApiKey) -and [string]::IsNullOrEmpty($deploy.DeploymentOptions.ApiKey))
        {
            Throw "An API key is required."
        }
        elseif($ApiKey -eq $null)
        {
            $ApiKey = $deploy.DeploymentOptions.ApiKey
        }

        # If a directory is passed in, iterate through directory pushing each nupkg
        if($Deploy.SourceType -eq 'Directory')
        {
            [string[]]$ChocolateyArguments = (Get-ChildItem -Path $deploy.Source  -Filter *.nupkg).FullName
        }
        else
        {
            [string[]]$ChocolateyArguments = $deploy.Source
        }

        foreach($ChocolateyPackage in $ChocolateyArguments)
        {
            $ChocolateyPackage += " --source='$target' "
            $ChocolateyPackage += " --api-key='$ApiKey' "

            if( $PSBoundParameters.ContainsKey('Force') )
            {
                $ChocolateyPackage += " --force "
            }

            if( $PSBoundParameters.ContainsKey('TimeOut') )
            {
                $ChocolateyPackage += " -t=$timeout "
            }

            Write-Verbose "Invoking Chocolatey Push."
            Write-Verbose "Chocolatey Path: $ChocolateyPath"
            Write-Verbose "Chocolatey Params are: $ChocolateyPackage "
            Write-Verbose "String executed: $ChocolateyPath push $ChocolateyPackage"
            Invoke-expression "$ChocolateyPath push $ChocolateyPackage"
        }

    }
}
