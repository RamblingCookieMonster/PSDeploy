Deploy Test {
    By noop somenoop {
        FromSource Modules
        To C:\PSDeployTo
        DependingOn Test-randomtask #yeah, this is more of an integration test...
    }
    By task randomtask {
        FromSource 'Tests\artifacts\Tasks\testtask.ps1'
    }
}
