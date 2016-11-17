This is a quick example showing a PSDirect deployment. 

PSDeploy can be used to deploy artifacts on the VM running on top of Hyper-V host.
Note the below OS & Configuration requirements for both Hyper-V host and VM.

- Operating system requirements:
    - Host: Windows 10, Windows Server Technical Preview 2, or later running Hyper-V.
    - Guest/Virtual Machine: Windows 10, Windows Server Technical Preview 2, or later.

- Configuration requirements:
    - The virtual machine must be running locally on the host.
    - The virtual machine must be turned on and running with at least one configured user profile.
    - You must be logged into the host computer as a Hyper-V administrator.
    - You must supply valid user credentials for the virtual machine.

In this example, we are running the PSDeploy on the Hyper-V host running VM named 'WDS' and we need to deploy a InstallScript and 
a folder to the VM (preserves folder structure). See below the structure:

```
PS C:\PSDeployFrom> tree /F
Folder PATH listing
Volume serial number is 00000064 C422:0C79
C:.
│   InstallScript.ps1
│   PSDirect.psdeploy.ps1
│
└───DummyFolder
    │   Dummy.txt
    │
    └───DummyNestedFolder
            DummyNested.txt

```

Here's the deployment config (PSDirect.psdeploy.ps1):

```powershell
Deploy DeploymentToServer2016VM {
    $Credential = Get-Credential # Credentials used to connect to VM
    By PSDirect InstallScript {
        FromSource 'InstallScript.ps1'
        To 'C:\PSDeployTo'
        Tagged Dev
        WithOptions @{
            VMName = 'Server2016'
            Credential = $Credential
            Force = $True
        }
    }

    By PSDirect PreserveFolderStructure {
        FromSource 'DummyFolder'
        To 'C:\PSDeployTo'
           WithOptions @{
            VMName = 'Server2016'
            Credential = $Credential
            Container = $true
            Force = $true
            Recurse = $true
        }
    }
}
```

Below is an animated gif showing this in action:
1. Run `Get-VM` to verify that the VM is up and running. 
2. We run `Invoke-PSDeploy` from C:\PSDeployFrom.
3. Later connect to the VM using PSDirect and verify that artifacts were deployed.

[![Source](images/PSDirect.gif)](images/PSDirect.gif)

