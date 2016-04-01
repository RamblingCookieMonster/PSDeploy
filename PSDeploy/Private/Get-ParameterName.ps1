Function Get-ParameterName {
#Get parameter names for a specific command
    [cmdletbinding()]
    param(
        [string]$command,
        [string]$parameterset = $null,
        [string[]]$excludeDefault = $( "Verbose",
                                "Debug",
                                "ErrorAction",
                                "WarningAction",
                                "ErrorVariable",
                                "WarningVariable",
                                "OutVariable",
                                "OutBuffer",
                                "PipelineVariable",
                                "Confirm",
                                "Whatif" ),
        [string[]]$exclude = $( "Passthru", "Commit" )
    )
    if($parameterset)
    {
        ((Get-Command -name $command).ParameterSets | ?{$_.name -eq $parameterset} ).Parameters.Name | ?{($exclude + $excludeDefault) -notcontains $_}
    }

    else
    {
        ((Get-Command -name $command).ParameterSets | ?{$_.name -eq "__AllParameterSets"} ).Parameters.Name | ?{($exclude + $excludeDefault) -notcontains $_}
    }
}