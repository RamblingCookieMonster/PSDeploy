[![Build status](https://ci.appveyor.com/api/projects/status/ntgl2679yn4g4m2b/branch/master?svg=true)](https://ci.appveyor.com/project/RamblingCookieMonster/psdeploy/branch/master)

PSDeploy
========

PSDeploy is a quick and dirty module to simplify PowerShell based deployments.

The idea is that you write a *.psdeploy.ps1 deployment configuration with sources and targets, and PSDeploy will deploy these.

Suggestions, pull requests, and other contributions would be more than welcome!

## Deployments

Invoking PSDeploy is very similar to running Invoke-Pester.  Here's an example, Some.PSDeploy.ps1

```powershell
Deploy ActiveDirectory1 {                        # Deployment name. This needs to be unique. Call it whatever you want
    By Filesystem {                              # Deployment type. See Get-PSDeploymentType
        FromSource 'Tasks\AD\Some-ADScript.ps1', # One or more sources to deploy. Absolute, or relative to deployment.yml parent
                   'Tasks\AllOfThisDirectory'
        To '\\contoso.org\share$\Tasks'          # One or more destinations to deploy the sources to
        Tagged Prod                              # One or more tags you can use to restrict deployments or queries
        WithOptions @{
            Mirror: True                         # If the source is a folder, triggers robocopy purge. Danger
        }
    }
}
```

Let's pretend Some.PSDeploy.ps1 lives in C:\Git\Misc\Deployments. Here's what happens when we invoke a deployment:

```powershell
Invoke-PSDeploy -Path C:\Git\Misc
```

 * We search for all *.psdeploy.ps1 files under C:\Git\Misc, and find Some.PSDeploy.ps1. In this case, we have two resulting deployments, Some-ADScript.ps1, and AllOfThisDirectory
 * We check the deployment type. Filesystem.
 * We invoke the script associated with Filesystem Deployments, passing in the two deployments
 * Relative paths are resolved by joining paths with C:\Git\Misc
 * C:\Git\Misc\Tasks\AD\Some-ADScript.ps1 is copied to \\contoso.org\share$\Tasks with Copy-Item
 * C:\Git\Misc\Tasks\AD\Tasks\AllOfThisDirectory is copied to \\contoso.org\share$\Tasks with robocopy, using /XO /E /PURGE (we only purge if mirror is true)

## Initial PSDeploy setup

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PSDeploy folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module PSDeploy

# Import the module.
    Import-Module PSDeploy    # Alternatively, Import-Module \\Path\To\PSDeploy

# Get commands in the module
    Get-Command -Module PSDeploy

# Get help for the module and a command
    Get-Help about_PSDeploy
    Get-Help Invoke-PSDeploy -full
```

## More Information

The [PSDeploy Wiki](https://github.com/RamblingCookieMonster/PSDeploy/wiki) will include more information, including:

* Example deployments - will try to keep these in sync with new types when they are added
* How to write new PSDeploy DeploymentTypes
* Details on the PSDeploy Configuration Files

They will become out of date over time, but the original (yaml-focused) and updated (*.psdeploy.ps1-focused) blog posts may include helpful details:

* [Original PSDeploy post](http://ramblingcookiemonster.github.io/PSDeploy/)
* [*.PSDeploy.ps1 post](http://ramblingcookiemonster.github.io/PSDeploy-Take-Two/)

## Notes

Thanks go to:

* Scott Muc for [PowerYaml](https://github.com/scottmuc/PowerYaml), which we borrow for YAML parsing
* Boe Prox for [Get-FileHash](http://learn-powershell.net/2013/03/25/use-powershell-to-calculate-the-hash-of-a-file/), which we borrow for downlevel hash support in the deployment scripts
* Michael Greene, for the idea of using a DSL similar to Pester
* Folks writing new PSDeploy deployment types - thank you!
