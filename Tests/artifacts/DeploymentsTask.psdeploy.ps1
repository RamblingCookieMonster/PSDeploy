Deploy LocalExample {
    By Task randomtask {
        "Running a task!"
    }
    By Task filecontent {
        FromSource .\Tasks\createfile.ps1
    }
}
Deploy ARMExample {
    By Task login {
        FromSource .\Tasks\armlogin.ps1
        Tagged 'Before'
        WithOptions @{
            SubscriptionID = 'YOURSUBSCRIPTIONID'
            Tenant = 'YOURTENANTID'
            Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist 'YOURSPNID', ('YOURSPNKEY' | ConvertTo-SecureString -AsPlainText -Force)
        }
    }
}