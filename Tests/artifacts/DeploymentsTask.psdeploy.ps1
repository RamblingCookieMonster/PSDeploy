Deploy LocalFileContentExample {
    By Task {
        FromSource .\Tasks\createfile.ps1
    }
}
Deploy ARMLoginExample {
    By Task {
        FromSource .\Tasks\loginazurerm.ps1
        WithOptions @{
            SubscriptionID = 'YOURSUBSCRIPTIONID'
            Tenant = 'YOURTENANTID'
            Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist 'YOURSPNID', ('YOURSPNKEY' | ConvertTo-SecureString -AsPlainText -Force)
        }
    }
}