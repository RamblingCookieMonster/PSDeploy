Deploy Git {
    By GitModule Git {
        FromSource 'D:\GitHub\PSDummy'
        To 'Master'
        Tagged 'Prod'
        WithOptions @{
            CommitMessage = 'Automatically commited by PSDeploy'
            Tag = 'v1.0.0'
        }
    }
}