    Function Test-Target {
        param(
            $Target,
            $Session
        )
        Invoke-Command -Session $Session -ScriptBlock {
            Test-Path -Path $using:Target -PathType Container
        }
    }