$Verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
{
    $Verbose.add("Verbose",$True)
}

$PSVersion = $PSVersionTable.PSVersion.Major
Import-Module $PSScriptRoot\..\PSDeploy -Force

#Set up some data we will use in testing
    $IntegrationTarget = "$PSScriptRoot\Destination\"
    $FileYML = "$PSScriptRoot\IntegrationFile.yml"
    $FolderYML = "$PSScriptRoot\IntegrationFolder.yml"
    $WaitForFilesystem = .5

    Remove-Item -Path $IntegrationTarget -ErrorAction SilentlyContinue -Force -Recurse
    mkdir $IntegrationTarget | Out-Null

@"
Files:
  Author: 'wframe'
  Source:
    - 'Modules\File1.ps1'
  Destination:
    - '$IntegrationTarget'
  Deployment:
    Type: Filesystem
    Mirror: False
"@ | Out-File -FilePath $FileYML -force

@"
Files:
  Author: 'wframe'
  Source:
    - 'Modules'
  Destination:
    - '$IntegrationTarget'
  Deployment:
    Type: Filesystem
    Mirror: True
"@ | Out-File -FilePath $FolderYML -force

Describe "Get-PSDeploymentType PS$PSVersion" {

    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should get definitions' {
            $Definitions = @( Get-PSDeploymentType @Verbose )
            $Definitions.Count | Should Be 2
            $Definitions.DeploymentType -contains 'FileSystem' | Should Be $True
            $Definitions.DeploymentType -contains 'FileSystemRemote' | Should Be $True
        }

        It 'Should return valid paths' {
            $Definitions = Get-PSDeploymentType @Verbose
            foreach($path in $Definitions.DeploymentScript)
            {
                Test-Path $Path | Should Be $True
            }
        }

        It 'Should show help' {
            Get-PSDeploymentType -DeploymentType FileSystem -ShowHelp | Should match 'SYNOPSIS'
        }
    }
}

Describe "Get-PSDeploymentScript PS$PSVersion" {
    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should get definitions' {
            $Definitions = Get-PSDeploymentScript @Verbose
            $Definitions.Keys.Count | Should Be 2
            $Definitions.GetType().Name | Should Be 'Hashtable'
            $Definitions.ContainsKey('FileSystem') | Should Be $True
            $Definitions.ContainsKey('FileSystemRemote') | Should Be $True
        }

        It 'Should return valid paths' {
            $Definitions = Get-PSDeploymentScript @Verbose
            foreach($path in $Definitions.Values)
            {
                Test-Path $Path | Should Be $True
            }
        }
    }

}

Describe "Get-PSDeployment PS$PSVersion" {

    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Handles single deployments' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\DeploymentsSingle.yml )
            $Deployments.Count | Should Be 1
        }

        It 'Handles multiple source deployments' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\DeploymentsMultiSource.yml )
            $Deployments.Count | Should Be 3
        }

        It 'Handles multiple deployments' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\DeploymentsMulti.yml )
            $Deployments.Count | Should Be 4
        }

        It 'Returns a PSDeploy.Deployment object' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\DeploymentsSingle.yml )
            $Deployments[0].psobject.TypeNames[0] | Should Be 'PSDeploy.Deployment'
        }

        It 'Handles identifying source type' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\DeploymentsMultiSource.yml )
            $Deployments[0].SourceType | Should Be 'File'
            $Deployments[1].SourceType | Should Be 'File'
            $Deployments[2].SourceType | Should Be 'Directory'
        }

        It 'Should allow user-specified, properly formed JSON' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\DeploymentsRaw.yml )
            $Deployments.Count | Should Be 1
            $Deployments.Raw.Deployment.List.Count | Should be 2
            $Deployments.Raw.Deployment.Making | Should be "Stuff up"
        }
    }
}

Describe "Invoke-PSDeployment PS$PSVersion" {

    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should deploy a file' {
            Invoke-PSDeployment @Verbose -Path $FileYML -Force
            start-sleep -Seconds $WaitForFilesystem
            
            Test-Path (Join-Path $IntegrationTarget File1.ps1) | Should Be $True

        }

        It 'Should deploy a folder' {
            Invoke-PSDeployment @Verbose -Path $FolderYML -Force
            start-sleep -Seconds $WaitForFilesystem
            
            Test-Path (Join-Path $IntegrationTarget File2.ps1) | Should Be $True
            Test-Path (Join-Path $IntegrationTarget 'CrazyModule\A file.txt') | Should Be $True

            Remove-Item -Path $IntegrationTarget -Recurse -Force

        }

        It 'Should mirror a folder' {
            $FolderToDelete = Join-Path $IntegrationTarget 'DeleteThisFolder'
            $FileToDelete = Join-Path $IntegrationTarget 'DeleteThisFile'
            
            mkdir $FolderToDelete
            New-Item -ItemType File -Path $FileToDelete
            
            Invoke-PSDeployment @Verbose -Path $FolderYML -Force
            start-sleep -Seconds $WaitForFilesystem
            
            Test-Path (Join-Path $IntegrationTarget File2.ps1) | Should Be $True
            Test-Path (Join-Path $IntegrationTarget 'CrazyModule\A file.txt') | Should Be $True
            Test-Path $FolderToDelete | Should Be $False
            Test-Path $FolderToDelete | Should Be $False

            Remove-Item -Path $IntegrationTarget -Recurse -Force
        }

        It 'Should accept pipeline input' {
            mkdir $IntegrationTarget

            Get-PSDeployment @Verbose -Path $FileYML | Invoke-PSDeployment @Verbose -force
            Start-Sleep -Seconds $WaitForFilesystem
            
            Test-Path (Join-Path $IntegrationTarget File1.ps1) | Should Be $True
        }
    }
}

Remove-Item -Path $FileYML -force
Remove-Item -Path $FolderYML -force
Remove-Item -Path $IntegrationTarget -Recurse -Force