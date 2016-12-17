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
            $Source = $Map.Source
        }
        Else 
        {
            $Files = @(Get-ItemProperty $Map.Source)
            $Source = Split-Path -Path $Map.Source
        }
        ForEach ($File in $Files)
        {
            ForEach ($Target in $Map.Targets)
            {
                #Checking for file differences from last deploy and file currently at target
                $OldFilePath = Join-Path -Path ($File.DirectoryName.ToLower().Replace($Source.ToLower(),$Target.ToLower())) -ChildPath $File.Name
                $OldHashPath = Join-Path -Path ($File.DirectoryName.ToLower().Replace($Source.ToLower(),$Target.ToLower())) -ChildPath "$($File.Name).hash"
                $OldFileParent = Split-Path -Path $OldFilePath

                If (-not (Test-Path $OldFileParent))
                {
                    $null = New-Item -Path $OldFileParent -ItemType Directory
                }
                ElseIf (Test-Path $OldHashPath)
                {
                    $OldHash = Import-Clixml -Path $OldHashPath
                    $NewHash = Get-FileHash -Path $OldFilePath
                    If ($OldHash.Hash -ne $NewHash.Hash)
                    {
                        Write-Warning "Difference was detected on target file $OldFilePath"
                        If ($SaveDiff)
                        {
                            $SaveDiffPath = Join-Path -Path (Split-Path -Path $OldFilePath) -ChildPath "$($File.BaseName)-$(Get-Date -Format 'MM-dd-yyyy-HH-mm-ss')$($File.Extension)"
                            Write-Verbose "Saving changed file as $SaveDiffPath"
                            Rename-Item -Path $OldFilePath -NewName $SaveDiffPath
                        }
                    }
                }

                #Deploying the file
                Write-Verbose "Deploying file '$($File.Name)' to '$Target'"
                $HashFilePath = Join-Path -Path (Split-Path -Path $OldFilePath) -ChildPath "$($File.Name).hash"
                Copy-Item -Path $File.FullName -Destination $OldFilePath -Force -Confirm:$false
                
                $Hash = [PSCustomObject]@{
                    Hash = Get-FileHash -Path $File.FullName | Select -ExpandProperty Hash
                    File = $null #Get-Content $File.FullName  #future proofing, not part of MVP
                }
                $Hash | Export-Clixml -Path $HashFilePath
            }
        }
    }
}

