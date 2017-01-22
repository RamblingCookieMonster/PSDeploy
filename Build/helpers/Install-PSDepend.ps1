    <#
    .SYNOPSIS
        Bootstrap PSDepend

    .DESCRIPTION
        Bootstrap PSDepend

        Why? No reliance on PowerShellGallery

          * Downloads nuget to your ~\ home directory
          * Creates $Path (and full path to it)
          * Downloads module to $Path\PSDepend
          * Moves nuget.exe to $Path\PSDepend (skips nuget bootstrap on initial PSDepend import)

    .PARAMETER Path
        Module path to install PSDepend

        Defaults to Profile\Documents\WindowsPowerShell\Modules

    .EXAMPLE
        .\Install-PSDepend.ps1 -Path C:\Modules

        # Installs to C:\Modules\PSDepend
    #>
    [cmdletbinding()]
    param(
        [string]$Path = $( Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules')
    )
    $ExistingProgressPreference = "$ProgressPreference"
    $ProgressPreference = 'SilentlyContinue'
    try {
        # Bootstrap nuget if we don't have it
        if(-not ($NugetPath = (Get-Command 'nuget.exe' -ErrorAction SilentlyContinue).Path)) {
            $NugetPath = Join-Path $ENV:USERPROFILE nuget.exe
            if(-not (Test-Path $NugetPath)) {
                Invoke-WebRequest -uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile $NugetPath
            }
        }

        # Bootstrap PSDepend, re-use nuget.exe for the module
        if($path) { $null = mkdir $path -Force }
        $NugetParams = 'install', 'PSDepend', '-Source', 'https://www.powershellgallery.com/api/v2/',
                    '-ExcludeVersion', '-NonInteractive', '-OutputDirectory', $Path
        & $NugetPath @NugetParams
        Move-Item -Path $NugetPath -Destination "$(Join-Path $Path PSDepend)\nuget.exe" -Force
    }
    finally {
        $ProgressPreference = $ExistingProgressPreference
    }