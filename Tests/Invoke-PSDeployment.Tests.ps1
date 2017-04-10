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

        Context 'Deploying File with yml' {
            Invoke-PSDeployment @Verbose -Path $FileYML -Force

            It 'Should deploy file1.ps1' {            
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -Childpath File1.ps1) 
                $Results | Should Be $True                
            }
        }

        Context 'Deploying Folder with yml' {
            Invoke-PSDeployment @Verbose -Path $FolderYML -Force

            It 'Should deploy File2.ps1' {                 
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -Childpath File2.ps1) 
                $Results | Should Be $True
            }

            It 'Should deploy "CrazyModule\A file.txt"' {
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -ChildPath 'CrazyModule\A file.txt') 
                $Results | Should Be $True                
            }
        }

        Context 'Mirror Folder' {
            $FolderToDelete = Join-Path -Path $IntegrationTarget -ChildPath 'DeleteThisFolder'
            $FileToDelete = Join-Path -Path $IntegrationTarget -ChildPath 'DeleteThisFile'
            New-Item -ItemType Directory -Path $FolderToDelete
            New-Item -ItemType File -Path $FileToDelete
            
            Invoke-PSDeployment @Verbose -Path $FolderYML -Force

            It 'Should deploy File2.ps1' {                                        
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -ChildPath File2.ps1) 
                $Results | Should Be $True
            }

            It 'Should deploy "CrazyModule\A file.txt"' {
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -ChildPath 'CrazyModule\A file.txt') 
                $Results | Should Be $True
            }

            It 'Should Delete Folder' {
                $Results = Test-Path $FolderToDelete 
                $Results | Should Be $False
            }

            It 'Should Delete File' {
                $Results = Test-Path $FolderToDelete 
                $Results | Should Be $False
            }            
        }

        Context 'Pipeline Input' {            
            # Look into Mocking Get-PSDeployment Output
            Get-PSDeployment @Verbose -Path $FileYML | Invoke-PSDeployment @Verbose -force

            It 'Should accept pipeline input' {                
                $Results = Test-Path (Join-Path -Path $IntegrationTarget -ChildPath File1.ps1) 
                $Results | Should Be $True
            }            
        }
    }
}