function Shadow-Copy($file, $shadowPath = "$($env:TEMP)\poweryaml\shadow") {

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
