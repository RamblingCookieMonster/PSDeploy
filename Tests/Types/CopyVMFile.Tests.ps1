Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1
if(-not $ENV:BHProjectPath)
{
    Set-BuildEnvironment -Path $PSScriptRoot\..\.. -Force
}

InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath
    
    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$False)
    }

    # Create a Dummy Hyper-V Module, to mock the Copy-VMfile cmdlet later
    Function Copy-VMFile { param($Name,$sourcePath,$DestinationPath,$FileSource) }

    Describe "CopyVMFile PS$PSVersion" {                     
        
        Context 'Deploy File to VM (using the YML)' {
            # Copy-VMFile has the 4 mandatory params, added now to the parameter filter
            Mock Copy-VMFile -MockWith { Return $True } -ParameterFilter { ($null -ne $name) -and ($null -ne $sourcePath) -and ($null -ne $DestinationPath) -and ($null -ne $fileSource)}
 
            $Deployment = Get-PSDeployment @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsCopyVMFile.yml"
            $Results = Invoke-PSDeployment -Deployment $Deployment @Verbose -Force

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }

            It 'Should copy file to VM' {                                
                Assert-MockCalled Copy-VMfile -Times 1 -Exactly -Scope Context
            }
        }

        Context 'Deploy Folder to VM (using the YML)' {
            Mock Copy-VMFile -MockWith { Return $True } -Verifiable  -ParameterFilter { ($null -ne $name) -and ($null -ne $sourcePath) -and ($null -ne $DestinationPath) -and ($null -ne $fileSource) }

            $Deployment = Get-PSDeployment @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsCopyVMFolder.yml"
            $Results = Invoke-PSDeployment -Deployment $Deployment @Verbose -Force

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }

            It 'Should copy folder to VM' {                
                $TotalFiles = Get-Childitem -Path $Deployment.Source -File -Recurse
                
                # Moved Each test to their own Context blocks so their Mock counts are reset.
                Assert-MockCalled Copy-VMfile -Times $TotalFiles.Count -Exactly -Scope Context
            }
        }

        Context 'Deploy Folder to VM (using the DSL)' {
            Mock Copy-VMFile -MockWith { Return $True } -Verifiable  -ParameterFilter { ($null -ne $name) -and ($null -ne $sourcePath) -and ($null -ne $DestinationPath) -and ($null -ne $fileSource) }
            $Deployment = Get-PSDeployment @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsCopyVMFolder.psdeploy.ps1"
            $Results = Invoke-PSDeploy -Path "$ProjectRoot\Tests\artifacts\DeploymentsCopyVMFolder.psdeploy.ps1" -Force @verbose

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }

            It 'Should copy folder to VM' {                
                $TotalFiles = Get-Childitem -Path $Deployment.Source -File -Recurse
                
                # Moved Each test to their own Context blocks so their Mock counts are reset.
                Assert-MockCalled Copy-VMfile -Times $TotalFiles.Count -Exactly -Scope Context
            }
        }

        Context 'Deploy File to VM (usng the DSL)'  {
            # Copy-VMFile has the 4 mandatory params, added now to the parameter filter
            Mock Copy-VMFile -MockWith { Return $True } -Verifiable  -ParameterFilter { ($null -ne $name) -and ($null -ne $sourcePath) -and ($null -ne $DestinationPath) -and ($null -ne $fileSource) }
            $Deployment = Get-PSDeployment @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsCopyVMFile.psdeploy.ps1"
            $Results = Invoke-PSDeploy -Path "$ProjectRoot\Tests\artifacts\DeploymentsCopyVMFile.psdeploy.ps1" -Force @Verbose

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }

            It 'Should copy file to VM' {                                
                Assert-MockCalled Copy-VMfile -Times 1 -Exactly -Scope Context
            }
        }

    }
}