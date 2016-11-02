Deploy CopyVMFolderExampleDeployment {

    By CopyVMFile TestFolder {
        FromSource 'Modules'
        To 'TestDrive:\'
        WithOptions @{
            Name = 'WDS'
            FileSource = 'Host'
            CreateFullPath = $True          
        }
    }
}