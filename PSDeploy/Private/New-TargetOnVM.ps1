    Function New-Target {
        param($Target, $Session)
        $null = Invoke-Command -Session $session -ScriptBlock {
            New-Item -Path $Using:Target -ItemType Directory -Force
        }
    }