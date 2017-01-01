<#
.Synopsis
    Launch console process, pipe strings to its StandardInput
    and get resulting StandardOutput/StandardError streams and exit code.

.Description
    This function will start console executable, pipe any user-specified strings to it
    and capture StandardOutput/StandardError streams and exit code.
    It returns object with following properties:

    StdOut - array of strings captured from StandardOutput 
    StdErr - array of strings captured from StandardError 
    ExitCode - exit code set by executable

.Parameter FilePath
    Path to the executable or its name.

.Parameter ArgumentList
    Array of arguments for the executable.
    Passing arguments as an array allows to run even such unfriendly applications as robocopy.

.Parameter InputObject
    Array of strings to be piped to the executable's StandardInput.
    This allows you to execute commands in interactive sessions of netsh and diskpart.

.Example
    Start-ConsoleProcess -FilePath find

    Start find.exe and capture its output.
    Because no arguments specified, find.exe prints error to StandardError stream,
    which is captured by the function:

    StdOut StdErr                               ExitCode
    ------ ------                               --------
    {}     {FIND: Parameter format not correct}        2

.Example
    'aaa', 'bbb', 'ccc' | Start-ConsoleProcess -FilePath find -ArgumentList '"aaa"'

    Start find.exe, pipe strings to its StandardInput and capture its output.
    Find.exe will attempt to find string "aaa" in StandardInput stream and
    print matches to StandardOutput stream, which is captured by the function:

    StdOut StdErr ExitCode
    ------ ------ --------
    {aaa}  {}            0

.Example
    'list disk', 'list volume' | Start-ConsoleProcess -FilePath diskpart

    Start diskpart.exe, pipe string to its StandardInput and capture its output.
    Diskpart.exe will accept piped strings as if they were typed in the interactive session
    and list all disks and volumes on the PC.

    Note that running diskpart requires already elevated PowerShell console.
    Otherwise, you will recieve elevation request and diskpart will run,
    however, no strings would be piped to it.

    Example:

    PS > $Result = 'list disk', 'list volume' | Start-ConsoleProcess -FilePath diskpart
    PS > $Result.StdOut

    Microsoft DiskPart version 6.3.9600

    Copyright (C) 1999-2013 Microsoft Corporation.
    On computer: HAL9000

    DISKPART> 
      Disk ###  Status         Size     Free     Dyn  Gpt
      --------  -------------  -------  -------  ---  ---
      Disk 0    Online          298 GB      0 B         

    DISKPART> 
      Volume ###  Ltr  Label        Fs     Type        Size     Status     Info
      ----------  ---  -----------  -----  ----------  -------  ---------  --------
      Volume 0     E                       DVD-ROM         0 B  No Media           
      Volume 1     C   System       NTFS   Partition    100 GB  Healthy    System  
      Volume 2     D   Storage      NTFS   Partition    198 GB  Healthy            

    DISKPART> 

.Example
    Start-ConsoleProcess -FilePath robocopy -ArgumentList 'C:\Src', 'C:\Dst', '/mir'

    Start robocopy.exe with arguments and capture its output.
    Robocopy.exe will mirror contents of the 'C:\Src' folder to 'C:\Dst'
    and print log to StandardOutput stream, which is captured by the function.

    Example:

    PS > $Result = Start-ConsoleProcess -FilePath robocopy -ArgumentList 'C:\Src', 'C:\Dst', '/mir'
    PS > $Result.StdOut

    -------------------------------------------------------------------------------
       ROBOCOPY     ::     Robust File Copy for Windows                              
    -------------------------------------------------------------------------------

      Started : 01 January 2016 y. 00:00:01
       Source : C:\Src\
         Dest : C:\Dst\

        Files : *.*
	    
      Options : *.* /S /E /DCOPY:DA /COPY:DAT /PURGE /MIR /R:1000000 /W:30 

    ------------------------------------------------------------------------------

	                       1	C:\Src\
	        New File  		       6	Readme.txt
      0%  
    100%  

    ------------------------------------------------------------------------------

                   Total    Copied   Skipped  Mismatch    FAILED    Extras
        Dirs :         1         0         0         0         0         0
       Files :         1         1         0         0         0         0
       Bytes :         6         6         0         0         0         0
       Times :   0:00:00   0:00:00                       0:00:00   0:00:00


       Speed :                 103 Bytes/sec.
       Speed :               0.005 MegaBytes/min.
       Ended : 01 January 2016 y. 00:00:01
#>
function Start-ConsoleProcess
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [string[]]$ArgumentList,

        [Parameter(ValueFromPipeline = $true)]
        [string[]]$InputObject
    )

    End
    {
        if($Input)
        {
            # Collect all pipeline input
            # http://www.powertheshell.com/input_psv3/
            $StdIn = @($Input)
        }
        else
        {
            $StdIn = $InputObject
        }

        try
        {
            "Starting process: $FilePath", "Redirect StdIn: $([bool]$StdIn.Count)", "Arguments: $ArgumentList" | Write-Verbose

            if($StdIn.Count)
            {
                $Output = $StdIn | & $FilePath $ArgumentList 2>&1
            }
            else
            {
                $Output = & $FilePath $ArgumentList 2>&1
            }
        }
        catch
        {
            throw $_
        }

        Write-Verbose 'Finished, processing output'

        $StdOut = New-Object -TypeName System.Collections.Generic.List``1[String]
        $StdErr = New-Object -TypeName System.Collections.Generic.List``1[String]

        foreach($item in $Output)
        {
            # Data from StdOut will be strings, while StdErr produces
            # System.Management.Automation.ErrorRecord objects.
            # http://stackoverflow.com/a/33002914/4424236
            if($item.Exception.Message)
            {
                $StdErr.Add($item.Exception.Message)
            }
            else
            {
                $StdOut.Add($item)
            }
        }

        Write-Verbose 'Returning result'
        New-Object -TypeName PSCustomObject -Property @{
            ExitCode = $LASTEXITCODE
            StdOut = $StdOut.ToArray()
            StdErr = $StdErr.ToArray()
        } | Select-Object -Property StdOut, StdErr, ExitCode
    }
}