# Deploy a module from a public repository
Deploy PSDependModule {
    By AzureAutomationModule {
        FromSource "https://www.powershellgallery.com/api/v2"
        To "AAName"
        WithOptions @{
            SourceIsAbsolute  = $true
            ModuleName        = "PSDepend"
            # ModuleVersion     = '0.3.0'
            ResourceGroupName = "AAResourceGroupName"
            # Force             = $true
        }
    }
}