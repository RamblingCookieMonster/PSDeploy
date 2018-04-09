if(-not $ENV:BHProjectPath)
{
    Set-BuildEnvironment -Path $PSScriptRoot\.. -Force
}
Remove-Module $ENV:BHProjectName -ErrorAction SilentlyContinue
Import-Module (Join-Path $ENV:BHProjectPath $ENV:BHProjectName) -Force

InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath
    
    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$True)
    }        

    Describe "Invoke-PSDeployment PS$PSVersion" {                
        $IntegrationTarget = "TestDrive:\"
        $FileYML = "$ProjectRoot\Tests\artifacts\IntegrationFile.yml"
        $FolderYML = "$ProjectRoot\Tests\artifacts\IntegrationFolder.yml"

        Context 'Accept yml config' {
            $NoopOutput = Invoke-PSDeployment @Verbose -Path $FileYML -Force

            It 'Should resolve source' {            
                $NoopOutput.Deployment[0].Source | Should Be (Join-Path -Path $ProjectRoot -ChildPath 'Tests\artifacts\Modules\File1.ps1')
            }
            It 'Should resolve Targets' {            
                $NoopOutput.Deployment[0].Targets | Should Be "TestDrive:\"
            }
            It 'Should resolve DeploymentOptions' {            
                $NoopOutput.Deployment[0].DeploymentOptions | Should Not BeNullOrEmpty
                $NoopOutput.Deployment[0].DeploymentOptions.Mirror | Should Be 'False'
            }
        }

        Context 'Pipeline Input' {
            # Look into Mocking Get-PSDeployment Output
            $NoopOutput = Get-PSDeployment @Verbose -Path $FileYML | Invoke-PSDeployment @Verbose -force

            It 'Should resolve source' {            
                $NoopOutput.Deployment[0].Source | Should Be (Join-Path -Path $ProjectRoot -ChildPath 'Tests\artifacts\Modules\File1.ps1')
            }
            It 'Should resolve Targets' {            
                $NoopOutput.Deployment[0].Targets | Should Be "TestDrive:\"
            }
            It 'Should resolve DeploymentOptions' {            
                $NoopOutput.Deployment[0].DeploymentOptions | Should Not BeNullOrEmpty
                $NoopOutput.Deployment[0].DeploymentOptions.Mirror | Should Be 'False'
            }           
        }
    }
}