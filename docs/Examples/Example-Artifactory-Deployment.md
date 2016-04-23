# Example: Artifactory Deployment
The following is an example of defining a deployment to [Artifactory](https://www.jfrog.com/artifactory/):

#### my.psdeploy.ps1
```powershell
Deploy ExampleDeployment {

    By Artifactory MyScript {
        FromSource 'myscript.ps1'
        To 'http://artifactory.local:8081/artifactory'
        Tagged Prod
        WithOptions @{
            Credential = $script:artifactoryCred
            Repository = 'myscripts'
            OrgPath = 'MyOrg'
            Module = 'MyCoolModule'
            BaseRev = '0.1.0'
            FileItegRev = ''
            Properties = @{
                generatedOn='2016-04-01'
                generatedBy='Joe User'
            }            
        }
	    WithPreScript {
            $script:artifactoryCred = Get-Credential -Message 'Artifactory credential'
        }
    }
}
```

The deployment above will issue a `PUT` request using Invoke-RestMethod to the URL `http://artifactory.local:8081/artifactory/myscripts/MyOrg/myscripts/myscripts-0.1.0.ps1;generatedOn=2016-04-20;generatedBy=Joe User`
using the specified credential and upload the file `myscript.ps1` specified in `FromeSource`.

The properties `generatedOn` and `generatedBy` are extra meta data properties that are attached to the artifact.
You can search on these properties within the Artifactory interface or using the API.