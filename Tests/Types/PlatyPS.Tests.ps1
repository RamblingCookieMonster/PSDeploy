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
        $Verbose.add("Verbose",$True)
    }

    Describe "PlatyPS PS$PSVersion" {
        function New-ExternalHelp {}

        $PlatyPSPS1 = "$ProjectRoot\Tests\artifacts\DeploymentsPlatyPS.psdeploy.ps1"

        Context 'Creates External Help' {
            Mock New-ExternalHelp { Return $True }

            $Results = Invoke-PSDeploy -Path $PlatyPSPS1 -Tags Success @Verbose -Force -ErrorAction SilentlyContinue

            It 'Should create external Help with PlatyPS' {
                Assert-MockCalled New-ExternalHelp -Times 2 -Exactly
            }

            It 'Should Return Mocked output' {
                $Results | Should be $True
            }
        }

        Context 'Source does not exist' {
            Mock New-ExternalHelp {}

            It 'Should throw because source does not exist' {
                $Results = { Invoke-PSDeploy @Verbose -Path $PlatyPSPS1 -Tags Failure -Force -ErrorAction SilentlyContinue }
                $Results | Should Throw
            }
        }
    }
}