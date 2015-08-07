#handle PS2
    $ModernPS = $PSVersionTable.PSVersion -ge '3.0'
    if(-not $ModernPS)
    {
        $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    }

#Get public and private function definition files.
    $Public  = @( Get-ChildItem $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue )
    $Private = @( Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Try
        {
            #PS2 compatibility
            if($import.fullname)
            {
                . $import.fullname
            }
        }
        Catch
        {
            Write-Error "Failed to import function $($import.fullname)"
        }
    }

Load-YamlDotNetLibraries (Join-Path $PSScriptRoot -ChildPath "Lib")

Export-ModuleMember -Function ConvertFrom-Yaml 
