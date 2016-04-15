function Sort-PSDeployment {
    [cmdletbinding()]
    param(
        [object[]]$Deployments
    )

    $Order = @{}
    Foreach($Deployment in $Deployments)
    {
        if($Deployment.Dependencies.DeploymentName)
        {
            if(-not $Order.ContainsKey($Deployment.DeploymentName))
            {
                $Order.add($Deployment.DeploymentName, $Deployment.Dependencies.DeploymentName)
            }
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