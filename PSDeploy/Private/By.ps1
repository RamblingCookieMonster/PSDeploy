Function By {
    [cmdletbinding(DefaultParameterSetName = 'NoName')]
    param(
        [parameter( Position = 0,
                    Mandatory = $True)]
        [string]$DeploymentType,

        [parameter( ParameterSetName = 'Name',
                    Position = 1,
                    Mandatory = $False)]
        [string]$Name,

        [parameter( ParameterSetName = 'NoName',
                    Position = 1,
                    Mandatory = $true)]
        [parameter( ParameterSetName = 'Name',
                    Position = 2,
                    Mandatory = $true)]
        [ScriptBlock]$Script

    )

    $Script:ThisBy = [pscustomobject]@{
        DeploymentName = $null
        DeploymentType = $null
        Source = $null
        Targets = $null
        DeploymentOptions = $null
    }

    if( $PSCmdlet.ParameterSetName -eq 'Name')
    {
        $Name = "$($Script:ThisDeployment.DeploymentName)-$Name"
    }
    else
    {
        $Name = $Script:ThisDeployment.DeploymentName
    }

    $Namespace = @( $Script:Deployments | Where {$_.DeploymentType -eq $DeploymentType -and $_.Name -eq $Name} )
    if($Namespace.Count -gt 0)
    {
        Write-Error "Could not add 'By $Name', please ensure your 'By' blocks have a unique name within their DeploymentType."
    }
    else
    {
        $Script:ThisBy.DeploymentName = $Name
        $Script:ThisBy.DeploymentType = $DeploymentType
        . $Script

        if($null -eq $Script:ThisBy.Source)
        {
            Write-Error "Missing Source for By '$($ThisBy.DeploymentName)'"
            return
        }
        if($null -eq $Script:ThisBy.Targets)
        {
            Write-Error "Missing Targets for By '$($ThisBy.DeploymentName)'"
            return
        }

        $Script:Deployments.Add($Name, $Script:ThisBy)
        Remove-Variable -Name ThisBy -Scope Script -Confirm:$False -Force
    }
}