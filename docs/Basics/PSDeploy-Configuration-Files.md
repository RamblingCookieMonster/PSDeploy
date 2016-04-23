# PSDeploy Configuration Files
PSDeploy has several configuration files to work with:

* Deployment configurations: *.PSDeploy.ps1 script files
* DeploymentType configurations: What script runs what deployment type

## Deployment Configurations: *.PSDeploy.ps1

These are PowerShell scripts that tell PSDeploy what to deploy.

They build up the following details on a deployment:

```
DeploymentName:    Name for a particular deployment.  Must be unique.
DeploymentType:    The type of deployment.  Tells PSDeploy how to deploy (FileSystem, ARM, etc.)
DeploymentOptions: One or more options to pass along to the DeploymentType script
Tags:              One or more tags associated with this deployment
Source:            One or more source items to deploy
Targets:           One or more targets to deploy to
Dependencies:      One or more DeploymentNames that this deployment depends on
```

A *.PSDeploy.ps1 file will have one or more deployment blocks like this:

```powershell
Deploy UniqueDeploymentName                         # Deployment name.
    By FileSystem {                                 # Deployment type.
        FromSource RelativeSourceFolder,            # One or more sources to deploy. These are specific to your DeploymentType
                   Subfolder\RelativeSource.File,
                   \\Absolute\Source$\FolderOrFile
        To \\Some\Target$\Folder,                   # One or more destinations to target for deployment. These are specific to a DeploymentType
           \\Another\Target$\Folder
        Tagged Prod, Module                         # One or more tags for this deployment. Optional
        WithOptions @{                              # Deployment options hash table to pass as parameters to DeploymentType script. Optional.
            Mirror = $True
        }
        DependingOn SomeOtherDeployment             # Run this deployment only after SomeOtherDeployment has run
    }
}
```

These are each PowerShell functions (only useful in a PSDeploy.ps1 file), so you can run Get-Help to find out more information:

```powershell
Get-Help Deploy -Full
Get-Help By -Full
Get-Help FromSource -Full
Get-Help To -Full
Get-Help Tagged -Full
Get-Help WithOptions -Full
Get-Help DependingOn -Full
```

Keep in mind that this is a PowerShell script.
You can use the language to make your deployments more flexible.

## DeploymentType map: PSDeploy.yml

This is a file that tells PSDeploy what script to use for each DeploymentType.
By default, it sits in your PSDeploy module folder.

There are two scenarios you would generally work with this:

* You want to extend PSDeploy to add more DeploymentTypes
* You want to move the PSDeploy.yml to a central location that multiple systems could point to

There are three attributes to each DeploymentType in this file:

```
DeploymentType Name:  The name of this DeploymentType
Script:               The name of the script to process these DeploymentTypes
                      This looks in the PSDeploy module path, under PSDeployScripts
                      You can theoretically specify an absolute path
Description:          Description for this DeploymentType. Provided to a user when they run Get-PSDeploymentType.
```

The PSDeploy.yml file will have one or more DeploymentType blocks like this:

```yaml
Filesystem:
  Script: Filesystem.ps1
  Description: Uses the current session and Robocopy or Copy-Item for folder and file deployments, respectively.
```