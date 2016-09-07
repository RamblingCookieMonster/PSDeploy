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

    # Create a Dummy Hyper-V Module, to mock the Copy-VMfile cmdlet later
    $DummyModule = New-Module -Name Hyper-V  -Function "Copy-VMFile" -ScriptBlock {  Function Copy-VMFile { Write-Host "Invoking Copy-VMFile -> $Args"}; }
    $DummyModule | Import-Module

    Describe "CopyVMFile PS$PSVersion" {                     
        
        Context 'Deploy File to VM' {
            Mock Copy-VMFile { Return $True }

            $Deployment = Get-PSDeployment @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsCopyVMFile.yml"
            $Results = Invoke-PSDeployment -Deployment $Deployment @Verbose -Force

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }

            It 'Should copy file to VM' {                                
                Assert-MockCalled Copy-VMfile -Times 1 -Exactly
            }
        }

        Context 'Deploy Folder to VM' {
            Mock Copy-VMFile { Return $True }

            $Deployment = Get-PSDeployment @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsCopyVMFolder.yml"
            $Results = Invoke-PSDeployment -Deployment $Deployment @Verbose -Force

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }

            It 'Should copy folder to VM' {                
                $TotalFiles = Get-Childitem -Path $Deployment.Source -File -Recurse
                
                # Moved Each test to their own Context blocks so their Mock counts are reset.
                Assert-MockCalled Copy-VMfile -Times $TotalFiles.Count -Exactly
            }
        }
    }
}