function Sort-PSDeployment {
    [cmdletbinding()]
    param(
        [object[]]$Deployments
    )

    $Order = @{}
    Foreach($Deployment in $Deployments)
    {
        if($Deployment.Dependencies)
        {
            $Order.add($Deployment.DeploymentName, $Deployment.Dependencies)
        }
    }

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