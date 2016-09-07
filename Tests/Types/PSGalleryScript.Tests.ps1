Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1
Set-BuildEnvironment -Path $PSScriptRoot\..\..


InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath
    
    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$True)
    }

    Describe "PSGalleryScript PS$PSVersion" {

        Context 'Publishes Script' {
            Mock Publish-Script { Return $true }
            Mock Get-PSRepository { Return $true }
            Mock Find-Script { }
            Mock Set-Content { }

            $Results = Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsPSGalleryScript.psdeploy.ps1" -Force

            It 'Should execute Set-Content' {
                Assert-MockCalled Set-Content -Times 1 -Exactly
            }

            It 'Should execute Publish-Module' {
                Assert-MockCalled Publish-Script -Times 1 -Exactly
            }

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }
        }

        Context 'Repository does not Exist' {
            Mock Publish-Script {}
            Mock Get-PSRepository { Return $false }
            Mock Find-Script { }
            Mock Set-Content { }

            It 'Throws because Repository could not be found' {
                $Results = { Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsPSGalleryScript.psdeploy.ps1" -Force }
                $Results | Should Throw
            }
        }
    }
}