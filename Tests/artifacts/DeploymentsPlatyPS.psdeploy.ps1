Deploy TestHelp {
    By PlatyPS {
        FromSource '\Modules\TestModule'
        To "$ENV:BHProjectName\en-US"
        Tagged Testing, Success
        WithOptions @{
            Force = $true
        }
    }

    By PlatyPS {
        FromSource '\Does\Not\Exist'
        To "$ENV:BHProjectName\en-US"
        Tagged Testing, Failure
        WithOptions @{
            Force = $true
        }
    }

    By PlatyPS {
        FromSource '\Modules\TestModule'
        To "$ENV:BHProjectName\en-US"
        Tagged Testing, Encoding, Success
        WithOptions @{
            Force = $true
            Encoding = ([System.Text.Encoding]::Unicode)
        }
    }
}