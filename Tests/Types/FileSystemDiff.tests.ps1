Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1
Set-BuildEnvironment -Path $PSScriptRoot   #\..\..

InModuleScope 'PSDeploy' {
    $ProjectRoot = $ENV:BHProjectPath
    #Make sure dest path does not exist
    Remove-Item $ENV:BHProjectPath\dest -Recurse -Force -ErrorAction SilentlyContinue


    Describe "Single File Deployment tests" {
        Context "Single Copy" {
            Invoke-PSDeploy -Path $ENV:BHProjectPath\..\Artifacts\FileSystemSingleDeploy.PSDeploy.ps1 -Force

            It "Test1 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt | Should Be $true
            }
            It "Test1 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt.hash | Should Be $true
            }
        }
        Context "Single Copy, destination present, no hash" {
            Remove-Item -Path $ENV:BHProjectPath\Dest\test1.txt.hash
            Invoke-PSDeploy -Path $ENV:BHProjectPath\..\Artifacts\FileSystemSingleDeploy.PSDeploy.ps1 -Force

            It "Test1 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt | Should Be $true
            }
            It "Test1 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt.hash | Should Be $true
            }
        }
        Context "Single Copy, destination present, matching hash" {
            Invoke-PSDeploy -Path $ENV:BHProjectPath\..\Artifacts\FileSystemSingleDeploy.PSDeploy.ps1 -Force

            It "Test1 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt | Should Be $true
            }
            It "Test1 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt.hash | Should Be $true
            }
        }
        Context "Single Copy, destination present, non-matching hash with SaveDiff" {
            "This is a test" | Add-Content -Path $ENV:BHProjectPath\Dest\test1.txt
            Invoke-PSDeploy -Path $ENV:BHProjectPath\..\Artifacts\FileSystemSingleDeploy.PSDeploy.ps1 -Force

            It "Test1 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt | Should Be $true
            }
            It "Test1 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt.hash | Should Be $true
            }
            It "Test1 Saved file present" {
                Test-Path $ENV:BHProjectPath\dest\test1-*.txt | Should Be $true
            }
        }
    }

    Describe "Directory File Deployments" {
        Context "Folder Copy, destination not present" {
            Remove-Item $ENV:BHProjectPath\dest -Recurse -Force -ErrorAction SilentlyContinue
            Invoke-PSDeploy -Path $ENV:BHProjectPath\..\Artifacts\FileSystemFolderDeploy.PSDeploy.ps1 -Force

            It "Test1 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt | Should Be $true
            }
            It "Test2 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test2.txt | Should Be $true
            }
            It "Test1 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt.hash | Should Be $true
            }
            It "Test2 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test2.txt.hash | Should Be $true
            }
        }
        Context "Folder Copy, destination present, no hash" {
            Remove-Item $ENV:BHProjectPath\dest\*.hash -Force -ErrorAction SilentlyContinue
            Invoke-PSDeploy -Path $ENV:BHProjectPath\..\Artifacts\FileSystemFolderDeploy.PSDeploy.ps1 -Force

            It "Test1 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt | Should Be $true
            }
            It "Test2 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test2.txt | Should Be $true
            }
            It "Test1 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt.hash | Should Be $true
            }
            It "Test2 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test2.txt.hash | Should Be $true
            }
        }
        Context "Folder Copy, destination present, matching hash" {
            Invoke-PSDeploy -Path $ENV:BHProjectPath\..\Artifacts\FileSystemFolderDeploy.PSDeploy.ps1 -Force

            It "Test1 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt | Should Be $true
            }
            It "Test2 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test2.txt | Should Be $true
            }
            It "Test1 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt.hash | Should Be $true
            }
            It "Test2 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test2.txt.hash | Should Be $true
            }
        }
        Context "Folder Copy, destination present, non-matching hash" {
            "This is a test" | Add-Content -Path $ENV:BHProjectPath\Dest\test1.txt
            "This is a test" | Add-Content -Path $ENV:BHProjectPath\Dest\test2.txt
            Invoke-PSDeploy -Path $ENV:BHProjectPath\..\Artifacts\FileSystemFolderDeploy.PSDeploy.ps1 -Force

            It "Test1 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt | Should Be $true
            }
            It "Test2 Present" {
                Test-Path $ENV:BHProjectPath\Dest\test2.txt | Should Be $true
            }
            It "Test1 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test1.txt.hash | Should Be $true
            }
            It "Test2 Hash Present" {
                Test-Path $ENV:BHProjectPath\Dest\test2.txt.hash | Should Be $true
            }
            It "Test1 Saved file present" {
                Test-Path $ENV:BHProjectPath\dest\test1-*.txt | Should Be $true
            }
            It "Test2 Saved file present" {
                Test-Path $ENV:BHProjectPath\dest\test2-*.txt | Should Be $true
            }
        }
    }
}

#Final cleanup
Remove-Item $ENV:BHProjectPath\dest -Recurse -Force -ErrorAction SilentlyContinue