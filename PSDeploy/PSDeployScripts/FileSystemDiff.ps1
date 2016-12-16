<#
    .SYNOPSIS
        Deploy using Copy-Item for folder and file deployments checking for code differences

    .DESCRIPTION
        Deploy files using Copy-Item, but first check if the code in the destination file has changed
        since the last deployment.  

        Scenarios:
            1. File does not exist at destination:  Copy from code control.  Create a hash file.
            2. File exists at destination, but no hash file:  Copy from code control.  Create a hash file.
            3. File exists at destination, matching hash file: Copy from code control.  Create a new hash file.
            4. File exists at destination, hash file does not match: two scenario's here:
                a. SaveDiff not set: Show warning that destination file is different.  Overwrite from code control.  Create new hash file.
                b. SaveDiff set: Show warning. Rename destination file. Copy from code control. Create new hash file.

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER SaveDiff
        If a difference between the target file, and the target files saved hash is different that means
        the target file was changed outside of code control.  Use this option to save the file before overwriting
        it with the proper file from code control.
#>
[CmdletBinding()]
Param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [switch]$SaveDiff
)

Write-Verbose "Starting local deployment with $($Deployment.count) sources"

#Local Deployment. Duplicate code. Sigh.
ForEach ($Map in $Deployment)
{
    If ($Map.SourceExists)
    {
        If ($Map.SourceType -eq "Directory")
        {
            $Files = Get-ChildItem $Map.Source -Recurse -File
        }
        Else 
        {
            $Files = @(Get-ItemProperty $Map.Source)
        }
        ForEach ($File in $Files)
        {
            ForEach ($Target in $Map.Targets)
            {


                
                Write-Verbose "Deploying file '$($Map.Source)' to '$Target'"
                Copy-Item -Path $File.FullName -Destination $Target -Force
            }

            $HashFilePath = Join-Path -Path ($File.Directory) -ChildPath "$($File.BaseName).hash"
            If (Test-Path $HashFilePath)
            {
                $OldHash = Import-Clixml -Path $HashFilePath

            }
            Else
            {
                $Hash = [PSCustomObject]@{
                    Hash = Get-FileHash -Path $File.FullName | Select -ExpandProperty Hash
                    File = $null #Get-Content $File.FullName  #future proofing in case you want to see the difference
                }
                $Hash | Export-Clixml -Path $HashFilePath
            }

        }





        $Targets = $Map.Targets
        ForEach ($Target in $Targets)
        {
            If ($Map.SourceType -eq 'Directory')
            {
                $Files = Get-ChildItem $Target -File -Recurse
            }
            Else 

            {
                $Files = 
            }
            Else

            {
                $SourceHash = ( Get-Hash $Map.Source ).SHA256
                $TargetHash = ( Get-Hash $Target -ErrorAction SilentlyContinue -WarningAction SilentlyContinue ).SHA256
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
                Else

                {
                    Write-Verbose "Skipping deployment with matching hash: '$($Map.Source)' = '$Target')"
                }
            }
        }
    }
}