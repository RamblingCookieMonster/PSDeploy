Deploy {
    By noop Misc {
        FromSource Modules
        To \\contoso.org\share$\PowerShell
        WithPreScript {"Setting things up for a deployment..."}
        WithPostScript {"Tearing things down from a deployment..."}
    }
}
