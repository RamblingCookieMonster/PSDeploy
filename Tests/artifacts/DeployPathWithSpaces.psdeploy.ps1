Deploy Folder {
    By Filesystem {
        FromSource 'Modules\This Path\'
        To 'TestDrive:\So Does This One\'
        WithOptions @{
            Mirror = $False
        }
        Tagged Testing
    }
}