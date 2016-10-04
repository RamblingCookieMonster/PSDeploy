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

        # How many times should it retry
        [Parameter(Mandatory=$false)]
        [int]
        $Retry = 2,

        # Output file for robocopy log
        [Parameter(Mandatory=$false)]
        [string]
        $OutputFile = '.\Robocopy.log',
        
        # Exit function if robocode throws "terminating" error code
        [Parameter(Mandatory=$false)]
        [switch]
        $EnableExit
    )

    # Remove trailing backslash
    $Path = $Path -replace '\\$'
    $Path = '"' + $Path + '"'
    $Destination = $Destination -replace '\\$'
    $Destination = '"' + $Destination + '"'

    # Add Retries to ArgumentList
    $ArgumentList += "/R:$Retry"

    # ROBOCOPY.exe $Path $Destination @ArgumentList
    Start-Process -FilePath ROBOCOPY.exe -ArgumentList "$Path $Destination $ArgumentList" -RedirectStandardOutput $OutputFile -NoNewWindow -Wait
    
    # Check Log File
    $RobocopyLog = Get-Content $OutputFile
    $RobocopyErrors = $RobocopyLog | Select-String -Pattern 'ERROR'
    if ($RobocopyErrors) {
        if ($EnableExit) {
            $host.SetShouldExit(1)
        } else {
            foreach ($RobocopyError in $RobocopyErrors) {
                Write-Error $RobocopyError
            }
        }
    } else {
        Write-Output $RobocopyLog
    }
}