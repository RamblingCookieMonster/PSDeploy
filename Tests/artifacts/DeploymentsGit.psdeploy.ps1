Deploy Git {
    By GitModule Git {
        FromSource 'D:\GitHub\PSDummy'
        To 'Master'
        WithOptions @{
            CommitMessage = 'Automatically commited by PSDeploy'
        }
    }
}