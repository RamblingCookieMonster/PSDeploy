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
}