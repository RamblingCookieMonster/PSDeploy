function Invoke-Robocopy () {
    [cmdletbinding()]
    param (
        # Copy from location
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        # Copy to location
        [Parameter(Mandatory=$true)]
        $Destination,

        # List of arguments to be splatted to ROBOCOPY
        [Parameter(Mandatory=$true)]
        [array]
        $ArgumentList
    )

    ROBOCOPY.exe $Path $Destination @ArgumentList

    switch ($LastExitCode) {
        0   { Write-Output 'No files copied. Source and destination are in sync' }
        1   { Write-Output 'Files were copied successfully'}
        2   { Write-Output 'Extra files/directories detected. Housekeeping may be required.'}
        4   { Write-Output 'Mismatched files/directories detected. Housekeeping may be required.'}
        8   { Write-Error 'Some files/directories could not be copied'}
        10  { Write-Error 'Usage error or an error due to insufficient access privileges'}
    }

    exit ($LastExitCode -band 24)
}