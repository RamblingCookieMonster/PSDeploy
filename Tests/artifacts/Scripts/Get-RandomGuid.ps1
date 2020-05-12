<#
.SYNOPSIS
    Generates a list of random GUIDs
.DESCRIPTION
    The Get-RandomGuid cmdlet generates a list of random GUIDs based on the input number
.PARAMETER Number
    Number of GUIDs to generate.
.EXAMPLE
    Get-RandomGuid -Number 10
    Accept input data from the parameter
.EXAMPLE
    10 | Get-RandomGuid
    Accept input data from the pipeline
.INPUTS
    System.Int
.OUTPUTS
    System.Guid
#>

    [CmdletBinding(
        PositionalBinding = $true)]
    [OutputType([System.Guid])]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Number
    )

begin {
    Write-Verbose "Runbook started at time: $(Get-Date -Format R)"
}

process {
    1..$Number | ForEach-Object { New-Guid }
}

end {
    Write-Verbose "Runbook ended at time: $(Get-Date -Format R)"
}