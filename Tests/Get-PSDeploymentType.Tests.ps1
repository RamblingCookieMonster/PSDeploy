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

    Describe "Get-PSDeploymentType PS$PSVersion" {    
        $DeploymentTypes = Get-PSDeploymentType @Verbose        
        $ScriptTypes = Get-ChildItem -Path $ProjectRoot\$ModuleName\PSDeployScripts

        Context 'Deployment Types Should return valid paths' {

            foreach ($DeploymentType in $DeploymentTypes.GetEnumerator())
            {
                It "[$($DeploymentType.DeploymentScript)] Should Exist" {
                    $Results = Test-Path $DeploymentType.DeploymentScript
                    $Results | Should be $True
                }
            }
        }

        Context 'Deployment Types Should have Description' {

            foreach ($DeploymentType in $DeploymentTypes.GetEnumerator())
            {
                It "[$($DeploymentType.DeploymentType)] Should have a Description" {
                    $DeploymentType.Description | Should Not BeNullOrEmpty
                }
            }
        }

        Context 'Deployment Types Should have Help' {

            foreach ($DeploymentType in $DeploymentTypes.GetEnumerator())
            {
                It "[$($DeploymentType.DeploymentType)] Should show help" {
                    $Results = Get-PSDeploymentType -DeploymentType $DeploymentType.DeploymentType -ShowHelp @Verbose
                    $Results | Should match 'SYNOPSIS'
                }
            }
        }

        Context 'Deployment Scripts should have Matching Deployment Types' {

            foreach ($Type in $ScriptTypes)
            {
                It "[$($Type.Name)] should have Deployment Type" {
                    $Results = $DeploymentTypes.DeploymentType -contains $Type.BaseName
                    $Results | Should Be $True
                }

                It "[$($Type.Name)] should have Matching Deployment Type Path" {
                    $Results = $DeploymentTypes.DeploymentScript -contains $Type.FullName
                    $Results | Should Be $True
                }
            }
        }

        Context 'Should have equal counts' {

            It "Should have same number of Deployment Types as valid paths [Count $($DeploymentTypes.count)]" {
                $DeploymentTypes.Count | Should Be $ScriptTypes.count                        
            }
        }
    }

    Describe "Get-PSDeploymentType -Path PS$PSVersion" {
        # We aren't testing Get-Help and it takes time to run so just mock it out for this block
        Mock Get-Help { return "" }

        $TestPath = Join-Path -Path 'TestDrive:\' -ChildPath 'PSDeploy.yml'
        $NewYml = @'
FileSystem:
  Script: FileSystem.ps1
  Description: Test description for filesystem

CustomType:
  Script: CustomType.ps1
  Description: Test description for custom type
'@
        $NewYml | Out-File -FilePath $TestPath -Force
        $ScriptParentPath = Join-Path -Path 'TestDrive:\' -ChildPath 'PSDeployScripts'
        $FSScriptPath = Join-Path -Path $ScriptParentPath -ChildPath 'FileSystem.ps1'
        $CustomScriptPath = Join-Path -Path $ScriptParentPath -ChildPath 'CustomType.ps1'

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
        $FakeScript | Out-File -FilePath $FSScriptPath -Force
        $FakeScript | Out-File -FilePath $CustomScriptPath -Force

        $DeploymentTypes = Get-PSDeploymentType -Path $TestPath @Verbose

        It 'Deployment Types should only have 2 entries' {
            $DeploymentTypes.Count | Should -Be 2
        }

        Context 'Deployment Types Should return valid paths' {

            foreach ($DeploymentType in $DeploymentTypes.GetEnumerator())
            {
                It "[$($DeploymentType.DeploymentScript)] Should Exist" {
                    $Results = Test-Path $DeploymentType.DeploymentScript
                    $Results | Should be $True
                }

                if ($DeploymentType.DeploymentType -eq 'FileSystem') {
                    It "[$($DeploymentType.DeploymentType)] Should be in module path" {
                        $DeploymentType.DeploymentScript | Should -Be ([System.IO.Path]::Combine($ProjectRoot, $ModuleName, 'PSDeployScripts', 'FileSystem.ps1'))
                    }
                } else {
                    It "[$($DeploymentType.DeploymentType)] Should be in custom path" {
                        $DeploymentType.DeploymentScript | Should -Be (Get-Item -Path $CustomScriptPath).FullName
                    }
                }
            }
        }

        Context 'Deployment Types Should have Description' {

            foreach ($DeploymentType in $DeploymentTypes.GetEnumerator())
            {
                It "[$($DeploymentType.DeploymentType)] Should have a Description" {
                    $DeploymentType.Description | Should Not BeNullOrEmpty
                }
            }
        }
    }
}
