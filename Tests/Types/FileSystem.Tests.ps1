Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1
if(-not $ENV:BHProjectPath)
{
    Set-BuildEnvironment -Path $PSScriptRoot\..\.. -Force
}

InModuleScope 'PSDeploy' {
    $ProjectRoot = $ENV:BHProjectPath

    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$True)
    } 

    Describe "FileSystem: Single File Deployment tests"{
        $IntegrationTarget = "TestDrive:\"

        Context 'Deploying File with ps1' {
            Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\IntegrationFile.PSDeploy.ps1" -Force

            It 'Should deploy file1.ps1' {            
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -Childpath File1.ps1) 
                $Results | Should Be $True                
            }
        }

        Context 'Deploying File with ps1 to folder that does not exist' {
            Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\IntegrationFileToNonExistingFolder.PSDeploy.ps1" -Force

            It 'Should deploy file1.ps1' {
                $Results = Test-Path (Join-Path -Path "$($IntegrationTarget)Non\Existing\Folder\" -Childpath File1.ps1)
                $Results | Should Be $True
            }

            It 'Should deploy file2.ps1' {
                $Results = Test-Path (Join-Path -Path "$($IntegrationTarget)Non\Existing\Folder\" -Childpath File2.ps1)
                $Results | Should Be $True
            }
        }

        Context 'Handling paths with spaces' {
            Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeployPathWithSpaces.psdeploy.ps1" -Force

            It 'Should deploy path with spaces' {
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -ChildPath 'So Does This One\Has Spaces.txt')
                $Results | Should Be $True
            }
        }
    }
    Describe "FileSystem: Directory File Deployments"{
        $IntegrationTarget = "TestDrive:\"
        
        Context 'Deploying Folder with ps1' {
            Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\IntegrationFolder.PSDeploy.ps1" -Force

            It 'Should deploy File2.ps1' {                 
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -Childpath File2.ps1) 
                $Results | Should Be $True
            }

            It 'Should deploy "CrazyModule\A file.txt"' {
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -ChildPath 'CrazyModule\A file.txt') 
                $Results | Should Be $True                
            }
        }
    }
}