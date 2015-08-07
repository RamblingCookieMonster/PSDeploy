PSDeploy
========

# Overview

PSDeploy is a quick and dirty module to simplify distribution of files and folders. It is very much a work-in-progress and likely has bugs and inefficiencies.

You keep a Deployments.yml file in a folder, define sources and targets, and PSDeploy will deploy files and folders as defined.

Wrote this for a few reasons:

* I like fun side projects
* I'm hoping to introduce CI/CD to the team, and a simplified deployment might help
* We use [Jenkins](https://www.hodgkins.net.au/powershell/automating-with-jenkins-and-powershell-on-windows-part-1/). Their build definition process leaves a bit to be desired. This allows me to use the same abstracted deployment as long as I have a deployments.yml in the repo root.
* THis might help folks who use more than one tool chain. I could use PSDeploy with Jenkins, TeamCity, AppVeyor, etc.

Suggestions, pull requests, and other contributions would be more than welcome!

# Terminology

* **Deployment**: These are yaml files defining what is being deployed. They might have a source, a destination, and options for specific types of deployment
* **Deployment Type**: These define how to actually deploy something. Each type is associated with a script. The default types are FileSystem and FileSystemRemote. This is extensible.
* **Deployment Script**: These are scripts associated to a particular deployment type. All should accept a 'Deployment' parameter. For example, the FileSystem script uses robocopy or copy-item to deploy folders and files, respectively.

# Deployments.yml Example

Here's an example entry in Deployments.yml

```yaml
ActiveDirectory1:                  # Deployment name. This NEEDS to be unique. Call it whatever you want.
  Author: 'wframe'                 # Author. Optional.
  Source:                          # One or more sources to deploy. Relative to deployment.yml parent
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
   * We didn't specify -DeploymentRoot, so we check relative path to source files under C:\Git\Misc (the yml file's parent)
 * We check the deployment type. Filesystem.
 * We invoke the script associated with Filesystem Deployments, passing in the ActiveDirectory1 deployment
 * C:\Git\Misc\Tasks\AD\Some-ADScript.ps1 is copied with Copy-Item (it's a file) to \\contoso.org\share$\Tasks
 * C:\Git\Misc\Tasks\AD\Tasks\AllOfThisDirectory is copied to \\contoso.org\share$\Tasks with robocopy, using /XO /E /PURGE (we only purge if mirror is true in yml)

# Initial setup

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
    Get-Help Invoke-PSDeployment
```

# Using PSDeploy

Here are a few example scenarios, illustrating the two initial deployment types, Filesystem and FilesystemRemote

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
The deployments.yml has FilesystemRemote deployments, which clunkyly deploys from a remote session (consider double hop implications).

```PowerShell

# Example using Jenkins with PSDeploy stored in a random path.
# My repository has a deployments.yml at the root.

# Import the module
    Try
    {
        #I previously copied the PSDeploy module here
        Import-Module C:\PSModules\PSDeploy -ErrorAction Stop
    }
    Catch
    {
        Throw "Failed to load PSDeployment:`n$_"
    }

# Path to deployments. All the files to be deployed are under the parent (workspace) directory.
    $SourceLocal = "C:\Jenkins\jobs\$($env:JOB_NAME)\workspace\Deployments.yml"

# Remoting details, cred based on Jenkins Global Password
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

# Notes

I'm assuming there might an existing solution out there. Wrote this partly out of a specific need, partly as a fun side project. It grew organically, so it's a bit of a mess.

TODO:

* Remove reliance on relative paths for sources  * Sources                - allow deploying from a more deterministic path
* Schema could use work.
* Fix bad code. PRs would be welcome
* More deployment types, if / when they come up
* Order of operations.
  * For example, perhaps you have an 'archive file' deployment type, and you want to run that first, deploy the resulting archive as another deployment type.
* Comment based help for scripts, expose through a parameter on Get-PSDeploymentType
* Blog. Figured I'd get this out there and see if I'm overlooking anything obvious before writing