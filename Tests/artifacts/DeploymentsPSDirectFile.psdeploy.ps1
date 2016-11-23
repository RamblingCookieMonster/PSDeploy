Deploy DeployToServer2016VM {

    By PSDirect DummyFile {
        FromSource 'Modules\File1.ps1'
        To 'TestDrive:\'
        WithOptions @{
            VMName = 'WDS'
            Credential = $(New-Object -TypeName PSCredential -ArgumentList 'Admin',(ConvertTo-SecureString -String 'pass123' -AsPlainText -Force))
        }
    }
}