Deploy DeployToServer2016VM {

    By PSDirect DummyFolder {
        FromSource 'Modules'
        To 'TestDrive:\'
        WithOptions @{
            VMName = 'WDS'
            Credential = $(New-Object -TypeName PSCredential -ArgumentList 'Admin',(ConvertTo-SecureString -String 'pass123' -AsPlainText -Force))
            Container = $true
            Recurse = $true
            Force = $true
        }
    }
}