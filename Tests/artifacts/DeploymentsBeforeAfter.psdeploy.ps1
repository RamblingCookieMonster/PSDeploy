Deploy {
    By noop Misc {
        FromSource Modules
        To \\contoso.org\share$\PowerShell
        Tagged False
        WithPreScript {"Setting things up for a deployment..."}
        WithPostScript {"Tearing things down from a deployment..."}
    }

    By noop Misc {
        FromSource Modules
        To \\contoso.org\share$\PowerShell
        Tagged True
        WithPreScript {
            "Setting things up for a deployment..."
        } -SkipOnError
        WithPostScript {"Tearing things down from a deployment..."}
    }
}
