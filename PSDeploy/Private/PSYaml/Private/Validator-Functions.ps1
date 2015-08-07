function Validate-yamlFile([string] $file) {
    
    Try
    {
        #Resolve relative paths... Thanks Oisin! http://stackoverflow.com/a/3040982/3067642
        $file = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($file)
    }
    Catch
    {
        Write-Error "Could not resolve path for '$file': $_"
        continue
    }

    $file_exists = Test-Path $file
    if (-not $file_exists) {
        "ERROR: '$file' does not exist" | Write-Error
        return $false 
    }

    $lines_in_file = [System.IO.File]::ReadAllLines($file)
    $line_tab_detected = Detect-Tab $lines_in_file

    if ($line_tab_detected -gt 0) {
        "ERROR in '$file'`nTAB detected on line $line_tab_detected" | Write-Error 
        return $false
    }

    $true
}

function Detect-Tab($lines) {
    for($i = 0; $i -lt $lines.count; $i++) {
        [string] $line = $lines[$i]
        if ($line.Contains("`t")) {
            return ($i + 1) 
        }
    }

    return 0
}
