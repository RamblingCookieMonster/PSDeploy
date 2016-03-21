# From is a reserved keyword...
Function FromSource {
    [cmdletbinding()]
    param(
        [parameter( Position = 0,
                    Mandatory = $True)]
        [object[]]$Source,

        [parameter( Position = 1,
                    Mandatory = $false)]
        [string]$DeploymentRoot = (Get-Location).Path
    )

    $Script:ThisBy.Source = $Source
}