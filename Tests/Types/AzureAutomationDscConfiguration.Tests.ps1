if (-not $ENV:BHProjectPath) {
    Set-BuildEnvironment -Path $PSScriptRoot\..\.. -Force
}
Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1

InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath

    # Define path to the deployment script itself
    $sutPath = "$ProjectRoot\PSDeploy\PSDeployScripts\AzureAutomationDscConfiguration.ps1"

    $Verbose = @{}
    if ($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose") {
        $Verbose.add("Verbose", $True)
    }

    Describe "AzureAutomationDscConfigurationScript PS$PSVersion" {

        Context "Code Style" {
            It "should define CmdletBinding" {
                $sutPath | Should Contain 'CmdletBinding'
            }

            It "should define parameters" {
                $sutPath | Should Contain 'Param'
            }

            It "should contain Write-Verbose blocks" {
                $sutPath | Should Contain 'Write-Verbose'
            }

            It "should be a valid PowerShell code" {
                $psFile = Get-Content -Path $sutPath -ErrorAction Stop
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
                $errors.Count | Should Be 0
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
                $scriptHelp.Synopsis | Should Not BeNullOrEmpty
            }

            It "should have a DESCRIPTION" {
                $scriptHelp.Description.Length | Should Not BeNullOrEmpty
            }

            It "should have at least one EXAMPLE" {
                $scriptHelp.Examples.Count | Should BeGreaterThan 0
            }

            # Getting the list of function parameters
            <# $parameters = $parsedScript.ParamBlock.Parameters.name.VariablePath.Foreach{ $_.ToString() }

            foreach ($parameter in $parameters) {
                It "should have descriptive help for '$parameter' parameter" {
                    $scriptHelp.Parameters.($parameter.ToUpper()) | Should Not BeNullOrEmpty
                }
            } #>
        }

        Context 'Script Logic' {

            Mock Import-AzAutomationDscConfiguration {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.DscConfiguration</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.DscConfiguration</ToString>
        <Props>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AAName</S>
        <S N="Location">westeurope</S>
        <S N="State">Published</S>
        <S N="Name">MMAConfiguration</S>
        <Obj N="Tags" RefId="1">
            <TN RefId="1">
            <T>System.Collections.Hashtable</T>
            <T>System.Object</T>
            </TN>
            <DCT />
        </Obj>
        <Obj N="CreationTime" RefId="2">
            <TN RefId="2">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>03/22/2020 10:54:46 +02:00</ToString>
            <Props>
            <DT N="DateTime">2020-03-22T10:54:46.873</DT>
            <DT N="UtcDateTime">2020-03-22T08:54:46.873Z</DT>
            <DT N="LocalDateTime">2020-03-22T10:54:46.873+02:00</DT>
            <DT N="Date">2020-03-22T00:00:00</DT>
            <I32 N="Day">22</I32>
            <S N="DayOfWeek">Sunday</S>
            <I32 N="DayOfYear">82</I32>
            <I32 N="Hour">10</I32>
            <I32 N="Millisecond">873</I32>
            <I32 N="Minute">54</I32>
            <I32 N="Month">3</I32>
            <TS N="Offset">PT2H</TS>
            <I32 N="Second">46</I32>
            <I64 N="Ticks">637204712868730000</I64>
            <I64 N="UtcTicks">637204640868730000</I64>
            <TS N="TimeOfDay">PT10H54M46.873S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="3">
            <TNRef RefId="2" />
            <ToString>05/12/2020 09:57:22 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-12T09:57:22.01</DT>
            <DT N="UtcDateTime">2020-05-12T06:57:22.01Z</DT>
            <DT N="LocalDateTime">2020-05-12T09:57:22.01+03:00</DT>
            <DT N="Date">2020-05-12T00:00:00</DT>
            <I32 N="Day">12</I32>
            <S N="DayOfWeek">Tuesday</S>
            <I32 N="DayOfYear">133</I32>
            <I32 N="Hour">9</I32>
            <I32 N="Millisecond">10</I32>
            <I32 N="Minute">57</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">22</I32>
            <I64 N="Ticks">637248742420100000</I64>
            <I64 N="UtcTicks">637248634420100000</I64>
            <TS N="TimeOfDay">PT9H57M22.01S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <S N="Description"></S>
        <Obj N="Parameters" RefId="4">
            <TNRef RefId="1" />
            <DCT />
        </Obj>
        <B N="LogVerbose">false</B>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }

            Mock Start-AzAutomationDscCompilationJob {}

            It 'should import the configuration' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationDscConfiguration.psdeploy.ps1" -Force
                    Assert-MockCalled Import-AzAutomationDscConfiguration -Exactly 1 -Scope It
                }
            }

            It 'should compile the configuration' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationDscConfiguration.psdeploy.ps1" -Force
                    Assert-MockCalled Start-AzAutomationDscCompilationJob -Exactly 1 -Scope It
                }
            }

            It "should output into the pipeline" {
                $result = { Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationDscConfiguration.psdeploy.ps1" -Force }
                $result | Should Not BeNullOrEmpty
            }
        }
    }
}