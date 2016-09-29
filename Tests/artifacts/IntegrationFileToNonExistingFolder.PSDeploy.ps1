Deploy FileToNonExistingFolder {
    By Filesystem File1 {
        FromSource Modules\File1.ps1
        To TestDrive:\Non\Existing\Folder\
        WithOptions @{
            Mirror = $False
        }
        Tagged Testing
    }
    
    By Filesystem File2 {
        FromSource Modules\File2.ps1
        To TestDrive:\Non\Existing\Folder\File2.ps1
        WithOptions @{
            Mirror = $False
        }
        Tagged Testing
    }
}