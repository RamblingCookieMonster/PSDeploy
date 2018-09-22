function Shadow-Copy($file, $shadowPath = (Join-Path -Path (Get-TempPath) -ChildPath 'poweryaml\shadow')) {

    if(!(Test-Path -Path Variable:\IsWindows) -or $IsWindows) {
        if (-not (Test-Path $shadowPath ) ) {
            New-Item $shadowPath -ItemType directory | Out-Null
        }

        try {
            Copy-Item $file $shadowPath -Force -ErrorAction SilentlyContinue
        } catch {
            "Attempted to write over locked file, continuing..." | Write-Debug
        }
        $fileName = (Get-Item $file).Name
        "$shadowPath\$fileName"
    }
    else {
        $file
    }
}
