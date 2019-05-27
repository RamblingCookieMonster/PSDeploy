# Azure Automation

## Prerequisites

This DeploymentType uses the [Az module](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az) to connect to Azure and deploy runbooks.
Because it's meant to run as part of a build pipeline, it requires a service principal to be created with a password (not certificate).

[Creating a Service Principal with the Az module](https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps)

[Creating a Service Principal with the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)

## Options

All options, except the CreateRunbook switch, are Mandatory

* **ResourceGroupName:** Resource Group to deploy runbook to
* **AutomationAccountName:** Automation Account to deploy runbook to
* **AzureServicePrincipalCredential:** Credential of Azure Service Principal, User is Application (client) ID, Password is Secret string / Application Password
* **AzureTenantID:** Tenant ID of Service Principal
* **RunbookType:** Type of runbook being deployed, one of "PowerShell", "GraphicalPowerShell", "PowerShellWorkflow", "GraphicalPowerShellWorkflow", "Python2"
* **CreateRunbook:** Boolean, if true, will create runbook if it doesn't already exist, otherwise runbook must already exist

## Examples

```Powershell
Deploy ExampleDeployment {
    By AzureAutomation {
        $cred = Get-Credential
        FromSource Runbook.ps1
        To AzureAutomation
        WithOptions @{
            ResourceGroupName = "examplegroup"
            AutomationAccountName = "example-account"
            AzureServicePrincipalCredential = $cred
            AzureTenantID = "6b3607b4-375b-447f-9fa1-34e452e1a91b"
            RunbookType = "PowerShell"
        }
    }
}
```

Because each runbook requires a runbook type, FromSource can only be an individual script, not a whole directory.
The To will always be AzureAutomation.
This example gets the login credentials interactively, to use this in a pipeline you would need to generate the credential object another way.
