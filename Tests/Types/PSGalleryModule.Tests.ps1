if(-not $ENV:BHProjectPath)
{
    Set-BuildEnvironment -Path $PSScriptRoot\..\.. -Force
}
Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1

InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath
    
    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$True)
    }

    Describe "PSGalleryModule PS$PSVersion" {

        Context 'Publishes Module' {
            Mock Publish-Module { Return $true }
            Mock Get-PSRepository { Return $true }
            
            $Results = Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsPSGalleryModule.psdeploy.ps1" -Force

            It 'Should execute Publish-Module' {
                Assert-MockCalled Publish-Module -Times 1 -Exactly
            }

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }
        }

        Context 'Repository does not Exist' {
            Mock Publish-Module {}
            Mock Get-PSRepository { Return $false }

            It 'Throws because Repository could not be found' {
                $Results = { Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsPSGalleryModule.psdeploy.ps1" -Force }
                $Results | Should Throw
            }
        }
    }
}