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

    Describe "Get-PSDeployment PS$PSVersion" {

        Context 'Handles Single Deployments' {

            It 'Handles single deployments by yml' {
                $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsSingle.yml )
                $Deployments.Count | Should Be 1
            }

            It 'Handles single deployments by ps1' {
                $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsSingle.psdeploy.ps1 )
                $Deployments.Count | Should Be 1
            }
        }

        Context 'Handles Multiple Deployments' {

            It 'Handles multiple source deployments by yml' {
                $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsMultiSource.yml )
                $Deployments.Count | Should Be 3
            }

            It 'Handles multiple source deployments by ps1' {
                $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsMultiSource.psdeploy.ps1 )
                $Deployments.Count | Should Be 3
            }

            It 'Handles multiple deployments by yml' {
                $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsMulti.yml )
                $Deployments.Count | Should Be 4
            }

            It 'Handles multiple deployments by ps1' {
                $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsMulti.psdeploy.ps1 )
                $Deployments.Count | Should Be 4
            }
        }

        Context 'Returns a PSDeploy.Deployment object' {

            It 'Returns a PSDeploy.Deployment object from yml' {
                $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsSingle.yml )
                $Deployments[0].psobject.TypeNames[0] | Should Be 'PSDeploy.Deployment'
            }

            It 'Returns a PSDeploy.Deployment object from ps1' {
                $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsSingle.psdeploy.ps1 )
                $Deployments[0].psobject.TypeNames[0] | Should Be 'PSDeploy.Deployment'
            }
        }

        Context 'Handles identifying source type from yml' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsMultiSource.yml )

            It "First Source Type Should Be File" {
                $Deployments[0].SourceType | Should Be 'File'            
            }

            It 'Second Source Type should be File' {
                $Deployments[1].SourceType | Should Be 'File'            
            }

            It 'Third Source Type Should be Directory' {            
                $Deployments[2].SourceType | Should Be 'Directory'
            }
        }

        Context 'Handles identifying source type from yml' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsMultiSource.yml )

            It "First Source Type Should Be File" {
                $Deployments[0].SourceType | Should Be 'File'            
            }

            It 'Second Source Type should be File' {
                $Deployments[1].SourceType | Should Be 'File'            
            }

            It 'Third Source Type Should be Directory' {            
                $Deployments[2].SourceType | Should Be 'Directory'
            }
        }


        Context 'Handles identifying source type from ps1' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsMultiSource.psdeploy.ps1 )

            It "First Source Type Should Be File" {
                $Deployments[0].SourceType | Should Be 'File'            
            }

            It 'Second Source Type should be File' {
                $Deployments[1].SourceType | Should Be 'File'            
            }

            It 'Third Source Type Should be Directory' {         
                $Deployments[2].SourceType | Should Be 'Directory'
            }

            It 'Should concatenate' {
                $Deployments[2].Source | Should Be (Resolve-Path "$ProjectRoot\Tests\artifacts\Modules\CrazyModule").Path
            }
        }


        Context 'Should allow user-specified, properly formed YAML' {
            $Deployments = @( Get-PSDeployment @Verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsRaw.yml )

            It 'Should have expected Count' {
                $Deployments.Count | Should Be 1
            }

            It 'Should have expected List Count' {
                $Deployments[0].DeploymentOptions.List.Count | Should be 2
            }

            It 'Should have the expected Options' {
                $Deployments[0].DeploymentOptions.Making | Should be "Stuff up"
            }
        }

        Context 'Should allow user-specified options from ps1' {
            $Deployments = @( Get-PSDeployment @Verbose -Path (Join-Path -Path $ProjectRoot -ChildPath 'Tests\artifacts\DeploymentsRaw.psdeploy.ps1') )

            It 'Should have expected Count' {
                $Deployments.Count | Should Be 1
            }

            It 'Should have expected List Count' {
                $Deployments[0].DeploymentOptions.List.Count | Should be 2
            }

            It 'Should have the expected Options' {
                $Deployments[0].DeploymentOptions.Making | Should be "Stuff up"
            }
        }

    	Context 'Should handle dependencies' {
            $Deployments = Get-PSDeployment @verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsDependencies.psdeploy.ps1

            It 'Should have expected Count' {
                $Deployments.Count | Should be 4
            }

            It 'Should have expected DeploymentName' {
                $Deployments[0].DeploymentName | Should Be 'ModuleFiles-Files'
            }

            It 'Should have expected DeploymentName' {
                $Deployments[3].DeploymentName | Should Be 'ModuleFiles-Misc'
            }
        }

        Context 'Should handle task "deployments"' {
            $Deployments = Get-PSDeployment @verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsTasks.psdeploy.ps1

            It 'Should have expected Count' {
                $Deployments.count | Should be 2
            }

            It 'Should have expected Source' {
                $Deployments[0].Source -Match '"Running a task!"' | Should be $True
            }
        }

        Context "Should handle absolute source paths that don't exist" {
            $Deployments = @( Get-PSDeployment @verbose -Path $ProjectRoot\Tests\artifacts\DeploymentsSourceAbsolute.psdeploy.ps1 )

            It 'Should have expected Count' {
                $Deployments.count | Should be 1
            }

            It 'Should have expected Source' {
                $Deployments[0].Source | Should be 'C:\Nope\Modules\File1.ps1'
            }
        }
    }
}