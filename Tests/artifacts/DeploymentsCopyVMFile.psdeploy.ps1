Deploy CopyVMFileExampleDeployment {

    By CopyVMFile TestFile {
        FromSource 'Modules\File1.ps1'
        To 'TestDrive:\'
        WithOptions @{
            Name = 'WDS'
            FileSource = 'Host'
        }
    }
}