Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\PSDeploy\PSDeploy.psd1
Set-BuildEnvironment -Path $PSScriptRoot\..


InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath
    $ModuleName = $ENV:BHProjectName

    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$True)
    }

    $FakeYml = @"
PlatyPS:
  Script: FakePlatyPS.ps1
  Description: Builds External Help files using PlatyPS markdown and Deploys them to Module Help directory.
"@


    Describe "Get-PSDeploymentScript PS$PSVersion" {
        $DeploymentScripts = Get-PSDeploymentScript @Verbose        

        Context 'Deployment Scripts Should return valid paths' {

            foreach ($DeploymentScript in $DeploymentScripts.GetEnumerator())
            {
                It "[$($DeploymentScript.Name)] Should Exist" {
                    $Results = Test-Path $DeploymentScript.value
                    $Results | Should be $True
                }
            }
        }

        Context 'Deployment Script does not Exist' {
            $TestPath = Join-Path -Path 'TestDrive:\' -ChildPath 'PSDeploy.yml'
            $FakeYml | Out-File -FilePath $TestPath -Force            

            It "[$($TestPath)] Should Throw" {
                $Results = { Get-PSDeploymentScript -Path $TestPath @Verbose -ErrorAction Stop }
                $Results | Should Throw
            }
        }

        Context 'Should have equal Counts' {

            It "Should have same number of Deployment Scripts as valid paths [Count $($DeploymentScripts.count)]" {
                $ScriptTypes = Get-ChildItem -Path $ProjectRoot\$ModuleName\PSDeployScripts
                $DeploymentScripts.count | Should be $ScriptTypes.count
            }
        }
    }
}