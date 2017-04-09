Deploy Files {
    By FilesystemRemote {
        FromSource 'C:\Nope\Modules\File1.ps1'
        To '\\contoso.org\share$\PowerShell\'
        WithOptions @{
            SourceIsAbsolute = $true
        }
    }
}
