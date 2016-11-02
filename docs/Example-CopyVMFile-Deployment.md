This is a quick example showing a CopyVMFile deployment. 
PSDeploy can be used to deploy artifacts on the VM running on top of Hyper-V host running Server 2012 R2 and above using this deployment type :

In this example, we are running the PSDeploy on the Hyper-V host running VM named 'WDS' and we need to deploy a InstallScript and few required files which this script reads to the VM.
Here's the deployment config, CopyFilesToVM.PSDeploy.ps1:

```PowerShell
Deploy CopyFilestoVM {

    By CopyVMFile InstallScript {
        FromSource 'InstallScript.ps1'
        To 'C:\PSDeployTo'
        Tagged Dev
        WithOptions @{
            Name = 'WDS'
            FileSource = 'Host'
            CreateFullPath = $true
        }
    }

    By CopyVMFile RequiredFilesFromAFolder {
        FromSource 'DummyFolder'
        To 'C:\PSDeployTo'
        Tagged Prod, Module
           WithOptions @{
            Name = 'WDS'
            FileSource = 'Host'
            CreateFullPath = $true
        }
    }
}
```

Here are the source files:

[![Source](images/copyVMfile1.png)](images/copyVMfile1.png)

We run `Invoke-PSDeploy` from C:\PSDeployFrom, and deployments ask for confirmation and it runs as expected:

[![Source](images/copyVMfile2.png)](images/copyVMfile2.png)

We can verify on the VM named 'WDS' that the required files were deployed.

[![Source](images/copyVMfile3.png)](images/copyVMfile3.png)
