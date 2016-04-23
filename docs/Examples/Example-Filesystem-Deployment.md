# Example: FileSystem Deployment
This is a quick example showing a Filesystem deployment:

Here's the deployment config, My.PSDeploy.ps1:

#### my.psdeploy.ps1
```PowerShell
Deploy ExampleDeployment {

    By FileSystem Scripts {
        FromSource 'SomeScripts'
        To 'C:\PSDeployTo'
        Tagged Dev
        DependingOn ExampleDeployment-Modules
    }

    By FileSystem Modules {
        FromSource MyModule
        To C:\PSDeployTo
        Tagged Prod, Module
        WithOptions @{
            Mirror = $true
        }
    }
}
```

Here are the source files:

```powershell
Get-ChildItem -Path "C:\PSDeployFrom" -Recurse | Select-Object -ExpandProperty FullName

C:\PSDeployFrom\Deployments
C:\PSDeployFrom\Deployments\my.psdeploy.ps1
C:\PSDeployFrom\MyModule
C:\PSDeployFrom\MyModule\MyModule.psd1
C:\PSDeployFrom\MyModule\MyModule.psm1
C:\PSDeployFrom\SomeScripts
C:\PSDeployFrom\SomeScripts\Script1.ps1
C:\PSDeployFrom\SomeScripts\Script2.ps1
```

We invoke PSDeploy with a  and deployments run as expected:

```powershell
Get-ChildItem -Path C:\PSDeployTo -Recurse | Select-Object -ExpandProperty FullName

C:\PSDeployTo\MyModule.psd1
C:\PSDeployTo\MyModule.psm1
C:\PSDeployTo\Script1.ps1
C:\PSDeployTo\Script2.ps1
```