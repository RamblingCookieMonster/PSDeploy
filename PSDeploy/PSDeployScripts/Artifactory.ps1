param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,
    
    # TODO
    #... other params
    [string]$Version
)

foreach($Deploy in $Deployment)
{
    Write-Verbose -Message "Deploying version [$Version] of $($Deploy.DeploymentName) to Artifactory endpoint"
    
    if (Test-Path -Path $Deploy.Source)
    {        
        if($Deploy.SourceType -eq 'Directory')
        {
            Write-Verbose 'Source is a directory!'   
        }
        else
        {
            Write-Verbose 'Source is a file'
        }        
        
        foreach($Target in $Deploy.Targets)
        {
            Write-Verbose -Message $Deploy.Source
            Write-Verbose -Message $Target
            #Deliver-SomethingTo $Target -From $Deploy.Source
        }   
    }
    else
    {
        throw "Unable to find [$(Deploy.Source)]"
    }
}