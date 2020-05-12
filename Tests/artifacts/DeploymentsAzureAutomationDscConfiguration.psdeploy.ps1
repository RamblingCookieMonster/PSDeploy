# Deploy a DSC configuration
Deploy hybridWorkerConfiguration {
    By AzureAutomationDscConfiguration {
        FromSource "\Scripts\MMAConfiguration.ps1"
        To "AAName"
        WithOptions @{
            ResourceGroupName = "AAResourceGroup"
            Published         = $true
            Force             = $true
            Compile           = $true
            ConfigurationData = @{
                # Node specific data
                AllNodes = @(
                    @{
                         NodeName = "localhost";
                     }
                 );
            }
        }
    }
}