Function Deploy {
    [cmdletbinding()]
    param(
        [parameter( Position = 0,
                    Mandatory = $False)]
        [string]$Name = $( [guid]::NewGuid().Guid ),

        [parameter( Position = 1,
                    Mandatory = $True)]
        [scriptblock]$Script

    )

    $Script:ThisDeployment = @{
        DeploymentName = $Name
    }

    . $Script
}