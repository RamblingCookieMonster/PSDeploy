# Example: FileSystem Remote Deployment
This is an example script you might call from Jenkins, illustrating the FilesystemRemote deployment type.
You should ideally gate deployments with Pester and ScriptAnalyzer, among other options.

Some.PSDeploy.ps1 has FilesystemRemote deployments, which deploys from a remote session (consider the double hop implications):

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

This is an example script you might use to invoke the deployment, after running your tests

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