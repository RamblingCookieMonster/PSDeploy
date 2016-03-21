Function To {
    [cmdletbinding()]
    param(
        [parameter( Position = 0,
                    Mandatory = $True)]
        [object[]]$Targets
    )

    $Script:ThisBy.Targets = $Targets
}