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
    
    .PARAMETER IncludeOlder
        If specified and the source is a folder, we effectively call robocopy without /XO (Exclude Older Files)
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [switch]$Mirror,
    
    [switch]$IncludeOlder
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
                if($Map.DeploymentOptions.includeolder -eq 'True' -or $IncludeOlder)
                {
                    [string[]]$Arguments = "/E"
                } else {
                    [string[]]$Arguments = "/XO"
                    $Arguments += "/E"
                }
                if($Map.DeploymentOptions.mirror -eq 'True' -or $Mirror)
                {
                    [string[]]$Arguments = "/E"
                    $Arguments += "/PURGE"
                }
                # Resolve PSDrives.
                $Target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Target)

                Write-Verbose "Invoking ROBOCOPY.exe $($Map.Source) $Target $Arguments"
                Invoke-Robocopy -Path $Map.Source -Destination $Target -ArgumentList $Arguments
            }
            else
            {
                $SourceHash = ( Get-Hash $Map.Source ).SHA256;Write-Verbose "SourceHash: $SourceHash"
                $TargetHash = ( Get-Hash $Target -ErrorAction SilentlyContinue -WarningAction SilentlyContinue ).SHA256;Write-Verbose "TargetHash: $TargetHash"
                if($SourceHash -ne $TargetHash)
                {
                    Write-Verbose "Deploying file '$($Map.Source)' to '$Target'"
                    Try {
                        Copy-Item -Path $Map.Source -Destination $Target -Force
                    }
                    Catch [System.IO.IOException],[System.IO.DirectoryNotFoundException] {
                        $NewDir = $Target
                        if ($NewDir[-1] -ne '\')
                        {
                            $NewDir = Split-Path -Path $NewDir
                        }
                        $null = New-Item -ItemType Directory -Path $NewDir
                        Copy-Item -Path $Map.Source -Destination $Target -Force
                    }
                }
                else
                {
                    Write-Verbose "Skipping deployment with matching hash: '$($Map.Source)' = '$Target')"
                }
            }
        }
    }
}
