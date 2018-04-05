if($PSVersionTable.ContainsKey('Platform') -and ($PSVersionTable['Platform'] -ne 'Win32NT')){
    $FromSource = '/mnt/c/Nope/Modules/File1.ps1'
} else {
    $FromSource = 'C:\Nope\Modules\File1.ps1'
}
Deploy Files {
    By FilesystemRemote {
        FromSource $FromSource
        To '\\contoso.org\share$\PowerShell\'
        WithOptions @{
            SourceIsAbsolute = $true
        }
    }
}
