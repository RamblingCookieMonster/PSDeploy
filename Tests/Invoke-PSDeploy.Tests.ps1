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

    Describe "Invoke-PSDeploy PS$PSVersion" {
        $IntegrationTarget = "TestDrive:\"

        Context 'Handles Dependencies' {        
            $NoopOutput = Invoke-PSDeploy @verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsDependencies.psdeploy.ps1 -Force

            It 'Should have 4 Deployments' {
                $NoopOutput.Deployment.Count | Should be 4
            }

            It 'Should have expected DeploymentName' {
                $NoopOutput.Deployment[0].DeploymentName | Should Be 'ModuleFiles-Files'
            }

            It 'Should have expected DeploymentName' {
                $NoopOutput.Deployment[3].DeploymentName | Should Be 'ModuleFiles-Misc'
            }
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
        Context 'Nested PSDeploy.ps1 Files' {

            It 'Should find all nested PSDeploy.ps1 files' {
                $NoopOutput = Invoke-PSDeploy  @verbose -Path $ProjectRoot\Tests\artifacts\Modules -Force
                $NoopOutput.Deployment.Count | Should be 2
            }
        }

        Context 'Handles Tags' {

            It 'Should filter deployments by Prod tags' {
                $NoopOutput = Invoke-PSDeploy @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsTags.psdeploy.ps1 -Tags Prod -Force
                $NoopOutput.Count | Should Be 2
            }

            It 'Should filter deployments by Dev tags' {
                $NoopOutput = Invoke-PSDeploy @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsTags.psdeploy.ps1 -Tags Dev -Force
                $NoopOutput.Count | Should Be 2
            }

            It 'Should accept multiple tags' {
                $NoopOutput = Invoke-PSDeploy @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsTags.psdeploy.ps1 -Tags Dev, Prod -Force
                $NoopOutput.Count | Should Be 4
            }
        }

        Context 'Handles Pre and Post Scriptblock without SkipOnError' {
            $NoopOutput = Invoke-PSDeploy @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsBeforeAfter.psdeploy.ps1 -Force -Tags False

            It 'Should have expected count' {                
                $NoopOutput.Count | Should Be 3
            }

            It 'Should Return Prescript' {
                $NoopOutput[0] | Should be "Setting things up for a deployment..."
            }

            It 'Should not Skip on Error' {
                $NoopOutput[1].Deployment.PreScript.SkipOnError.IsPresent | Should be $False
            }

            It 'Should Return Postscript' {
                $NoopOutput[2] | Should be "Tearing things down from a deployment..."
            }
        }

        Context 'Handles Pre and Post Scriptblock with SkipOnError' {
            $NoopOutput = Invoke-PSDeploy @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsBeforeAfter.psdeploy.ps1 -Force -Tags True

            It 'Should have expected count' {                
                $NoopOutput.Count | Should Be 3
            }

            It 'Should Return Prescript' {
                $NoopOutput[0] | Should be "Setting things up for a deployment..."
            }

            It 'Should not Skip on Error' {
                $NoopOutput[1].Deployment.PreScript.SkipOnError.IsPresent | Should be $True
            }

            It 'Should Return Postscript' {
                $NoopOutput[2] | Should be "Tearing things down from a deployment..."
            }
        }

        Context 'Task Deployment' {

            It 'Should handle task scriptblock "deployments"' {
                $Deployments = @( Invoke-PSDeploy @verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsTasks.psdeploy.ps1 -Force )
                $Deployments[0] | Should Be 'Running a task!'
            }

            It 'Should handle task ps1 "deployments"' {
                $Deployments = @( Invoke-PSDeploy @verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsTasksPS1.psdeploy.ps1 -Force )
                $Deployments[0] | Should Be 'mmhmm'
            }
        }

        Context 'Picks up custom PSDeploy.yml scripts in custom path' {
            $CustomYaml = @'
CustomScript:
  Script: CustomScript.ps1
  Description: Custom script to deploy
'@
            $PSDeployYamlPath = Join-Path -Path 'TestDrive:' -ChildPath 'PSDeploy.yml'
            $CustomYaml | Out-File -FilePath $PSDeployYamlPath -Force

            $CustomScript = @'
[CmdletBinding()]
Param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [PSObject[]]$Deployment,

    [Parameter(Mandatory=$true)]
    [System.String]
    $Path
)

Set-Content -Path $Path -Value $Deployment.Source
'@
            $PSDeployScriptsPath = Join-Path -Path 'TestDrive:' -ChildPath 'PSDeployScripts'
            New-Item -Path $PSDeployScriptsPath -ItemType Directory > $null
            $CustomScriptPath = Join-Path -Path $PSDeployScriptsPath -ChildPath 'CustomScript.ps1'
            $CustomScript | Out-File -FilePath $CustomScriptPath -Force

            $OutputPath = Join-Path -Path 'TestDrive:' -ChildPath 'output.txt'
            New-Item -Path $OutputPath -ItemType File > $null
            $CustomDeploy = @"
Deploy Test {
    By CustomScript {
        FromSource '$((Get-Item -Path $PSDeployYamlPath).FullName)'
        WithOptions @{
            Path = '$((Get-Item -Path $OutputPath).FullName)'
        }
    }
}
"@
            $CustomDeployPath = Join-Path -Path 'TestDrive:' -ChildPath 'custom.psdeploy.ps1'
            $CustomDeploy | Out-File -FilePath $CustomDeployPath -Force

            Invoke-PSDeploy -Path $CustomDeployPath -PSDeployTypePath $PSDeployYamlPath -Force
            $Actual = (Get-Content -Path $OutputPath -Raw).Trim()

            It 'Should output both sources specified' {
                $Actual | Should -Be (Get-Item -Path $PSDeployYamlPath).FullName
            }
        }
    }
}
