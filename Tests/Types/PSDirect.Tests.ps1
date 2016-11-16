Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1
Set-BuildEnvironment -Path $PSScriptRoot\..\..


InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath
    
    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$true)
    }
    
    # Dummy function, since the New-PSSession on the Server 2016 box has VMName param
    Function New-PSSession {
        [CmdletBinding()]
        param(
            $VMName,
            $Credential
        )
    }

    # Dummy Copy-Item function with parameter -ToSession
    Function Copy-Item {
        [CmdletBinding()]
        param(
            $ToSession,
            $Path,
            $Destination,
            [Switch]$Force,
            [Switch]$Recurse,
            [Switch]$Container
        )
    }

    Describe "PSDirect PS$PSVersion" {

        Context 'Service vmicvmsession is not present on the Host' {

            # Arrange
            Mock -Command Start-Service -MockWith {throw "Cannot find any service with service name 'vmicvmsession'"}

            It 'Should throw customized error' {
                {Invoke-PSDeploy -Path "$ProjectRoot\Tests\artifacts\DeploymentsPSDirectFile.psdeploy.ps1" @Verbose -Force} | 
                    Should Throw "Hyper-V PowerShell Direct Service not found. Terminating."
            }

        }

        Context 'Service vmicvmsession present but cannot be started' {

            Mock -CommandName Start-Service 
            Mock -Command Get-Service -MockWith {[pscustomobject]@{'Status'='Stopped'}}

            It  'Should throw customized error message' {
                {Invoke-PSDeploy -Path "$ProjectRoot\Tests\artifacts\DeploymentsPSDirectFile.psdeploy.ps1" @Verbose -Force} | 
                    Should Throw "Hyper-V PowerShell Direct Service not running. Terminating."
            }
                        
            It 'Should try to start the service' {
                Assert-MockCalled Start-Service -Times 1 -Exactly
            }

        }
        
        Context 'Deploy File to VM' {
            Mock -CommandName Start-Service 
            Mock -Command Get-Service -parameterFilter {$Name -eq 'vmicvmsession'} -MockWith {[pscustomobject]@{'Status'='Running'}}
            Mock -Command New-PSSession -ParameterFilter { ($VMName -eq 'WDS') -and ($null -ne $Credential)} -MockWith {'DummyPSSession'}
            Mock Copy-Item -MockWith { Return $True } -ParameterFilter {
                ($ToSession -eq 'DummyPSSession') -and
                ($null -ne $Path) -and 
                ($null -ne $Destination) 
            }
 
            $Results = Invoke-PSDeploy -Path "$ProjectRoot\Tests\artifacts\DeploymentsPSDirectFile.psdeploy.ps1" @Verbose -Force

            It 'Should ensure Hyper-V PS Direct service is started' {
                Assert-MockCalled Start-Service -Times 1 -Exactly -Scope Context
                Assert-MockCalled Get-Service -Times 1 -Exactly -Scope Context
            }

            It 'Should open a PSSession to the VM' {
                Assert-MockCalled New-PSSession -Times 1 -Exactly -Scope Context
            }

            It 'Should copy file to VM' {                                
                Assert-MockCalled Copy-Item -Times 1 -Exactly -Scope Context
            }

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }
            
        }

        Context 'Deploy Folder to VM' {
            Mock -CommandName Start-Service 
            Mock -Command Get-Service -parameterFilter {$Name -eq 'vmicvmsession'} -MockWith {[pscustomobject]@{'Status'='Running'}}
            Mock -Command New-PSSession -ParameterFilter { ($VMName -eq 'WDS') -and ($null -ne $Credential)} -MockWith {'DummyPSSession'}
            Mock -Command Copy-Item -MockWith { Return $True } -ParameterFilter {
                ($ToSession -eq 'DummyPSSession') -and
                ($null -ne $Path) -and 
                ($null -ne $Destination) -and
                $Container.IsPresent -and
                $Force.IsPresent -and 
                $Recurse.IsPresent
            }

            $Results = Invoke-PSDeploy -Path "$ProjectRoot\Tests\artifacts\DeploymentsPSDirectFolder.psdeploy.ps1" @Verbose -Force
            
            It 'Should pass the mocked PSSession to the Copy-Item' {
                Assert-MockCalled Copy-Item -ParameterFilter {$TOSession -eq 'DummyPSSession' } -Times 1 -Scope Context
            }

            It 'Should set the -Container, -Force & -Recurse switches' {
                Assert-MockCalled Copy-Item -ParameterFilter {$Container.IsPresent -and $Force.IsPresent -and $Recurse.IsPresent} -times 1 -Scope Context
            }

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }

            It 'Should copy folder to VM, recursive copy' {                
                Assert-MockCalled Copy-Item -Times 1 -Exactly -Scope Context -ParameterFilter {
                    $Recurse.IsPresent 
                }
            }
        }


    }
}