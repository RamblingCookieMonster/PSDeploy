Deploy Folder {
    By Filesystem {
        FromSource 'Modules\This Path\'
        To TestDrive:\
        WithOptions @{
            Mirror = $False
        }
        Tagged Testing
    }
}