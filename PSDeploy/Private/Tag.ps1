# From is a reserved keyword...
Function Tag {
    [cmdletbinding()]
    param(
        [parameter( Position = 0,
                    Mandatory = $True)]
        [string[]]$Tags
    )

    $Script:ThisBy.Tags = $Tags
}