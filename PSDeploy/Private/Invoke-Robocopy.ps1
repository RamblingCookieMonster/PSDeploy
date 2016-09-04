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
        [Parameter(Mandatory=$false)]
        [array]
        $ArgumentList,
        
        # Exit function if robocode throws "terminating" error code
        [Parameter(Mandatory=$false)]
        [switch]
        $EnableExit
    )

    # Remove trailing backslash
    $Path = $Path -replace '\\$'
    $Destination = $Destination -replace '\\$'

    ROBOCOPY.exe $Path $Destination @ArgumentList

    switch ($LastExitCode) {
        0   { Write-Output 'No files copied. Source and destination are in sync' }
        1   { Write-Output 'Files were copied successfully'}
        2   { Write-Warning 'Extra files/directories detected. Housekeeping may be required.'}
        4   { Write-Warning 'Mismatched files/directories detected. Housekeeping may be required.'}
        8   { $RCError = 'Some files/directories could not be copied'}
        10  { $RCError = 'Usage error or an error due to insufficient access privileges'}
        16  { $RCError = 'No destination directory specified'}
    }

    if ($LastExitCode -gt 4) {
        if ($EnableExit) {
            $host.SetShouldExit($LastExitCode)
        } else {
            Write-Error $RCError
        }
    }
}