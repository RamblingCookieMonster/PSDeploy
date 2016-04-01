Deploy {
    By FilesystemRemote Misc {
        FromSource Modules
        To \\contoso.org\share$\PowerShell
        Tagged Prod
    }

    By FilesystemRemote Files {
        FromSource Modules\File1.ps1,
                   Modules\File2.ps1
        To '\\contoso.org\share$\PowerShell\'
    }
}

Deploy {
    By Filesystem ActiveDirectory {
        FromSource Modules\CrazyModule
        To '\\contoso.org\share$\PowerShell\Modules\CrazyModule',
           '\\some.dev.pc.contoso.org\c$\sc\CrazyModule'
        WithOptions @{
            Mirror = $true
        }
    }
}
