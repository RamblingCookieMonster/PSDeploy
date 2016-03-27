$Verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
{
    $Verbose.add("Verbose",$True)
}

$PSVersion = $PSVersionTable.PSVersion.Major
Import-Module $PSScriptRoot\..\PSDeploy -Force

#Set up some data we will use in testing
    $IntegrationTarget = "$PSScriptRoot\Destination\"
    $FileYML = "$PSScriptRoot\artifacts\IntegrationFile.yml"
    $FolderYML = "$PSScriptRoot\artifacts\IntegrationFolder.yml"
    $FilePS1 = "$PSScriptRoot\artifacts\IntegrationFile.PSDeploy.ps1"
    $FolderPS1 = "$PSScriptRoot\artifacts\IntegrationFolder.PSDeploy.ps1"
    $WaitForFilesystem = .5
    $MyVariable = 42

    Remove-Item -Path $IntegrationTarget -ErrorAction SilentlyContinue -Force -Recurse
    mkdir $IntegrationTarget | Out-Null

@"
Files:
  Author: 'wframe'
  Source:
    - 'Modules\File1.ps1'
  Destination:
    - '$IntegrationTarget'
  DeploymentType: Filesystem
  Options:
    Mirror: False
"@ | Out-File -FilePath $FileYML -force

@"
Files:
  Author: 'wframe'
  Source:
    - 'Modules'
  Destination:
    - '$IntegrationTarget'
  DeploymentType: Filesystem
  Options:
    Mirror: True
"@ | Out-File -FilePath $FolderYML -force

@"
Deploy Files {
    By Filesystem {
        FromSource Modules
        To $IntegrationTarget
        WithOptions @{
            Mirror = $True
        }
        Tagged Testing
    }
}
"@ | Out-File -FilePath $FolderPS1 -force

@"
Deploy Files {
    By Filesystem {
        FromSource Modules\File1.ps1
        To $IntegrationTarget
        WithOptions @{
            Mirror = $false
        }
        Tagged Testing
    }
}
"@ | Out-File -FilePath $FilePS1 -force

Describe "Get-PSDeploymentType PS$PSVersion" {

    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should get definitions' {
            $Definitions = @( Get-PSDeploymentType @Verbose )
            $Definitions.Count | Should Be 3
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
            $Definitions.Keys.Count | Should Be 3
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

        It 'Handles single deployments by yml' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsSingle.yml )
            $Deployments.Count | Should Be 1
        }

        It 'Handles single deployments by ps1' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsSingle.psdeploy.ps1 )
            $Deployments.Count | Should Be 1
        }

        It 'Handles multiple source deployments by yml' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsMultiSource.yml )
            $Deployments.Count | Should Be 3
        }

        It 'Handles multiple source deployments by ps1' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsMultiSource.psdeploy.ps1 )
            $Deployments.Count | Should Be 3
        }

        It 'Handles multiple deployments by yml' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsMulti.yml )
            $Deployments.Count | Should Be 4
        }

        It 'Handles multiple deployments by ps1' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsMulti.psdeploy.ps1 )
            $Deployments.Count | Should Be 4
        }

        It 'Returns a PSDeploy.Deployment object from yml' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsSingle.yml )
            $Deployments[0].psobject.TypeNames[0] | Should Be 'PSDeploy.Deployment'
        }

        It 'Returns a PSDeploy.Deployment object from ps1' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsSingle.psdeploy.ps1 )
            $Deployments[0].psobject.TypeNames[0] | Should Be 'PSDeploy.Deployment'
        }

        It 'Handles identifying source type from yml' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsMultiSource.yml )
            $Deployments[0].SourceType | Should Be 'File'
            $Deployments[1].SourceType | Should Be 'File'
            $Deployments[2].SourceType | Should Be 'Directory'
        }

        It 'Handles identifying source type from ps1' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsMultiSource.psdeploy.ps1 )
            $Deployments[0].SourceType | Should Be 'File'
            $Deployments[1].SourceType | Should Be 'File'
            $Deployments[2].SourceType | Should Be 'Directory'
        }

        It 'Should allow user-specified, properly formed YAML' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsRaw.yml )
            $Deployments.Count | Should Be 1
            $Deployments.Raw.Options.List.Count | Should be 2
            $Deployments.Raw.Options.Making | Should be "Stuff up"
        }

        It 'Should allow user-specified options from ps1' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $PSScriptRoot\artifacts\DeploymentsRaw.PSDeploy.ps1 )
            $Deployments.Count | Should Be 1
            $Deployments.DeploymentOptions.List.Count | Should be 2
            $Deployments.DeploymentOptions.Making | Should be "Stuff up"
        }

        It 'Should handle dependencies' {
            $Deployments = Get-PSDeployment @verbose -Path $PSScriptRoot\artifacts\DeploymentsDependencies.psdeploy.ps1
            $Deployments.Count | Should be 4
            $Deployments[0].DeploymentName | Should Be 'ModuleFiles-Files'
            $Deployments[3].DeploymentName | Should Be 'ModuleFiles-Misc'
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

Describe "Invoke-PSDeploy PS$PSVersion" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should handle dependencies' {
            $NoopOutput = Invoke-PSDeploy @verbose -Path $PSScriptRoot\artifacts\DeploymentsDependencies.psdeploy.ps1 -Force
            $NoopOutput.Deployment.Count | Should be 4
            $NoopOutput.Deployment[0].DeploymentName | Should Be 'ModuleFiles-Files'
            $NoopOutput.Deployment[3].DeploymentName | Should Be 'ModuleFiles-Misc'
        }
        <#
        # Open to suggestions on getting this working.
        # If you set a variable in your session and run PSDeploy, it will see that variable
        # Barring any bugs, of course : )
        It 'Should run in the current scope to allow variable usage' {
            $NoopOutput = Invoke-PSDeploy -Path DeploymentsDependencies.psdeploy.ps1 -Force
            $NoopOutput.GetVariable | Where {$_.Name -eq 'MyVariable'} | Select -ExpandProperty Value | Should Be 42
        }
        #>

        It 'Should find all nested PSDeploy.ps1 files' {
            $NoopOutput = Invoke-PSDeploy  @verbose -Path $PSScriptRoot\artifacts\Modules -Force
            $NoopOutput.Deployment.Count | Should be 2
        }

        It 'Should filter deployments by tags' {
            $NoopOutput = Invoke-PSDeploy @Verbose -Path $PSScriptRoot\artifacts\DeploymentsTags.psdeploy.ps1 -Tags Prod -Force
            $NoopOutput.Count | Should Be 2

            $NoopOutput = Invoke-PSDeploy @Verbose -Path $PSScriptRoot\artifacts\DeploymentsTags.psdeploy.ps1 -Tags Dev -Force
            $NoopOutput.Count | Should Be 2
        }

        It 'Should accept multiple tags' {
            $NoopOutput = Invoke-PSDeploy @Verbose -Path $PSScriptRoot\artifacts\DeploymentsTags.psdeploy.ps1 -Tags Dev, Prod -Force
            $NoopOutput.Count | Should Be 4
        }
    }

}

Remove-Item -Path $FileYML -force
Remove-Item -Path $FolderYML -force
Remove-Item -Path $FilePS1 -force
Remove-Item -Path $FolderPS1 -force
Remove-Item -Path $IntegrationTarget -Recurse -Force