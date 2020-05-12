if (-not $ENV:BHProjectPath) {
    Set-BuildEnvironment -Path $PSScriptRoot\..\.. -Force
}
Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1

InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath

    # Define path to the deployment script itself
    $sutPath = "$ProjectRoot\PSDeploy\PSDeployScripts\AzureAutomationRunbook.ps1"

    $Verbose = @{}
    if ($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose") {
        $Verbose.add("Verbose", $True)
    }

    Describe "AzureAutomationRunbookScript PS$PSVersion" {

        Context "Code Style" {
            It "should define CmdletBinding" {
                $sutPath | Should -FileContentMatch 'CmdletBinding'
            }

            It "should define parameters" {
                $sutPath | Should -FileContentMatch 'Param'
            }

            It "should contain Write-Verbose blocks" {
                $sutPath | Should -FileContentMatch 'Write-Verbose'
            }

            It "should be a valid PowerShell code" {
                $psFile = Get-Content -Path $sutPath -ErrorAction Stop
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
                $errors.Count | Should -Be 0
            }
        }

        Context "Help Quality" {

            # Getting function help
            $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
            ParseInput((Get-Content -raw $sutPath), [ref]$null, [ref]$null)
            $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.ScriptBlockAst] }
            $parsedScript = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) # | Where-Object Name -eq $functionName
            $scriptHelp = $parsedScript.GetHelpContent()

            It "should have a SYNOPSIS" {
                $scriptHelp.Synopsis | Should -Not -BeNullOrEmpty
            }

            It "should have a DESCRIPTION" {
                $scriptHelp.Description.Length | Should -Not -BeNullOrEmpty
            }

            It "should have at least one EXAMPLE" {
                $scriptHelp.Examples.Count | Should -BeGreaterThan 0
            }

            # Getting the list of function parameters
            $parameters = $parsedScript.ParamBlock.Parameters.name.VariablePath.Foreach{ $_.ToString() }

            foreach ($parameter in $parameters) {
                It "should have descriptive help for '$parameter' parameter" {
                    $scriptHelp.Parameters.($parameter.ToUpper()) | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context 'Script Logic' {
            Mock Import-AzAutomationRunbook {}

            It 'should publish the runbook' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationRunbook.psdeploy.ps1" -Force
                    Assert-MockCalled Import-AzAutomationRunbook -Times 1 -Exactly
                }
            }

            It "should output into the pipeline" {
                $result = { Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationRunbook.psdeploy.ps1" -Force }
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}