Function Get-TaggedDeployment {
    param(
        [object[]]$Deployment,
        [string[]]$Tags
    )

    # Only return deployment with all specified tags
    foreach($Deploy in $Deployment)
    {
        $Include = $True
        foreach($Tag in @($Tags))
        {
            if($Deploy.Tags -notcontains $Tag)
            {
                $Include = $False
            }
        }
        If($Include)
        {
            $Deploy
        }
    }
}