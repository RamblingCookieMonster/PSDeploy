# Dependencies
Dependencies in PSDeploy are simply an option to help you determine the order of deployments.
Perhaps you want to deploy infrastructure before deploying the services running over them, or deploy a node before deploying a file to it.

First, let's look at the typical order of operations:

```powershell
Deploy A {
    By FileSystem Two {
        FromSource MyModule
        To C:\PSDeployTo
    }

    By FileSystem Three {
        FromSource MyModule
        To C:\PSDeployTo
    }
}

Deploy B {
    By FileSystem One {
        FromSource MyModule
        To C:\PSDeployTo
    }
}
```

```powershell
Get-PSDeployment -Path C:\PSDeployFrom\Deployments\my.psdeploy.ps1 |
    Select-Object -ExpandProperty DeploymentName

A-Two
A-Three
One
```

PSDeploy processes items in the order that it reads them.
But, you might have a reason to alter this behavior.
We can use the DependingOn function for this.
It takes one or more DeploymentNames to depend on.

Keep in mind that a DeploymentName will be in the format DeploymentName-ByName if you name a By block

```powershell
Deploy A {
    By FileSystem Two {
        FromSource MyModule
        To C:\PSDeployTo
        DependingOn One
    }

    By FileSystem Three {
        FromSource MyModule
        To C:\PSDeployTo
        DependingOn Two
    }
}

Deploy B {
    By FileSystem One {
        FromSource MyModule
        To C:\PSDeployTo
    }
}
```

```powershell
Get-PSDeployment -Path C:\PSDeployFrom\Deployments\my.psdeploy.ps1 |
    Select-Object -ExpandProperty DeploymentName
    
One
A-Two
A-Three
```

`Invoke-PSDeploy` will respect these dependencies.


Note: Developers out there... I borrowed [a topological sort](https://github.com/RamblingCookieMonster/PSDeploy/blob/master/PSDeploy/Private/Sort-WithCustomList.ps1) from stackoverflow. It seemed to work with everything I threw at it, but if you spot any issues, pull requests would be welcome!