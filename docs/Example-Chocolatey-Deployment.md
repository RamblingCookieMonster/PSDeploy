# Overview
Chocolatey is an open source package manager for Windows. It's built on top of the Nuget framework which allows for storing the packages in a repository. For more information on what Chocolatey is you can learn more at the [Chocolatey website](https://chocolatey.org/) or the [Github Page](https://github.com/chocolatey/choco).

There is a community feed available, but most organizations host their own private repositories. For more information on setting up your own repository see [How To Host Your Own Package Repository Server](https://chocolatey.org/docs/how-to-host-feed).

# Prerequisites
The local system must have Chocolatey installed in order to do the deployment.

# Options
The options ApiKey and Force map directly to the ApiKey and Force parameters in the [choco push command](https://chocolatey.org/docs/commands-push).

# Examples
## Deploying a single package
### SingleChocolateyPackage.PSDeploy.ps1

Here's an example Deployment config:

```PowerShell
Deploy SingleChocolateyPackage {
    By Chocolatey {
        FromSource 'c:\ChocolateyPackages\examplepackage.0.1.1.nupkg'
        To "http://your-choco-repo.internal.com/"
        WithOptions @{
            ApiKey = 'yourAPIkey'
            Force = $true
        }
    }
}
```

This deployment takes the file `examplepackage.0.1.1.nupkg` from the specified location and runs choco push to deploy the package to the internal repository.

## Deploying a group of packages from a directory
### DirectoryChocolateyPackage.PSDeploy.ps1

This example shows using Unicode as the Encoding.

```PowerShell
Deploy DirectoryChocolateyPackage {
    By Chocolatey {
      FromSource 'c:\ChocolateyPackages'
      To "http://your-choco-repo.internal.com/"
      WithOptions @{
          ApiKey = 'yourAPIkey'
          Force = $true
      }
  }
}
```

This deployment pulls all of the nupkg files from the directory `c:\ChocolateyPackages` and pushes each  package to the internal repository.
