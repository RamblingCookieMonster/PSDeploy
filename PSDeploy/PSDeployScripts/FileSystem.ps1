<#
    .SYNOPSIS
        Deploy using Robocopy or Copy-Item for folder and file deployments, respectively.

    .DESCRIPTION
        Deploy using Robocopy or Copy-Item for folder and file deployments, respectively.

        Runs in the current session (i.e. as the current user)

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER Mirror
        If specified and the source is a folder, we effectively call robocopy /MIR (Can remove folders/files...)
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [switch]$Mirror
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
                if($Map.DeploymentOptions.mirror -eq 'True' -or $Mirror)
                {
                    $Arguments += "/PURGE"
                }
                Write-Verbose "Invoking ROBOCOPY.exe $($Map.Source) $Target $Arguments"
                ROBOCOPY.exe $Map.Source $Target @Arguments
            }
            else
            {
                $SourceHash = Get-Hash $Map.Source
                $TargetHash = Get-Hash $Target -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if($SourceHash -ne $TargetHash)
                {
                    Write-Verbose "Deploying file '$($Map.Source)' to '$Target'"
                    Copy-Item -Path $Map.Source -Destination $Target -Force
                }
                else
                {
                    Write-Verbose "Skipping deployment with matching hash: '$($Map.Source)' = '$Target')"
                }
            }
        }
    }
}