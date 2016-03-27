Function Get-TaggedDeployment {
    param(
        [object[]]$Deployment,
        [string[]]$Tags
    )

    # Only return deployment with all specified tags
    foreach($Deploy in $Deployment)
    {
        $Include = $False
        foreach($Tag in @($Tags))
        {
            if($Deploy.Tags -contains $Tag)
            {
                $Include = $True
            }
        }
        If($Include)
        {
            $Deploy
        }
    }
}