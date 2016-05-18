# More to do. Ugly example. I don't like depending on AppVeyor specific env vars...
# TODO... find or write something that generalizes build system-specific variables.
    # Example, for build folder alone, on two build systems:
    # GitLab: $ENV:CI_PROJECT_DIR
    # AppVeyor: $ENV:APPVEYOR_BUILD_FOLDER
    # Jenkins: $ENV:WORKSPACE
    # Local builds: $PSScriptRoot...

# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
        $ProjectRoot = switch ((Get-ChildItem ENV:).Name)
        {
            'APPVEYOR_BUILD_FOLDER' { Get-Item -Path "ENV:$_"; break }
            'CI_PROJECT_DIR'        { Get-Item -Path "ENV:$_"; break }
            'WORKSPACE'             { Get-Item -Path "ENV:$_"; break } # Jenkins Jenkins... seems generic.
        }
        if(-not $ProjectRoot)
        {
            $ProjectRoot = $PSScriptRoot
        }

    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"

    # Verbose output for non-master builds on appveyor
    # Handy for troubleshooting. Splat @Verbose against commands as needed
    $Verbose = @{}
    if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
    {
        $Verbose.add("Verbose",$True)
    }
}

Task Default -Depends Deploy

Task Init {
    Set-Location $ProjectRoot
}

Task Clean {
    Remove-Item "$ProjectRoot\Destination\" -ErrorAction SilentlyContinue -Force -Recurse
}

Task Test -Depends Clean {
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $TestResults = Invoke-Pester @verbose -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile"

    # In Appveyor?  Upload our tests!
    If($env:APPVEYOR_JOB_ID)
    {
        (New-Object 'System.Net.WebClient').UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
            "$ProjectRoot\$TestFile" )
    }

    Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if($TestResults.FailedCount -gt 0)
    {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }

}

Task Deploy -Depends Test {

    # Gate on master branch, and !deploy keyword anywhere in the commit
    if(
        $env:APPVEYOR_REPO_BRANCH -like "master" -and
        (
            $env:APPVEYOR_REPO_COMMIT_MESSAGE -match '!deploy' -or
            $env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED -match '!deploy'
        )
    )
    {
        Invoke-PSDeploy -Path $ProjectRoot
    }
    else
    {
        "Skipping deployment: To deploy, ensure that...`n`t* You are committing to the master branch`n`t* Your commit message includes !deploy (anywhere)"
    }
}