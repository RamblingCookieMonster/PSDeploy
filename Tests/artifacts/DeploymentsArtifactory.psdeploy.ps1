Deploy ExampleDeployment {
    By Artifactory MyScript {
        FromSource '\Modules\File1.ps1'
        To 'http://artifactory.local:8081/artifactory'
        Tagged Prod
        WithOptions @{
            Credential = $script:artifactoryCred
            Repository = 'myscripts'
            OrgPath = 'MyOrg'
            Module = 'myscripts'
            BaseRev = '0.1.0'
            Properties = @{
                generatedOn='2016-04-20'
                generatedBy='Joe User'
            }
        }
        WithPreScript {
            $script:artifactoryCred = Get-Credential -Message 'Artifactory credential'
        }
    }
}