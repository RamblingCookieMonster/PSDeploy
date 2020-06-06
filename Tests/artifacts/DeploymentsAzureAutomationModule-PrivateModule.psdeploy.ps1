# Deploy a module from a private repository
Deploy PrivateModule {
    By AzureAutomationModule {
        FromSource "https://pkgs.dev.azure.com/ORGANIZATION_NAME/PROJECT_NAME/_packaging/FEED_NAME/nuget/v2"
        To "AAName"
        WithOptions @{
            SourceIsAbsolute   = $true
            ModuleName         = "PrivateModule"
            # ModuleVersion     = '0.0.4'
            Force              = $true
            ResourceGroupName  = "AAResourceGroupName"
            StorageAccountName = "aadeploymentstor"
            Credential         = $script:credential
        }
        WithPreScript {
            $user = 'user@contoso.com'
            $password = ConvertTo-SecureString 'PAT_TOKEN' -AsPlainText -Force # PAT with permissions to read from the Artifacts feed
            $script:credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $user, $password
        }
    }
}
