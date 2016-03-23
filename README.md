[![Build status](https://ci.appveyor.com/api/projects/status/ntgl2679yn4g4m2b/branch/master?svg=true)](https://ci.appveyor.com/project/RamblingCookieMonster/psdeploy/branch/master)

PSDeploy
========

PSDeploy is a quick and dirty module to simplify distribution of files and folders. This is very much a work-in-progress.

The idea is that you keep a Deployments.yml file in a folder, define sources and targets, and PSDeploy will deploy these.

Suggestions, pull requests, and other contributions would be more than welcome!

## Deployments.yml Example

Here's an example Deployments.yml

```yaml
ActiveDirectory1:                  # Deployment name. This needs to be unique. Call it whatever you want.
  Author: 'wframe'                 # Author. Optional.
  Source:                          # One or more sources to deploy. Absolute, or relative to deployment.yml parent
    - 'Tasks\AD\Some-ADScript.ps1'
    - 'Tasks\AllOfThisDirectory'
  Destination:                     # One or more destinations to deploy the sources to
    - '\\contoso.org\share$\Tasks'
  DeploymentType: Filesystem       # Deployment type. See Get-PSDeploymentType
  Options:
    Mirror: True                   # If the source is a folder, triggers robocopy purge. Danger.
```

Let's pretend this deployments.yml lives in C:\Git\Misc. Here's what happens when we invoke a deployment:

```Invoke-PSDeployment -Path C:\Git\Misc\deployments.yml```

 * We read the yaml. In this case, we have two resulting deployments, Some-ADScript.ps1, and AllOfThisDirectory
   * We didn't specify absolute paths or -DeploymentRoot, so we check relative path to source files under C:\Git\Misc (the yml file's parent)
 * We check the deployment type. Filesystem.
 * We invoke the script associated with Filesystem Deployments, passing in the ActiveDirectory1 deployment
 * C:\Git\Misc\Tasks\AD\Some-ADScript.ps1 is copied to \\contoso.org\share$\Tasks with Copy-Item
 * C:\Git\Misc\Tasks\AD\Tasks\AllOfThisDirectory is copied to \\contoso.org\share$\Tasks with robocopy, using /XO /E /PURGE (we only purge if mirror is true in yml)

## Initial setup

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
    Get-Help Invoke-PSDeployment -full
```

## Using PSDeploy

Here are a few example scenarios, illustrating the two deployment types, Filesystem and FilesystemRemote

### Filesystem Deployment

This is an example script where the account running PowerShell has access.

The deployments.yml has Filesystem deployments, which run in this session, using robocopy and copy-item

```PowerShell
Import-Module PSDeploy
$Yaml = 'C:\Git\MyModule\deployments.yml'

# Read some deployments ahead of time. Do they look right?
Get-PSDeployment -Path $Yaml

# Check out existing deployment types. You can extend these.
Get-PSDeploymentType

# Deploy! Use -Force to skip all prompts.
Invoke-PSDeployment -Path $Yaml
```

### FilesystemRemote deployment

This is an example script you might call from Jenkins.
The deployments.yml has FilesystemRemote deployments, which clunkyly deploys from a remote session (consider the double hop implications).

```PowerShell
# Example using Jenkins with PSDeploy already installed
# My repository has a deployments.yml at the root.
    Import-Module PSDeploy

# Path to deployments. All the files to be deployed are under the parent (workspace) directory.
    $SourceLocal = "C:\Jenkins\jobs\$($env:JOB_NAME)\workspace\Deployments.yml"

# Remoting details, cred based on Jenkins Global Password from EnvInject
    $JumpServer = 'server.contoso.org'
    $SecurePassword = $env:SomeJenkinsGlobalCreds| ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList "contoso\SomeUser", $SecurePassword

# Invoke a deployment! Any 'FileSystemRemote' deployment types will have the DeploymentParameters.FilesystemRemote parameters splatted
    Invoke-PSDeployment -Path $SourceLocal -DeploymentParameters @{
            FilesystemRemote = @{
                ComputerName = $JumpServer
                Credential = $cred
                ConfigurationName = 'SomeSessionConfig'
            }
        }
```
### CopyVMFile deployment

This is an example script you might put it in your Hyper-V host.
The deployment.yml has CopyVMfile deployment, which deploys file from the Hyper-V host to the VM running on the same host using Copy-VMfile cmdlet (ships with Hyper-V module).

```PowerShell
# Project named CloudAutomation has file under Labteardown\teardown.ps1 which I want deployed to VM named 'testAutomation' under C:\temp\CloudAutomation directory. Below is how the deploment.yml file looks for this.
PS>get-content .\deployment.yml
CloudAutomation:                  # Deployment name. This needs to be unique. Call it whatever you want.
  Author: 'DexterPOSH'                 # Author. Optional.
  Source:                          # One or more sources to deploy. Absolute, or relative to deployment.yml parent
    - 'LabtearDown\TearDown.ps1'
  Destination:                     # One or more destinations to deploy the sources to
    - C:\Temp\CloudAutomation\
  DeploymentType: CopyVMFile       # Deployment type. See Get-PSDeploymentType
  Options:
    Name: testAutomation #name of the VM to which the file needs to be deployed
    CreateFullPath: True
    FileSource: Host

#Invoke the Deployment to copy file
TRY {
Get-PSDeployment -Path .\deployment.yml |
    Invoke-PSDeployment -Verbose -Force -ErrorAction Stop

}
CATCH [Microsoft.HyperV.PowerShell.VirtualizationException] {
    Write-host -ForegroundColor Green "All the changes are already synced"

}

## Notes

TODO:

* Schema could use work.
* Fix bad code. PRs would be welcome
* More deployment types, if / when they come up
* Order of operations.
  * For example, perhaps you have an 'archive file' deployment type, and you want to run that first, deploy the resulting archive as another deployment type.

Thanks to Scott Muc's [PowerYaml](https://github.com/scottmuc/PowerYaml), which we borrow for YAML parsing, and Boe Prox' [Get-FileHash](http://learn-powershell.net/2013/03/25/use-powershell-to-calculate-the-hash-of-a-file/), which we borrow for downlevel hash support in the deployment scripts.
