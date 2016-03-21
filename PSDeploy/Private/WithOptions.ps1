Function WithOptions {
    [cmdletbinding()]
    param(
        [parameter( Position = 0,
                    Mandatory = $True)]
        [System.Collections.Hashtable]$Options
    )

    $Script:ThisBy.DeploymentOptions = $Options
}