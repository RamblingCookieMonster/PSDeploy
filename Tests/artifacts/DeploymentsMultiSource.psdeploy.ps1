Deploy Files {
    By FilesystemRemote {
        FromSource 'Modules\File1.ps1',
                   'Modules\File2.ps1',
                   'Modules\CrazyModule'
        To '\\contoso.org\share$\PowerShell\'
    }
}
