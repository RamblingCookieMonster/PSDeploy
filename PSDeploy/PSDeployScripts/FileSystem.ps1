<#
    .SYNOPSIS
        Deploy using Robocopy or Copy-Item for folder and file deployments, respectively.

    .DESCRIPTION
        Deploy using Robocopy or Copy-Item for folder and file deployments, respectively.

        Runs in the current session (i.e. as the current user)

    .PARAMETER Deployment
        Deployment to run
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment
)

Write-Verbose "Starting local deployment with $($Deployment.count) sources"

#Local Deployment. Duplicate code. Sigh.
foreach($Map in $Deployment)
{
    if($Map.SourceExists)
    {
        $Targets = $Map.Targets
        foreach($Target in $Targets)
        {
            if($Map.SourceType -eq 'Directory')
            {
                [string[]]$Arguments = "/XO"
                $Arguments += "/E"
                if($Map.Mirror -eq 'True')
                {
                    $Arguments += "/PURGE"
                }
                Write-Verbose "Invoking ROBOCOPY.exe $($Map.RemoteSource) $Target $Arguments"
                ROBOCOPY.exe $Map.RemoteSource $Target @Arguments
            }       
            else
            {
                $SourceHash = Get-Hash $Map.LocalSource
                $TargetHash = Get-Hash $Target -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if($SourceHash -ne $TargetHash)
                {
                    Write-Verbose "Deploying file '$($Map.LocalSource)' to '$Target'"
                    Copy-Item -Path $Map.RemoteSource -Destination $Target -Force
                }
                else
                {
                    Write-Verbose "Skipping deployment with matching hash: '$($Map.RemoteSource)' = '$Target')"
                }
            }
        }
    }
}