Deploy Misc {
    By noop {
        FromSource Modules
        To '\\contoso.org\share$\PowerShell\Modules'
        WithOptions @{
            Mirror = $False
            Making = 'stuff up'
            List   = 'What is going on!', 'hmm'
        }
    }
}