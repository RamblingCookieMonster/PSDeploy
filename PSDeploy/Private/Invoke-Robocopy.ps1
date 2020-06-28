<#
.Synopsis
    Wrapper function for robocopy.exe

.Parameter Path
    String. Source path. You can use relative path.

.Parameter Destination
    Array of destination paths. You can use relative paths.

.Parameter ArgumentList
    Array of additional arguments for robocopy.exe

.Parameter Retry
    Integer. Number of retires. Default is 2.

.Parameter EnableExit
    Switch. Exit function if Robocopy throws "terminating" error code.

.Parameter PassThru
    Switch. Returns an object with the following properties:

    StdOut - array of strings captured from StandardOutput 
    StdErr - array of strings captured from StandardError 
    ExitCode - Enum with Robocopy exit code in human-readable format
    
    By default, this function doesn't generate any output.

.Link
    https://technet.microsoft.com/en-us/library/cc733145.aspx

.Link
    http://ss64.com/nt/robocopy.html

.Link
    http://ss64.com/nt/robocopy-exit.html

.Example
    'c:\bravo', 'c:\charlie' | Invoke-Robocopy -Path 'c:\alpha' -ArgumentList @('/xo', '/e' )

    Copy 'c:\alpha' to 'c:\bravo' and 'c:\charlie'. Copy subdirectories, include empty directories, exclude older files.
#>
function Invoke-Robocopy
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Destination,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$ArgumentList,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$Retry = 2,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]$EnableExit,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]$PassThru
    )

    Begin
    {
        # https://learn-powershell.net/2016/03/07/building-a-enum-that-supports-bit-fields-in-powershell/
        function New-RobocopyHelper
        {
            $TypeName = 'Robocopy.ExitCode'

            # http://stackoverflow.com/questions/16552801/how-do-i-conditionally-add-a-class-with-add-type-typedefinition-if-it-isnt-add
            if (! ([System.Management.Automation.PSTypeName]$TypeName).Type) {
                try {
                    #region Module Builder
                    $Domain = [System.AppDomain]::CurrentDomain
                    $DynAssembly = New-Object -TypeName System.Reflection.AssemblyName($TypeName)
                    $AssemblyBuilder = [System.Reflection.Emit.AssemblyBuilder]::DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run) # Only run in memory
                    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule($TypeName, $false)
                    #endregion Module Builder

                    # https://pshirwin.wordpress.com/2016/03/18/robocopy-exitcodes-the-powershell-way/
                    #region Enum
                    $EnumBuilder = $ModuleBuilder.DefineEnum($TypeName, 'Public', [int32])
                    [void]$EnumBuilder.DefineLiteral('NoChange', [int32]0x00000000)
                    [void]$EnumBuilder.DefineLiteral('OKCopy', [int32]0x00000001)
                    [void]$EnumBuilder.DefineLiteral('ExtraFiles', [int32]0x00000002)
                    [void]$EnumBuilder.DefineLiteral('MismatchedFilesFolders', [int32]0x00000004)
                    [void]$EnumBuilder.DefineLiteral('FailedCopyAttempts', [int32]0x00000008)
                    [void]$EnumBuilder.DefineLiteral('FatalError', [int32]0x000000010)
                    $EnumBuilder.SetCustomAttribute(
                        [FlagsAttribute].GetConstructor([Type]::EmptyTypes),
                        @()
                    )
                    [void]$EnumBuilder.CreateType()
                    #endregion Enum
                } catch {
                    throw $_
                }
            }
        }

        New-RobocopyHelper
    }

    Process
    {
        foreach ($item in $Destination) {
            # Resolve destination paths, remove trailing backslash, add Retries and combine all arguments into one array
            $AllArguments = @(
                (Resolve-Path -Path $Path).ProviderPath -replace '\\+$'
            ) + (
                $item | ForEach-Object {
                    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_) -replace '\\+$'
                }
            ) + $ArgumentList + "/R:$Retry"

            # Invoke Robocopy
            $Result = Start-ConsoleProcess -FilePath 'robocopy.exe' -ArgumentList $AllArguments
            $Result.ExitCode = [Robocopy.ExitCode]$Result.ExitCode
    
            # Dump Robocopy log to Verbose stream
            $Result.StdOut | Write-Verbose

            # Process Robocopy exit code
            # http://latkin.org/blog/2012/07/08/using-enums-in-powershell/
            if ($Result.ExitCode -band [Robocopy.ExitCode]'FailedCopyAttempts, FatalError') {
                if ($EnableExit) {
                    $host.SetShouldExit(1)
                } else {
                    $ErrorMessage =  @($Result.ExitCode) + (
                        # Try to provide additional info about error.
                        # WARNING: This WILL fail in localized Windows. E.g., "Œÿ»¡ ¿" in Russian.
                        $Result.StdOut | Select-String -Pattern '\s*ERROR\s+:\s+(.+)' | ForEach-Object {
                            $_.Matches.Groups[1].Value
                        }
                    )

                    $ErrorMessage -join [System.Environment]::NewLine | Write-Error
                }
            } else {
                # Passthru Robocopy result
                if ($PassThru) {
                    $Result
                }
            }
        }
    }
}