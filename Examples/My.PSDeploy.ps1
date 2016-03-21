Deploy MyDeploymentName {

    # Allow multiple types per named deploy
    # Allow specifying an optional name to differentiate
    By FileSystem 'OptionalName' {

        FromSource 'Tests' #From is a reserved keyword, nix From/To phrasing...

        To 'C:\sc\'

        # Not sure if there is a friendlier way (v. hash) to take arbitrary parameters
        # Also, the name is awkward. All one word? Two words? Something else?
        WithOptions @{
            Mirror = $False
        }
    }

    By FileSystem {

        FromSource 'PSDeploy'

        To 'C:\sc\PSDeploy'

        WithOptions @{
            Mirror = $True
        }
    }
}


<#
Functions:

    Deploy 0Name 1Scriptblock Force? PSDeployTypePath

    By 0DeploymentType [1DeploymentTypeName]

    From 0Source[]

    To 0Targets[]

    WithOptions 0DeploymentOptions[]

Flow:

Loop through Deploys.
    Validate that By Names are unique across this named Deploy and Deployment Type.
    Loop through Bys
        Build details. From, To, Options
        Create 'Deployment' object
        Invoke-PSDeployment
        
#>