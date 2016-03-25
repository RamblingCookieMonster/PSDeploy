function Sort-PSDeployment {
    [cmdletbinding()]
    param(
        [object[]]$Deployments
    )

    Write-Verbose "Working on $($Deployments | Select DeploymentName, Dependencies | Out-String)"
    $Order = @{}
    Foreach($Deployment in $Deployments)
    {
        if($Deployment.Dependencies)
        {
            $Order.add($Deployment.DeploymentName, $Deployment.Dependencies)
        }
    }
    Write-Verbose "$($Order | Out-String)"

    if($Order.Keys.Count -gt 0)
    {
        $DeployOrder = Get-TopologicalSort $Order
        Sort-ObjectWithCustomList -InputObject $Deployments -Property DeploymentName -CustomList $DeployOrder
    }
    else
    {
        $Deployments
    }
}