Deploy MyDeploymentName {

    # Allow multiple types per named deploy
    # Allow specifying an optional name to differentiate
    By FileSystem 'OptionalName' {

        FromSource 'Tests' #From is a reserved keyword, nix From/To phrasing...

        To 'C:\temp\Test'

        # Not sure if there is a friendlier way (v. hash) to take arbitrary parameters
        # Also, the name is awkward. All one word? Two words? Something else?
        WithOptions @{
            Mirror = $False
        }
    }

    By FileSystem {

        FromSource 'PSDeploy'
        To 'C:\temp\PSDeploy'
        WithOptions @{
            Mirror = $True
        }
        Tag module, prod
    }
}