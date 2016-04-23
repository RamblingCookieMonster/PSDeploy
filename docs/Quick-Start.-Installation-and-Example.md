### PSDeploy Installation

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PSDeploy folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module PSDeploy

# Import the module.
    Import-Module PSDeploy    #Alternatively, Import-Module \\Path\To\PSDeploy

# Get commands in the module
    Get-Command -Module PSDeploy

# Get help for the module and a command
    Get-Help about_PSDeploy
    Get-Help Invoke-PSDeploy -full       # *.PSDeploy.ps1 based deployments
    Get-Help Invoke-PSDeployment -full   # yaml based deployments (legacy)
```

### PSDeploy Example

All you need is a *.psdeploy.ps1 file that tell PSDeploy about your deployments. Here's a quick example.

Here are some source files I want to deploy:

[![Source](images/DirFrom.png)](images/DirFrom.png)

Here's my *.PSDeploy.ps1 file

```powershell
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

Here's how PSDeploy reads that file:

[![Get-PSDeployment Output](images/QuickStart-Get-PSD.png)](images/QuickStart-Get-PSD.png)

We invoke this deployment similar to Invoke-Pester:

```powershell
PS C:\PSDeployFrom> Invoke-PSDeploy
```

Your deployments are parsed and carried out:

[![GCI Output](images/QuickStart.AfterInvoke.png)](images/QuickStart.AfterInvoke.png)

