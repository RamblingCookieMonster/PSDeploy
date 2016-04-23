# Quick Start 

## PSDeploy Installation

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

## PSDeploy Example

All you need is a `*.psdeploy.ps1` file that tells PSDeploy about your deployments. 
Here's a quick example.

Here are some source files I want to deploy:

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

Here's my `*.PSDeploy.ps1` file

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

```powershell
Get-PSDeployment -Path C:\PSDeployFrom\Deployments\my.psdeploy.ps1 -DeploymentRoot C:\PSDeployFrom |
    Select -Property *
    
DeploymentFile    : C:\PSDeployFrom\Deployments\my.psdeploy.ps1
DeploymentName    : ExampleDeployment-Modules
DeploymentType    : FileSystem
DeploymentOptions : {Mirror}
Source            : C:\PSDeployFrom\MyModule
SourceType        : Directory
SourceExists      : True
Targets           : {C:\PSDeployTo}
Tags              : {Prod, Module}
Dependencies      :
Raw               :

DeploymentFile    : C:\PSDeployFrom\Deployments\my.psdeploy.ps1
DeploymentName    : ExampleDeployment-Scripts
DeploymentType    : FileSystem
DeploymentOptions :
Source            : C:\PSDeployFrom\SomeScripts
SourceType        : Directory
SourceExists      : True
Targets           : {C:\PSDeployTo}
Tags              : {Dev}
Dependencies      : {ExampleDeployment-Modules}
Raw               :
```

We invoke this deployment similar to `Invoke-Pester`:

```powershell
Invoke-PSDeploy -Path C:\PSDeployFrom\Deployments\my.psdeploy.ps1
```

Your deployments are parsed and carried out:

```powershell
Get-ChildItem -Path C:\PSDeployTo -Recurse | Select-Object -ExpandProperty FullName

C:\PSDeployTo\MyModule.psd1
C:\PSDeployTo\MyModule.psm1
C:\PSDeployTo\Script1.ps1
C:\PSDeployTo\Script2.ps1
```