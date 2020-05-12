# Deploy a module from a local path
Deploy PSDependModule {
    By AzureAutomationModule {
        FromSource ".\PSDepend"
        To "AAName"
        WithOptions @{
            ModuleName         = "PSDepend"
            # ModuleVersion      = '0.3.0'
            ResourceGroupName  = "AAResourceGroupName"
            StorageAccountName = "aadeploymentstor"
            # Force              = $true
        }
    }
}
