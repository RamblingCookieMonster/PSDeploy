# Deploy an Azure Automation runbook
Deploy New-Runbook {
    By AzureAutomationRunbook {
        FromSource "\Scripts\Get-RandomGuid.ps1"
        To "AAName"
        WithOptions @{
            RunbookName       = "Get-RandomGuid"
            ResourceGroupName = "AAResourceGroup"
            Force             = $true
        }
    }
}