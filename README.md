[![Build status](https://ci.appveyor.com/api/projects/status/ntgl2679yn4g4m2b/branch/master?svg=true)](https://ci.appveyor.com/project/RamblingCookieMonster/psdeploy/branch/master)

PSDeploy
========

PSDeploy is a quick and dirty module to simplify distribution of files and folders. This is very much a work-in-progress.

The idea is that you keep a *.psdeploy.ps1 file in a folder, define sources and targets, and PSDeploy will deploy these.

Suggestions, pull requests, and other contributions would be more than welcome!

## Deployments

Invoking PSDeploy is very similar to running Invoke-Pester.  Here's an example, Some.PSDeploy.ps1

```powershell
Deploy ActiveDirectory1 {                        # Deployment name. This needs to be unique. Call it whatever you want.
    By Filesystem {                              # Deployment type. See Get-PSDeploymentType
        FromSource 'Tasks\AD\Some-ADScript.ps1', # One or more sources to deploy. Absolute, or relative to deployment.yml parent
                   'Tasks\AllOfThisDirectory'
        To '\\contoso.org\share$\Tasks'          # One or more destinations to deploy the sources to
        Tagged Prod                              # One or more tags you can use to restrict deployments or queries
        WithOptions @{
            Mirror: True                         # If the source is a folder, triggers robocopy purge. Danger.
        }
    }
}
```

Let's pretend Some.PSDeploy.ps1 lives in C:\Git\Misc\Deployments. Here's what happens when we invoke a deployment:

```powershell
Invoke-PSDeploy C:\Git\Misc
```

 * We search for all *.psdeploy.ps1 files under C:\Git\Misc, and find Some.PSDeploy.ps1. In this case, we have two resulting deployments, Some-ADScript.ps1, and AllOfThisDirectory
 * We check the deployment type. Filesystem.
 * We invoke the script associated with Filesystem Deployments, passing in the two deployments
 * C:\Git\Misc\Tasks\AD\Some-ADScript.ps1 is copied to \\contoso.org\share$\Tasks with Copy-Item
 * C:\Git\Misc\Tasks\AD\Tasks\AllOfThisDirectory is copied to \\contoso.org\share$\Tasks with robocopy, using /XO /E /PURGE (we only purge if mirror is true)

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
    Get-Help Invoke-PSDeploy -full
```

## Using PSDeploy

Here are a few example scenarios, illustrating the two deployment types, Filesystem and FilesystemRemote

### Filesystem Deployment

This is an example script where the account running PowerShell has access.

Some.PSDeploy.ps1 has Filesystem deployments, which run in this session, using robocopy and copy-item

```PowerShell
Import-Module PSDeploy
$Deployments = 'C:\Git\MyModule\Some.PSDeploy.ps1'

# Read some deployments ahead of time. Do they look right?
Get-PSDeployment -Path $Deployments

# Check out existing deployment types. You can extend these.
Get-PSDeploymentType

# Deploy! Use -Force to skip all prompts.
Invoke-PSDeploy -Path $Deployments
```

### FilesystemRemote deployment

This is an example script you might call from Jenkins. You should ideally gate deployments with Pester and ScriptAnalyzer, among other options.

Some.PSDeploy.ps1 has FilesystemRemote deployments, which clunkyly deploys from a remote session (consider the double hop implications):

```powershell
Deploy SomeModuleDeployment {
    By FileSystemRemote {
        FromSource 'SomeModule'
        To '\\Server\Modules'
        Tagged Prod, Module
        WithOptions @{
            Mirror = $True
            ComputerName = $JumpServer
            Credential = $cred
            ConfigurationName = 'SomeSessionConfig'
        }
    }
}
```

This is an example script you might use to invoke the deployment

```PowerShell
# Example using Jenkins with PSDeploy already installed
    Import-Module PSDeploy

# Path to deployments. Repository files are under the parent (workspace) directory.
    $SourceLocal = "C:\Jenkins\jobs\$($env:JOB_NAME)\workspace"

# Remoting details, cred based on Jenkins Global Password from EnvInject
    $JumpServer = 'server.contoso.org'
    $SecurePassword = $env:SomeJenkinsGlobalCreds | ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList "contoso\SomeUser", $SecurePassword

# Invoke a deployment! Any 'FileSystemRemote' deployment types will have the DeploymentParameters.FilesystemRemote parameters splatted
    Invoke-PSDeploy -Path $SourceLocal
```

## Extending PSDeploy

PSDeploy is somewhat extensible. To add a new deployment type:

* Update PSDeploy.yml in the PSDeploy root.
  * The deployment name is the root node.
  * The script node defines what script to run for these deployment types
  * The description is... not really used. But feel free to write one!
  * For example, I might add support for SCP:

```yaml
SCP:
  Script: SCP.ps1
  Description: Deploys artifacts using SCP. Requires Posh-SSH
```

* Create the associated script in PSDeploy\PSDeployScripts
  * For example, I would create \\Path\To\PSDeploy\PSDeployScripts\SCP.ps1
  * Include a 'Deployment' parameter.
    * See [\\\\Path\To\PSDeploy\PSDeployScripts\FilesystemRemote.ps1](https://github.com/RamblingCookieMonster/PSDeploy/blob/master/PSDeploy%2FPSDeployScripts%2FFilesystemRemote.ps1) for an example
    * Here's how I implement this:

```powershell
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment
    #... other params
)

# Further down, I remove deployment From PSBoundParameters, and splat that as needed.
# $Deployment would still be available, just not listed in bound params.
$PSBoundParameters.Remove('Deployment')
```

## Notes

Thanks go to:

* Scott Muc for [PowerYaml](https://github.com/scottmuc/PowerYaml), which we borrow for YAML parsing
* Boe Prox for [Get-FileHash](http://learn-powershell.net/2013/03/25/use-powershell-to-calculate-the-hash-of-a-file/), which we borrow for downlevel hash support in the deployment scripts.
* Michael Greene, for the idea of using a DSL similar to Pester
