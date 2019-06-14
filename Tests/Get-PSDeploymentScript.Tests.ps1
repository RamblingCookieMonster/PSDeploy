if(-not $ENV:BHProjectPath)
{
    Set-BuildEnvironment -Path $PSScriptRoot\.. -Force
}
Remove-Module $ENV:BHProjectName -ErrorAction SilentlyContinue
Import-Module (Join-Path $ENV:BHProjectPath $ENV:BHProjectName) -Force


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

        Context 'Deployment Script should be looked up in PSDeploy.yml path' {
            $TestPath = Join-Path -Path 'TestDrive:\' -ChildPath 'PSDeploy.yml'
            $FakeYml | Out-File -FilePath $TestPath -Force
            $ScriptParentPath = Join-Path -Path 'TestDrive:\' -ChildPath 'PSDeployScripts'
            $ScriptPath = Join-Path -Path $ScriptParentPath -ChildPath 'FakePlatyPS.ps1'
            New-Item -Path $ScriptParentPath -ItemType Directory > $null
            $FakeScript = @'
[CmdletBinding()]
Param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [PSObject[]]$Deployment,

    [Parameter(Mandatory=$true)]
    [System.String]
    $Option1,

    [System.String]
    $Option2,
)
'@
            $FakeScript | Out-File -FilePath $ScriptPath -Force

            $DeploymentScripts = Get-PSDeploymentScript -Path $TestPath @Verbose
            It 'Should have returned only 1 script' {
                $DeploymentScripts.Count | Should -Be 1
            }

            foreach ($DeploymentScript in $DeploymentScripts.GetEnumerator())
            {
                It "[$($DeploymentScript.Name)] should point to custom dir" {
                    $DeploymentScript.value | Should -Be (Get-Item -Path $ScriptPath).FullName
                }
            }
        }

        Context 'Deployment Script should favour module install path over PSDeploy.yml path' {
            $TestPath = Join-Path -Path 'TestDrive:\' -ChildPath 'PSDeploy.yml'
            $NewYml = @'
FileSystem:
  Script: FileSystem.ps1
  Description: Test description for filesystem
'@
            $NewYml | Out-File -FilePath $TestPath -Force
            $ScriptParentPath = Join-Path -Path 'TestDrive:\' -ChildPath 'PSDeployScripts'
            $ScriptPath = Join-Path -Path $ScriptParentPath -ChildPath 'FileSystem.ps1'
            New-Item -Path $ScriptParentPath -ItemType Directory > $null
            $FakeScript = @'
[CmdletBinding()]
Param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [PSObject[]]$Deployment,

    [Parameter(Mandatory=$true)]
    [System.String]
    $Option1,

    [System.String]
    $Option2,
)
'@
            $FakeScript | Out-File -FilePath $ScriptPath -Force

            $DeploymentScripts = Get-PSDeploymentScript -Path $TestPath @Verbose
            It 'Should have returned only 1 script' {
                $DeploymentScripts.Count | Should -Be 1
            }

            foreach ($DeploymentScript in $DeploymentScripts.GetEnumerator())
            {
                It "[$($DeploymentScript.Name)] Should use module path" {
                    $DeploymentScript.value | Should -Be ([System.IO.Path]::Combine($ProjectRoot, $ModuleName, 'PSDeployScripts', 'Filesystem.ps1'))
                }
            }
        }
    }
}
