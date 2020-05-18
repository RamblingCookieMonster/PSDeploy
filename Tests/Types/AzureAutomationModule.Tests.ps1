if (-not $ENV:BHProjectPath) {
    Set-BuildEnvironment -Path $PSScriptRoot\..\.. -Force
}
Remove-Module PSDeploy -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\..\PSDeploy\PSDeploy.psd1

InModuleScope 'PSDeploy' {
    $PSVersion = $PSVersionTable.PSVersion.Major
    $ProjectRoot = $ENV:BHProjectPath

    # Define path to the deployment script itself
    $sutPath = "$ProjectRoot\PSDeploy\PSDeployScripts\AzureAutomationModule.ps1"

    $Verbose = @{}
    if ($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose") {
        $Verbose.add("Verbose", $True)
    }

    Describe "AzureAutomationModuleScript PS$PSVersion" {

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
            $parameters = $parsedScript.ParamBlock.Parameters.name.VariablePath.Foreach{ $_.ToString() }

            foreach ($parameter in $parameters) {
                It "should have descriptive help for '$parameter' parameter" {
                    $scriptHelp.Parameters.($parameter.ToUpper()) | Should Not BeNullOrEmpty
                }
            }
        }

        Context 'Script Logic - Public Module' {

            Mock Get-AzAutomationAccount {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.AutomationAccount</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.AutomationAccount</ToString>
        <Props>
        <S N="SubscriptionId">c49124fa-befd-4207-a3b7-29c95c41a964</S>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AAName</S>
        <S N="Location">westeurope</S>
        <S N="State">Ok</S>
        <S N="Plan">Basic</S>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>10/02/2017 16:05:15 +03:00</ToString>
            <Props>
            <DT N="DateTime">2017-10-02T16:05:15.39</DT>
            <DT N="UtcDateTime">2017-10-02T13:05:15.39Z</DT>
            <DT N="LocalDateTime">2017-10-02T16:05:15.39+03:00</DT>
            <DT N="Date">2017-10-02T00:00:00</DT>
            <I32 N="Day">2</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">275</I32>
            <I32 N="Hour">16</I32>
            <I32 N="Millisecond">390</I32>
            <I32 N="Minute">5</I32>
            <I32 N="Month">10</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">15</I32>
            <I64 N="Ticks">636425571153900000</I64>
            <I64 N="UtcTicks">636425463153900000</I64>
            <TS N="TimeOfDay">PT16H5M15.39S</TS>
            <I32 N="Year">2017</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>03/22/2020 10:41:20 +02:00</ToString>
            <Props>
            <DT N="DateTime">2020-03-22T10:41:20.57</DT>
            <DT N="UtcDateTime">2020-03-22T08:41:20.57Z</DT>
            <DT N="LocalDateTime">2020-03-22T10:41:20.57+02:00</DT>
            <DT N="Date">2020-03-22T00:00:00</DT>
            <I32 N="Day">22</I32>
            <S N="DayOfWeek">Sunday</S>
            <I32 N="DayOfYear">82</I32>
            <I32 N="Hour">10</I32>
            <I32 N="Millisecond">570</I32>
            <I32 N="Minute">41</I32>
            <I32 N="Month">3</I32>
            <TS N="Offset">PT2H</TS>
            <I32 N="Second">20</I32>
            <I64 N="Ticks">637204704805700000</I64>
            <I64 N="UtcTicks">637204632805700000</I64>
            <TS N="TimeOfDay">PT10H41M20.57S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="LastModifiedBy" />
        <Obj N="Tags" RefId="3">
            <TN RefId="2">
            <T>System.Collections.Hashtable</T>
            <T>System.Object</T>
            </TN>
            <DCT>
            <En>
                <S N="Key">environment</S>
                <S N="Value">Test</S>
            </En>
            </DCT>
        </Obj>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzAutomationModule {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.Module</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.Module</ToString>
        <Props>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AANAme</S>
        <S N="Name">PSDepend</S>
        <B N="IsGlobal">false</B>
        <S N="Version">0.3.2</S>
        <I64 N="SizeInBytes">71093</I64>
        <I32 N="ActivityCount">8</I32>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 17:42:32 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:42:32.617</DT>
            <DT N="UtcDateTime">2020-05-04T14:42:32.617Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:42:32.617+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">617</I32>
            <I32 N="Minute">42</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">32</I32>
            <I64 N="Ticks">637242109526170000</I64>
            <I64 N="UtcTicks">637242001526170000</I64>
            <TS N="TimeOfDay">PT17H42M32.617S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>05/04/2020 17:44:14 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:44:14.537</DT>
            <DT N="UtcDateTime">2020-05-04T14:44:14.537Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:44:14.537+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">537</I32>
            <I32 N="Minute">44</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">14</I32>
            <I64 N="Ticks">637242110545370000</I64>
            <I64 N="UtcTicks">637242002545370000</I64>
            <TS N="TimeOfDay">PT17H44M14.537S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <S N="ProvisioningState">Succeeded</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzAutomationModule {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.Module</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.Module</ToString>
        <Props>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AAName</S>
        <S N="Name">PSDepend</S>
        <B N="IsGlobal">false</B>
        <S N="Version">0.3.2</S>
        <I64 N="SizeInBytes">71093</I64>
        <I32 N="ActivityCount">8</I32>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 17:42:32 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:42:32.617</DT>
            <DT N="UtcDateTime">2020-05-04T14:42:32.617Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:42:32.617+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">617</I32>
            <I32 N="Minute">42</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">32</I32>
            <I64 N="Ticks">637242109526170000</I64>
            <I64 N="UtcTicks">637242001526170000</I64>
            <TS N="TimeOfDay">PT17H42M32.617S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>05/12/2020 14:05:27 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-12T14:05:27.527</DT>
            <DT N="UtcDateTime">2020-05-12T11:05:27.527Z</DT>
            <DT N="LocalDateTime">2020-05-12T14:05:27.527+03:00</DT>
            <DT N="Date">2020-05-12T00:00:00</DT>
            <I32 N="Day">12</I32>
            <S N="DayOfWeek">Tuesday</S>
            <I32 N="DayOfYear">133</I32>
            <I32 N="Hour">14</I32>
            <I32 N="Millisecond">527</I32>
            <I32 N="Minute">5</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">27</I32>
            <I64 N="Ticks">637248891275270000</I64>
            <I64 N="UtcTicks">637248783275270000</I64>
            <TS N="TimeOfDay">PT14H5M27.527S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <S N="ProvisioningState">Succeeded</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }

            Mock Get-AzStorageAccount {}
            Mock Get-AzStorageContainer {}
            Mock Get-AzStorageAccountKey {}
            Mock New-AzStorageContainer {}
            Mock New-AzStorageContext {}
            Mock New-AzStorageBlobSASToken {}
            Mock Set-AzStorageBlobContent {}

            It 'should get an Automation account' {
                {
                    {Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force}
                    Assert-MockCalled Get-AzAutomationAccount -Exactly 1 -Scope It
                }
            }

            It 'should query the Automation account for already imported module' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled Get-AzAutomationModule -Exactly 1 -Scope It
                }
            }

            It 'should import the module into Automation account' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled New-AzAutomationModule -Exactly 1 -Scope It
                }
            }

            It 'should should not use a Storage account' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled Get-AzStorageAccount -Exactly 0 -Scope It
                    Assert-MockCalled Get-AzStorageContainer -Exactly 0 -Scope It
                    Assert-MockCalled Get-AzStorageAccountKey -Exactly 0 -Scope It
                    Assert-MockCalled New-AzStorageContainer -Exactly 0 -Scope It
                    Assert-MockCalled New-AzStorageContext -Exactly 0 -Scope It
                    Assert-MockCalled New-AzStorageBlobSASToken -Exactly 0 -Scope It
                    Assert-MockCalled Set-AzStorageBlobContent -Exactly 0 -Scope It
                }
            }
        }

        Context 'Script Logic - Private Module' {

            Mock Get-AzAutomationAccount {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.AutomationAccount</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.AutomationAccount</ToString>
        <Props>
        <S N="SubscriptionId">c49124fa-befd-4207-a3b7-29c95c41a964</S>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AAName</S>
        <S N="Location">westeurope</S>
        <S N="State">Ok</S>
        <S N="Plan">Basic</S>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>10/02/2017 16:05:15 +03:00</ToString>
            <Props>
            <DT N="DateTime">2017-10-02T16:05:15.39</DT>
            <DT N="UtcDateTime">2017-10-02T13:05:15.39Z</DT>
            <DT N="LocalDateTime">2017-10-02T16:05:15.39+03:00</DT>
            <DT N="Date">2017-10-02T00:00:00</DT>
            <I32 N="Day">2</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">275</I32>
            <I32 N="Hour">16</I32>
            <I32 N="Millisecond">390</I32>
            <I32 N="Minute">5</I32>
            <I32 N="Month">10</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">15</I32>
            <I64 N="Ticks">636425571153900000</I64>
            <I64 N="UtcTicks">636425463153900000</I64>
            <TS N="TimeOfDay">PT16H5M15.39S</TS>
            <I32 N="Year">2017</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>03/22/2020 10:41:20 +02:00</ToString>
            <Props>
            <DT N="DateTime">2020-03-22T10:41:20.57</DT>
            <DT N="UtcDateTime">2020-03-22T08:41:20.57Z</DT>
            <DT N="LocalDateTime">2020-03-22T10:41:20.57+02:00</DT>
            <DT N="Date">2020-03-22T00:00:00</DT>
            <I32 N="Day">22</I32>
            <S N="DayOfWeek">Sunday</S>
            <I32 N="DayOfYear">82</I32>
            <I32 N="Hour">10</I32>
            <I32 N="Millisecond">570</I32>
            <I32 N="Minute">41</I32>
            <I32 N="Month">3</I32>
            <TS N="Offset">PT2H</TS>
            <I32 N="Second">20</I32>
            <I64 N="Ticks">637204704805700000</I64>
            <I64 N="UtcTicks">637204632805700000</I64>
            <TS N="TimeOfDay">PT10H41M20.57S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="LastModifiedBy" />
        <Obj N="Tags" RefId="3">
            <TN RefId="2">
            <T>System.Collections.Hashtable</T>
            <T>System.Object</T>
            </TN>
            <DCT>
            <En>
                <S N="Key">environment</S>
                <S N="Value">Test</S>
            </En>
            </DCT>
        </Obj>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzAutomationModule {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.Module</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.Module</ToString>
        <Props>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AANAme</S>
        <S N="Name">PSDepend</S>
        <B N="IsGlobal">false</B>
        <S N="Version">0.3.2</S>
        <I64 N="SizeInBytes">71093</I64>
        <I32 N="ActivityCount">8</I32>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 17:42:32 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:42:32.617</DT>
            <DT N="UtcDateTime">2020-05-04T14:42:32.617Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:42:32.617+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">617</I32>
            <I32 N="Minute">42</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">32</I32>
            <I64 N="Ticks">637242109526170000</I64>
            <I64 N="UtcTicks">637242001526170000</I64>
            <TS N="TimeOfDay">PT17H42M32.617S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>05/04/2020 17:44:14 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:44:14.537</DT>
            <DT N="UtcDateTime">2020-05-04T14:44:14.537Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:44:14.537+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">537</I32>
            <I32 N="Minute">44</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">14</I32>
            <I64 N="Ticks">637242110545370000</I64>
            <I64 N="UtcTicks">637242002545370000</I64>
            <TS N="TimeOfDay">PT17H44M14.537S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <S N="ProvisioningState">Succeeded</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzAutomationModule {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.Module</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.Module</ToString>
        <Props>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AAName</S>
        <S N="Name">PSDepend</S>
        <B N="IsGlobal">false</B>
        <S N="Version">0.3.2</S>
        <I64 N="SizeInBytes">71093</I64>
        <I32 N="ActivityCount">8</I32>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 17:42:32 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:42:32.617</DT>
            <DT N="UtcDateTime">2020-05-04T14:42:32.617Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:42:32.617+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">617</I32>
            <I32 N="Minute">42</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">32</I32>
            <I64 N="Ticks">637242109526170000</I64>
            <I64 N="UtcTicks">637242001526170000</I64>
            <TS N="TimeOfDay">PT17H42M32.617S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>05/12/2020 14:05:27 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-12T14:05:27.527</DT>
            <DT N="UtcDateTime">2020-05-12T11:05:27.527Z</DT>
            <DT N="LocalDateTime">2020-05-12T14:05:27.527+03:00</DT>
            <DT N="Date">2020-05-12T00:00:00</DT>
            <I32 N="Day">12</I32>
            <S N="DayOfWeek">Tuesday</S>
            <I32 N="DayOfYear">133</I32>
            <I32 N="Hour">14</I32>
            <I32 N="Millisecond">527</I32>
            <I32 N="Minute">5</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">27</I32>
            <I64 N="Ticks">637248891275270000</I64>
            <I64 N="UtcTicks">637248783275270000</I64>
            <TS N="TimeOfDay">PT14H5M27.527S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <S N="ProvisioningState">Succeeded</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzStorageAccount {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Management.Storage.Models.PSStorageAccount</T>
        <T>System.Object</T>
        </TN>
        <ToString />
        <Props>
        <S N="ResourceGroupName">SATestAutomationAndMonitoringRG</S>
        <S N="StorageAccountName">aadeploymentstor</S>
        <S N="Id">/subscriptions/eb31e8d0-5a14-4eea-87b9-66581523e545/resourceGroups/SATestAutomationAndMonitoringRG/providers/Microsoft.Storage/storageAccounts/aadeploymentstor</S>
        <S N="Location">westeurope</S>
        <Obj N="Sku" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Commands.Management.Storage.Models.PSSku</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Commands.Management.Storage.Models.PSSku</ToString>
            <Props>
            <S N="Name">Standard_LRS</S>
            <S N="Tier">Standard</S>
            <Nil N="ResourceType" />
            <Nil N="Kind" />
            <Nil N="Locations" />
            <Nil N="Capabilities" />
            <Nil N="Restrictions" />
            </Props>
        </Obj>
        <S N="Kind">StorageV2</S>
        <Obj N="Encryption" RefId="2">
            <TN RefId="2">
            <T>Microsoft.Azure.Management.Storage.Models.Encryption</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Management.Storage.Models.Encryption</ToString>
            <Props>
            <S N="Services">Microsoft.Azure.Management.Storage.Models.EncryptionServices</S>
            <S N="KeySource">Microsoft.Storage</S>
            <Nil N="KeyVaultProperties" />
            </Props>
        </Obj>
        <Obj N="AccessTier" RefId="3">
            <TN RefId="3">
            <T>Microsoft.Azure.Management.Storage.Models.AccessTier</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Hot</ToString>
            <I32>0</I32>
        </Obj>
        <DT N="CreationTime">2020-05-03T10:59:39.4378401Z</DT>
        <Nil N="CustomDomain" />
        <Nil N="Identity" />
        <Nil N="LastGeoFailoverTime" />
        <Obj N="PrimaryEndpoints" RefId="4">
            <TN RefId="4">
            <T>Microsoft.Azure.Management.Storage.Models.Endpoints</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Management.Storage.Models.Endpoints</ToString>
            <Props>
            <S N="Blob">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="Queue">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="Table">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="File">https://aadeploymentstor.file.core.windows.net/</S>
            <S N="Web">https://aadeploymentstor.z6.web.core.windows.net/</S>
            <S N="Dfs">https://aadeploymentstor.dfs.core.windows.net/</S>
            <Nil N="MicrosoftEndpoints" />
            <Nil N="InternetEndpoints" />
            </Props>
        </Obj>
        <S N="PrimaryLocation">westeurope</S>
        <Obj N="ProvisioningState" RefId="5">
            <TN RefId="5">
            <T>Microsoft.Azure.Management.Storage.Models.ProvisioningState</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Succeeded</ToString>
            <I32>2</I32>
        </Obj>
        <Nil N="SecondaryEndpoints" />
        <Nil N="SecondaryLocation" />
        <Obj N="StatusOfPrimary" RefId="6">
            <TN RefId="6">
            <T>Microsoft.Azure.Management.Storage.Models.AccountStatus</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Available</ToString>
            <I32>0</I32>
        </Obj>
        <Nil N="StatusOfSecondary" />
        <Obj N="Tags" RefId="7">
            <TN RefId="7">
            <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
            <T>System.Object</T>
            </TN>
            <DCT>
            <En>
                <S N="Key">environment</S>
                <S N="Value">Test</S>
            </En>
            </DCT>
        </Obj>
        <B N="EnableHttpsTrafficOnly">true</B>
        <Nil N="AzureFilesIdentityBasedAuth" />
        <Nil N="EnableHierarchicalNamespace" />
        <S N="LargeFileSharesState">Disabled</S>
        <Obj N="NetworkRuleSet" RefId="8">
            <TN RefId="8">
            <T>Microsoft.Azure.Commands.Management.Storage.Models.PSNetworkRuleSet</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Commands.Management.Storage.Models.PSNetworkRuleSet</ToString>
            <Props>
            <Obj N="IpRules" RefId="9">
                <TN RefId="9">
                <T>Microsoft.Azure.Commands.Management.Storage.Models.PSIpRule[]</T>
                <T>System.Array</T>
                <T>System.Object</T>
                </TN>
                <LST />
            </Obj>
            <Obj N="VirtualNetworkRules" RefId="10">
                <TN RefId="10">
                <T>Microsoft.Azure.Commands.Management.Storage.Models.PSVirtualNetworkRule[]</T>
                <T>System.Array</T>
                <T>System.Object</T>
                </TN>
                <LST />
            </Obj>
            <S N="Bypass">AzureServices</S>
            <S N="DefaultAction">Allow</S>
            </Props>
        </Obj>
        <Nil N="GeoReplicationStats" />
        <Obj N="Context" RefId="11">
            <TN RefId="11">
            <T>Microsoft.WindowsAzure.Commands.Common.Storage.LazyAzureStorageContext</T>
            <T>Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.WindowsAzure.Commands.Common.Storage.LazyAzureStorageContext</ToString>
            <Props>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="StorageAccountName">aadeploymentstor</S>
            <Ref N="Context" RefId="11" />
            <S N="Name">aadeploymentstor</S>
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="12">
                <TNRef RefId="7" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <Obj N="ExtendedProperties" RefId="13">
            <TNRef RefId="7" />
            <DCT />
        </Obj>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzStorageContainer {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer</T>
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer</ToString>
        <Props>
        <Obj N="CloudBlobContainer" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Storage.Blob.CloudBlobContainer</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.CloudBlobContainer</ToString>
            <Props>
            <S N="ServiceClient">Microsoft.Azure.Storage.Blob.CloudBlobClient</S>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend</URI>
            <S N="StorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/psdepend'; Secondary = ''</S>
            <S N="Name">psdepend</S>
            <Obj N="Metadata" RefId="2">
                <TN RefId="2">
                <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
                <T>System.Object</T>
                </TN>
                <DCT />
            </Obj>
            <S N="Properties">Microsoft.Azure.Storage.Blob.BlobContainerProperties</S>
            </Props>
        </Obj>
        <Obj N="Permission" RefId="3">
            <TN RefId="3">
            <T>Microsoft.Azure.Storage.Blob.BlobContainerPermissions</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.BlobContainerPermissions</ToString>
            <Props>
            <S N="PublicAccess">Container</S>
            <Obj N="SharedAccessPolicies" RefId="4">
                <TN RefId="4">
                <T>Microsoft.Azure.Storage.Blob.SharedAccessBlobPolicies</T>
                <T>System.Object</T>
                </TN>
                <IE />
            </Obj>
            </Props>
        </Obj>
        <Obj N="PublicAccess" RefId="5">
            <TN RefId="5">
            <T>Microsoft.Azure.Storage.Blob.BlobContainerPublicAccessType</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Container</ToString>
            <I32>1</I32>
        </Obj>
        <Obj N="LastModified" RefId="6">
            <TN RefId="6">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 14:45:45 +00:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T14:45:45</DT>
            <DT N="UtcDateTime">2020-05-04T14:45:45Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:45:45+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">14</I32>
            <I32 N="Millisecond">0</I32>
            <I32 N="Minute">45</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT0S</TS>
            <I32 N="Second">45</I32>
            <I64 N="Ticks">637242003450000000</I64>
            <I64 N="UtcTicks">637242003450000000</I64>
            <TS N="TimeOfDay">PT14H45M45S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="ContinuationToken" />
        <Obj N="BlobContainerClient" RefId="7">
            <TN RefId="7">
            <T>Azure.Storage.Blobs.BlobContainerClient</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.BlobContainerClient</ToString>
            <Props>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend</URI>
            <S N="AccountName">aadeploymentstor</S>
            <S N="Name">psdepend</S>
            </Props>
        </Obj>
        <Obj N="BlobContainerProperties" RefId="8">
            <TN RefId="8">
            <T>Azure.Storage.Blobs.Models.BlobContainerProperties</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.Models.BlobContainerProperties</ToString>
            <Props>
            <S N="LastModified">05/04/2020 14:45:45 +00:00</S>
            <S N="LeaseStatus">Unlocked</S>
            <S N="LeaseState">Available</S>
            <S N="LeaseDuration">Infinite</S>
            <S N="PublicAccess">BlobContainer</S>
            <B N="HasImmutabilityPolicy">false</B>
            <B N="HasLegalHold">false</B>
            <S N="DefaultEncryptionScope">$account-encryption-key</S>
            <B N="PreventEncryptionScopeOverride">false</B>
            <S N="ETag">"0x8D7F039D3D0C5C5"</S>
            <Obj N="Metadata" RefId="9">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <Obj N="Context" RefId="10">
            <TN RefId="9">
            <T>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
            <Props>
            <S N="StorageAccountName">aadeploymentstor</S>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <Ref N="Context" RefId="10" />
            <S N="Name"></S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="TableStorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</S>
            <Nil N="Track2OauthToken" />
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="11">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <S N="Name">psdepend</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzStorageAccountKey {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Management.Storage.Models.StorageAccountKey</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Management.Storage.Models.StorageAccountKey</ToString>
        <Props>
        <S N="KeyName">key1</S>
        <S N="Value">aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
        <Obj N="Permissions" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Management.Storage.Models.KeyPermission</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Full</ToString>
            <I32>1</I32>
        </Obj>
        </Props>
    </Obj>
    <Obj RefId="2">
        <TNRef RefId="0" />
        <ToString>Microsoft.Azure.Management.Storage.Models.StorageAccountKey</ToString>
        <Props>
        <S N="KeyName">key2</S>
        <S N="Value">lCvSampwF8ZkAgjaDJXpw3akynx5aEecS3Wg/WDeygQd7l+/bXMZD+uk0Dd0Jbk2tZ7nBO39W0fGXsZBQtK0zQ==</S>
        <Obj N="Permissions" RefId="3">
            <TNRef RefId="1" />
            <ToString>Full</ToString>
            <I32>1</I32>
        </Obj>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzStorageContainer {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer</T>
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer</ToString>
        <Props>
        <Obj N="CloudBlobContainer" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Storage.Blob.CloudBlobContainer</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.CloudBlobContainer</ToString>
            <Props>
            <S N="ServiceClient">Microsoft.Azure.Storage.Blob.CloudBlobClient</S>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend</URI>
            <S N="StorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/psdepend'; Secondary = ''</S>
            <S N="Name">psdepend</S>
            <Obj N="Metadata" RefId="2">
                <TN RefId="2">
                <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
                <T>System.Object</T>
                </TN>
                <DCT />
            </Obj>
            <S N="Properties">Microsoft.Azure.Storage.Blob.BlobContainerProperties</S>
            </Props>
        </Obj>
        <Obj N="Permission" RefId="3">
            <TN RefId="3">
            <T>Microsoft.Azure.Storage.Blob.BlobContainerPermissions</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.BlobContainerPermissions</ToString>
            <Props>
            <S N="PublicAccess">Container</S>
            <Obj N="SharedAccessPolicies" RefId="4">
                <TN RefId="4">
                <T>Microsoft.Azure.Storage.Blob.SharedAccessBlobPolicies</T>
                <T>System.Object</T>
                </TN>
                <IE />
            </Obj>
            </Props>
        </Obj>
        <Obj N="PublicAccess" RefId="5">
            <TN RefId="5">
            <T>Microsoft.Azure.Storage.Blob.BlobContainerPublicAccessType</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Container</ToString>
            <I32>1</I32>
        </Obj>
        <Obj N="LastModified" RefId="6">
            <TN RefId="6">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 14:45:45 +00:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T14:45:45</DT>
            <DT N="UtcDateTime">2020-05-04T14:45:45Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:45:45+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">14</I32>
            <I32 N="Millisecond">0</I32>
            <I32 N="Minute">45</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT0S</TS>
            <I32 N="Second">45</I32>
            <I64 N="Ticks">637242003450000000</I64>
            <I64 N="UtcTicks">637242003450000000</I64>
            <TS N="TimeOfDay">PT14H45M45S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="ContinuationToken" />
        <Obj N="BlobContainerClient" RefId="7">
            <TN RefId="7">
            <T>Azure.Storage.Blobs.BlobContainerClient</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.BlobContainerClient</ToString>
            <Props>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend</URI>
            <S N="AccountName">aadeploymentstor</S>
            <S N="Name">psdepend</S>
            </Props>
        </Obj>
        <Obj N="BlobContainerProperties" RefId="8">
            <TN RefId="8">
            <T>Azure.Storage.Blobs.Models.BlobContainerProperties</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.Models.BlobContainerProperties</ToString>
            <Props>
            <S N="LastModified">05/04/2020 14:45:45 +00:00</S>
            <S N="LeaseStatus">Unlocked</S>
            <S N="LeaseState">Available</S>
            <S N="LeaseDuration">Infinite</S>
            <S N="PublicAccess">BlobContainer</S>
            <B N="HasImmutabilityPolicy">false</B>
            <B N="HasLegalHold">false</B>
            <S N="DefaultEncryptionScope">$account-encryption-key</S>
            <B N="PreventEncryptionScopeOverride">false</B>
            <S N="ETag">"0x8D7F039D3D0C5C5"</S>
            <Obj N="Metadata" RefId="9">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <Obj N="Context" RefId="10">
            <TN RefId="9">
            <T>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
            <Props>
            <S N="StorageAccountName">aadeploymentstor</S>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <Ref N="Context" RefId="10" />
            <S N="Name"></S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="TableStorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</S>
            <Nil N="Track2OauthToken" />
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="11">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <S N="Name">psdepend</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzStorageContext {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
        <Props>
        <S N="StorageAccountName">aadeploymentstor</S>
        <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
        <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
        <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
        <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
        <Obj N="Context" RefId="1">
            <TNRef RefId="0" />
            <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
            <Props>
            <S N="StorageAccountName">aadeploymentstor</S>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <Ref N="Context" RefId="1" />
            <S N="Name"></S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="TableStorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</S>
            <Nil N="Track2OauthToken" />
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="2">
                <TN RefId="1">
                <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
                <T>System.Object</T>
                </TN>
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <S N="Name"></S>
        <Obj N="StorageAccount" RefId="3">
            <TN RefId="2">
            <T>Microsoft.Azure.Storage.CloudStorageAccount</T>
            <T>System.Object</T>
            </TN>
            <ToString>BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=[key hidden]</ToString>
            <Props>
            <URI N="BlobEndpoint">https://aadeploymentstor.blob.core.windows.net/</URI>
            <URI N="QueueEndpoint">https://aadeploymentstor.queue.core.windows.net/</URI>
            <URI N="TableEndpoint">https://aadeploymentstor.table.core.windows.net/</URI>
            <URI N="FileEndpoint">https://aadeploymentstor.file.core.windows.net/</URI>
            <S N="BlobStorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/'; Secondary = ''</S>
            <S N="QueueStorageUri">Primary = 'https://aadeploymentstor.queue.core.windows.net/'; Secondary = ''</S>
            <S N="TableStorageUri">Primary = 'https://aadeploymentstor.table.core.windows.net/'; Secondary = ''</S>
            <S N="FileStorageUri">Primary = 'https://aadeploymentstor.file.core.windows.net/'; Secondary = ''</S>
            <S N="Credentials">Microsoft.Azure.Storage.Auth.StorageCredentials</S>
            </Props>
        </Obj>
        <Obj N="TableStorageAccount" RefId="4">
            <TN RefId="3">
            <T>Microsoft.Azure.Cosmos.Table.CloudStorageAccount</T>
            <T>System.Object</T>
            </TN>
            <ToString>BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</ToString>
            <Props>
            <URI N="TableEndpoint">https://aadeploymentstor.table.core.windows.net/</URI>
            <S N="TableStorageUri">Primary = 'https://aadeploymentstor.table.core.windows.net/'; Secondary = ''</S>
            <S N="Credentials">Microsoft.Azure.Cosmos.Table.StorageCredentials</S>
            </Props>
        </Obj>
        <Nil N="Track2OauthToken" />
        <S N="EndPointSuffix">core.windows.net/</S>
        <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
        <Ref N="ExtendedProperties" RefId="2" />
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzStorageBlobSASToken {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <S>https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip?sv=2019-02-02&amp;sr=b&amp;sig=if5HREXrRThQDVCvfCQI3ukJTvGtsJvQMNB6nkBkX4E%3D&amp;se=2020-05-12T12%3A30%3A57Z&amp;sp=r</S>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Set-AzStorageBlobContent {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob</T>
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob</ToString>
        <Props>
        <Obj N="ICloudBlob" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Storage.Blob.CloudBlockBlob</T>
            <T>Microsoft.Azure.Storage.Blob.CloudBlob</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.CloudBlockBlob</ToString>
            <Props>
            <I32 N="StreamWriteSizeInBytes">4194304</I32>
            <S N="ServiceClient">Microsoft.Azure.Storage.Blob.CloudBlobClient</S>
            <I32 N="StreamMinimumReadSizeInBytes">4194304</I32>
            <S N="Properties">Microsoft.Azure.Storage.Blob.BlobProperties</S>
            <Obj N="Metadata" RefId="2">
                <TN RefId="2">
                <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
                <T>System.Object</T>
                </TN>
                <DCT />
            </Obj>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip</URI>
            <S N="StorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip'; Secondary = ''</S>
            <Nil N="SnapshotTime" />
            <B N="IsSnapshot">false</B>
            <B N="IsDeleted">false</B>
            <URI N="SnapshotQualifiedUri">https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip</URI>
            <S N="SnapshotQualifiedStorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip'; Secondary = ''</S>
            <Nil N="CopyState" />
            <S N="Name">PSDepend.zip</S>
            <S N="Container">Microsoft.Azure.Storage.Blob.CloudBlobContainer</S>
            <S N="Parent">Microsoft.Azure.Storage.Blob.CloudBlobDirectory</S>
            <S N="BlobType">BlockBlob</S>
            </Props>
        </Obj>
        <Obj N="BlobType" RefId="3">
            <TN RefId="3">
            <T>Microsoft.Azure.Storage.Blob.BlobType</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>BlockBlob</ToString>
            <I32>2</I32>
        </Obj>
        <I64 N="Length">2274</I64>
        <B N="IsDeleted">false</B>
        <Obj N="BlobClient" RefId="4">
            <TN RefId="4">
            <T>Azure.Storage.Blobs.BlobClient</T>
            <T>Azure.Storage.Blobs.Specialized.BlobBaseClient</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.BlobClient</ToString>
            <Props>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip</URI>
            <S N="AccountName">aadeploymentstor</S>
            <S N="BlobContainerName">psdepend</S>
            <S N="Name">PSDepend.zip</S>
            </Props>
        </Obj>
        <Obj N="BlobProperties" RefId="5">
            <TN RefId="5">
            <T>Azure.Storage.Blobs.Models.BlobProperties</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.Models.BlobProperties</ToString>
            <Props>
            <S N="LastModified">05/12/2020 11:22:11 +00:00</S>
            <S N="CreatedOn">05/04/2020 14:45:45 +00:00</S>
            <Obj N="Metadata" RefId="6">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            <S N="BlobType">Block</S>
            <S N="CopyCompletedOn">01/01/0001 00:00:00 +00:00</S>
            <Nil N="CopyStatusDescription" />
            <Nil N="CopyId" />
            <Nil N="CopyProgress" />
            <Nil N="CopySource" />
            <S N="CopyStatus">Pending</S>
            <B N="IsIncrementalCopy">false</B>
            <Nil N="DestinationSnapshot" />
            <S N="LeaseDuration">Infinite</S>
            <S N="LeaseState">Available</S>
            <S N="LeaseStatus">Unlocked</S>
            <I64 N="ContentLength">2274</I64>
            <S N="ContentType">application/octet-stream</S>
            <S N="ETag">"0x8D7F666B761B3E1"</S>
            <BA N="ContentHash">Oz7uCTeqWbwPHzSXuNcHFw==</BA>
            <Nil N="ContentEncoding" />
            <Nil N="ContentDisposition" />
            <Nil N="ContentLanguage" />
            <Nil N="CacheControl" />
            <I64 N="BlobSequenceNumber">0</I64>
            <S N="AcceptRanges">bytes</S>
            <I32 N="BlobCommittedBlockCount">0</I32>
            <B N="IsServerEncrypted">true</B>
            <Nil N="EncryptionKeySha256" />
            <Nil N="EncryptionScope" />
            <S N="AccessTier">Hot</S>
            <B N="AccessTierInferred">true</B>
            <Nil N="ArchiveStatus" />
            <S N="AccessTierChangedOn">01/01/0001 00:00:00 +00:00</S>
            </Props>
        </Obj>
        <Nil N="RemainingDaysBeforePermanentDelete" />
        <S N="ContentType">application/octet-stream</S>
        <Obj N="LastModified" RefId="7">
            <TN RefId="6">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/12/2020 11:22:11 +00:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-12T11:22:11</DT>
            <DT N="UtcDateTime">2020-05-12T11:22:11Z</DT>
            <DT N="LocalDateTime">2020-05-12T14:22:11+03:00</DT>
            <DT N="Date">2020-05-12T00:00:00</DT>
            <I32 N="Day">12</I32>
            <S N="DayOfWeek">Tuesday</S>
            <I32 N="DayOfYear">133</I32>
            <I32 N="Hour">11</I32>
            <I32 N="Millisecond">0</I32>
            <I32 N="Minute">22</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT0S</TS>
            <I32 N="Second">11</I32>
            <I64 N="Ticks">637248793310000000</I64>
            <I64 N="UtcTicks">637248793310000000</I64>
            <TS N="TimeOfDay">PT11H22M11S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="SnapshotTime" />
        <Nil N="ContinuationToken" />
        <Obj N="Context" RefId="8">
            <TN RefId="7">
            <T>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
            <Props>
            <S N="StorageAccountName">aadeploymentstor</S>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <Ref N="Context" RefId="8" />
            <S N="Name"></S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="TableStorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</S>
            <Nil N="Track2OauthToken" />
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="9">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <S N="Name">PSDepend.zip</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }

            It 'should get an Automation account' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled Get-AzAutomationAccount -Exactly 1 -Scope It
                }
            }

            It 'should query the Automation account for already imported module' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled Get-AzAutomationModule -Exactly 1 -Scope It
                }
            }

            It 'should import the module into Automation account' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled New-AzAutomationModule -Exactly 1 -Scope It
                }
            }

            It 'should use a Storage account' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled Get-AzStorageAccount -Exactly 1 -Scope It
                    Assert-MockCalled Get-AzStorageContainer -Exactly 1 -Scope It
                    Assert-MockCalled Get-AzStorageAccountKey -Exactly 1 -Scope It
                    Assert-MockCalled New-AzStorageContainer -Exactly 0 -Scope It
                    Assert-MockCalled New-AzStorageContext -Exactly 1 -Scope It
                    Assert-MockCalled New-AzStorageBlobSASToken -Exactly 1 -Scope It
                    Assert-MockCalled Set-AzStorageBlobContent -Exactly 1 -Scope It
                }
            }
        }

        Context 'Script Logic - Source Module' {

            Mock Get-AzAutomationAccount {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.AutomationAccount</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.AutomationAccount</ToString>
        <Props>
        <S N="SubscriptionId">c49124fa-befd-4207-a3b7-29c95c41a964</S>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AAName</S>
        <S N="Location">westeurope</S>
        <S N="State">Ok</S>
        <S N="Plan">Basic</S>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>10/02/2017 16:05:15 +03:00</ToString>
            <Props>
            <DT N="DateTime">2017-10-02T16:05:15.39</DT>
            <DT N="UtcDateTime">2017-10-02T13:05:15.39Z</DT>
            <DT N="LocalDateTime">2017-10-02T16:05:15.39+03:00</DT>
            <DT N="Date">2017-10-02T00:00:00</DT>
            <I32 N="Day">2</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">275</I32>
            <I32 N="Hour">16</I32>
            <I32 N="Millisecond">390</I32>
            <I32 N="Minute">5</I32>
            <I32 N="Month">10</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">15</I32>
            <I64 N="Ticks">636425571153900000</I64>
            <I64 N="UtcTicks">636425463153900000</I64>
            <TS N="TimeOfDay">PT16H5M15.39S</TS>
            <I32 N="Year">2017</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>03/22/2020 10:41:20 +02:00</ToString>
            <Props>
            <DT N="DateTime">2020-03-22T10:41:20.57</DT>
            <DT N="UtcDateTime">2020-03-22T08:41:20.57Z</DT>
            <DT N="LocalDateTime">2020-03-22T10:41:20.57+02:00</DT>
            <DT N="Date">2020-03-22T00:00:00</DT>
            <I32 N="Day">22</I32>
            <S N="DayOfWeek">Sunday</S>
            <I32 N="DayOfYear">82</I32>
            <I32 N="Hour">10</I32>
            <I32 N="Millisecond">570</I32>
            <I32 N="Minute">41</I32>
            <I32 N="Month">3</I32>
            <TS N="Offset">PT2H</TS>
            <I32 N="Second">20</I32>
            <I64 N="Ticks">637204704805700000</I64>
            <I64 N="UtcTicks">637204632805700000</I64>
            <TS N="TimeOfDay">PT10H41M20.57S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="LastModifiedBy" />
        <Obj N="Tags" RefId="3">
            <TN RefId="2">
            <T>System.Collections.Hashtable</T>
            <T>System.Object</T>
            </TN>
            <DCT>
            <En>
                <S N="Key">environment</S>
                <S N="Value">Test</S>
            </En>
            </DCT>
        </Obj>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzAutomationModule {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.Module</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.Module</ToString>
        <Props>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AANAme</S>
        <S N="Name">PSDepend</S>
        <B N="IsGlobal">false</B>
        <S N="Version">0.3.2</S>
        <I64 N="SizeInBytes">71093</I64>
        <I32 N="ActivityCount">8</I32>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 17:42:32 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:42:32.617</DT>
            <DT N="UtcDateTime">2020-05-04T14:42:32.617Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:42:32.617+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">617</I32>
            <I32 N="Minute">42</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">32</I32>
            <I64 N="Ticks">637242109526170000</I64>
            <I64 N="UtcTicks">637242001526170000</I64>
            <TS N="TimeOfDay">PT17H42M32.617S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>05/04/2020 17:44:14 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:44:14.537</DT>
            <DT N="UtcDateTime">2020-05-04T14:44:14.537Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:44:14.537+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">537</I32>
            <I32 N="Minute">44</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">14</I32>
            <I64 N="Ticks">637242110545370000</I64>
            <I64 N="UtcTicks">637242002545370000</I64>
            <TS N="TimeOfDay">PT17H44M14.537S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <S N="ProvisioningState">Succeeded</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzAutomationModule {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Automation.Model.Module</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Commands.Automation.Model.Module</ToString>
        <Props>
        <S N="ResourceGroupName">AAResourceGroupName</S>
        <S N="AutomationAccountName">AAName</S>
        <S N="Name">PSDepend</S>
        <B N="IsGlobal">false</B>
        <S N="Version">0.3.2</S>
        <I64 N="SizeInBytes">71093</I64>
        <I32 N="ActivityCount">8</I32>
        <Obj N="CreationTime" RefId="1">
            <TN RefId="1">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 17:42:32 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T17:42:32.617</DT>
            <DT N="UtcDateTime">2020-05-04T14:42:32.617Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:42:32.617+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">17</I32>
            <I32 N="Millisecond">617</I32>
            <I32 N="Minute">42</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">32</I32>
            <I64 N="Ticks">637242109526170000</I64>
            <I64 N="UtcTicks">637242001526170000</I64>
            <TS N="TimeOfDay">PT17H42M32.617S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Obj N="LastModifiedTime" RefId="2">
            <TNRef RefId="1" />
            <ToString>05/12/2020 14:05:27 +03:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-12T14:05:27.527</DT>
            <DT N="UtcDateTime">2020-05-12T11:05:27.527Z</DT>
            <DT N="LocalDateTime">2020-05-12T14:05:27.527+03:00</DT>
            <DT N="Date">2020-05-12T00:00:00</DT>
            <I32 N="Day">12</I32>
            <S N="DayOfWeek">Tuesday</S>
            <I32 N="DayOfYear">133</I32>
            <I32 N="Hour">14</I32>
            <I32 N="Millisecond">527</I32>
            <I32 N="Minute">5</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT3H</TS>
            <I32 N="Second">27</I32>
            <I64 N="Ticks">637248891275270000</I64>
            <I64 N="UtcTicks">637248783275270000</I64>
            <TS N="TimeOfDay">PT14H5M27.527S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <S N="ProvisioningState">Succeeded</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzStorageAccount {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Commands.Management.Storage.Models.PSStorageAccount</T>
        <T>System.Object</T>
        </TN>
        <ToString />
        <Props>
        <S N="ResourceGroupName">SATestAutomationAndMonitoringRG</S>
        <S N="StorageAccountName">aadeploymentstor</S>
        <S N="Id">/subscriptions/eb31e8d0-5a14-4eea-87b9-66581523e545/resourceGroups/SATestAutomationAndMonitoringRG/providers/Microsoft.Storage/storageAccounts/aadeploymentstor</S>
        <S N="Location">westeurope</S>
        <Obj N="Sku" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Commands.Management.Storage.Models.PSSku</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Commands.Management.Storage.Models.PSSku</ToString>
            <Props>
            <S N="Name">Standard_LRS</S>
            <S N="Tier">Standard</S>
            <Nil N="ResourceType" />
            <Nil N="Kind" />
            <Nil N="Locations" />
            <Nil N="Capabilities" />
            <Nil N="Restrictions" />
            </Props>
        </Obj>
        <S N="Kind">StorageV2</S>
        <Obj N="Encryption" RefId="2">
            <TN RefId="2">
            <T>Microsoft.Azure.Management.Storage.Models.Encryption</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Management.Storage.Models.Encryption</ToString>
            <Props>
            <S N="Services">Microsoft.Azure.Management.Storage.Models.EncryptionServices</S>
            <S N="KeySource">Microsoft.Storage</S>
            <Nil N="KeyVaultProperties" />
            </Props>
        </Obj>
        <Obj N="AccessTier" RefId="3">
            <TN RefId="3">
            <T>Microsoft.Azure.Management.Storage.Models.AccessTier</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Hot</ToString>
            <I32>0</I32>
        </Obj>
        <DT N="CreationTime">2020-05-03T10:59:39.4378401Z</DT>
        <Nil N="CustomDomain" />
        <Nil N="Identity" />
        <Nil N="LastGeoFailoverTime" />
        <Obj N="PrimaryEndpoints" RefId="4">
            <TN RefId="4">
            <T>Microsoft.Azure.Management.Storage.Models.Endpoints</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Management.Storage.Models.Endpoints</ToString>
            <Props>
            <S N="Blob">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="Queue">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="Table">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="File">https://aadeploymentstor.file.core.windows.net/</S>
            <S N="Web">https://aadeploymentstor.z6.web.core.windows.net/</S>
            <S N="Dfs">https://aadeploymentstor.dfs.core.windows.net/</S>
            <Nil N="MicrosoftEndpoints" />
            <Nil N="InternetEndpoints" />
            </Props>
        </Obj>
        <S N="PrimaryLocation">westeurope</S>
        <Obj N="ProvisioningState" RefId="5">
            <TN RefId="5">
            <T>Microsoft.Azure.Management.Storage.Models.ProvisioningState</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Succeeded</ToString>
            <I32>2</I32>
        </Obj>
        <Nil N="SecondaryEndpoints" />
        <Nil N="SecondaryLocation" />
        <Obj N="StatusOfPrimary" RefId="6">
            <TN RefId="6">
            <T>Microsoft.Azure.Management.Storage.Models.AccountStatus</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Available</ToString>
            <I32>0</I32>
        </Obj>
        <Nil N="StatusOfSecondary" />
        <Obj N="Tags" RefId="7">
            <TN RefId="7">
            <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
            <T>System.Object</T>
            </TN>
            <DCT>
            <En>
                <S N="Key">environment</S>
                <S N="Value">Test</S>
            </En>
            </DCT>
        </Obj>
        <B N="EnableHttpsTrafficOnly">true</B>
        <Nil N="AzureFilesIdentityBasedAuth" />
        <Nil N="EnableHierarchicalNamespace" />
        <S N="LargeFileSharesState">Disabled</S>
        <Obj N="NetworkRuleSet" RefId="8">
            <TN RefId="8">
            <T>Microsoft.Azure.Commands.Management.Storage.Models.PSNetworkRuleSet</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Commands.Management.Storage.Models.PSNetworkRuleSet</ToString>
            <Props>
            <Obj N="IpRules" RefId="9">
                <TN RefId="9">
                <T>Microsoft.Azure.Commands.Management.Storage.Models.PSIpRule[]</T>
                <T>System.Array</T>
                <T>System.Object</T>
                </TN>
                <LST />
            </Obj>
            <Obj N="VirtualNetworkRules" RefId="10">
                <TN RefId="10">
                <T>Microsoft.Azure.Commands.Management.Storage.Models.PSVirtualNetworkRule[]</T>
                <T>System.Array</T>
                <T>System.Object</T>
                </TN>
                <LST />
            </Obj>
            <S N="Bypass">AzureServices</S>
            <S N="DefaultAction">Allow</S>
            </Props>
        </Obj>
        <Nil N="GeoReplicationStats" />
        <Obj N="Context" RefId="11">
            <TN RefId="11">
            <T>Microsoft.WindowsAzure.Commands.Common.Storage.LazyAzureStorageContext</T>
            <T>Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.WindowsAzure.Commands.Common.Storage.LazyAzureStorageContext</ToString>
            <Props>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="StorageAccountName">aadeploymentstor</S>
            <Ref N="Context" RefId="11" />
            <S N="Name">aadeploymentstor</S>
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="12">
                <TNRef RefId="7" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <Obj N="ExtendedProperties" RefId="13">
            <TNRef RefId="7" />
            <DCT />
        </Obj>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzStorageContainer {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer</T>
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer</ToString>
        <Props>
        <Obj N="CloudBlobContainer" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Storage.Blob.CloudBlobContainer</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.CloudBlobContainer</ToString>
            <Props>
            <S N="ServiceClient">Microsoft.Azure.Storage.Blob.CloudBlobClient</S>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend</URI>
            <S N="StorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/psdepend'; Secondary = ''</S>
            <S N="Name">psdepend</S>
            <Obj N="Metadata" RefId="2">
                <TN RefId="2">
                <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
                <T>System.Object</T>
                </TN>
                <DCT />
            </Obj>
            <S N="Properties">Microsoft.Azure.Storage.Blob.BlobContainerProperties</S>
            </Props>
        </Obj>
        <Obj N="Permission" RefId="3">
            <TN RefId="3">
            <T>Microsoft.Azure.Storage.Blob.BlobContainerPermissions</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.BlobContainerPermissions</ToString>
            <Props>
            <S N="PublicAccess">Container</S>
            <Obj N="SharedAccessPolicies" RefId="4">
                <TN RefId="4">
                <T>Microsoft.Azure.Storage.Blob.SharedAccessBlobPolicies</T>
                <T>System.Object</T>
                </TN>
                <IE />
            </Obj>
            </Props>
        </Obj>
        <Obj N="PublicAccess" RefId="5">
            <TN RefId="5">
            <T>Microsoft.Azure.Storage.Blob.BlobContainerPublicAccessType</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Container</ToString>
            <I32>1</I32>
        </Obj>
        <Obj N="LastModified" RefId="6">
            <TN RefId="6">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 14:45:45 +00:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T14:45:45</DT>
            <DT N="UtcDateTime">2020-05-04T14:45:45Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:45:45+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">14</I32>
            <I32 N="Millisecond">0</I32>
            <I32 N="Minute">45</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT0S</TS>
            <I32 N="Second">45</I32>
            <I64 N="Ticks">637242003450000000</I64>
            <I64 N="UtcTicks">637242003450000000</I64>
            <TS N="TimeOfDay">PT14H45M45S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="ContinuationToken" />
        <Obj N="BlobContainerClient" RefId="7">
            <TN RefId="7">
            <T>Azure.Storage.Blobs.BlobContainerClient</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.BlobContainerClient</ToString>
            <Props>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend</URI>
            <S N="AccountName">aadeploymentstor</S>
            <S N="Name">psdepend</S>
            </Props>
        </Obj>
        <Obj N="BlobContainerProperties" RefId="8">
            <TN RefId="8">
            <T>Azure.Storage.Blobs.Models.BlobContainerProperties</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.Models.BlobContainerProperties</ToString>
            <Props>
            <S N="LastModified">05/04/2020 14:45:45 +00:00</S>
            <S N="LeaseStatus">Unlocked</S>
            <S N="LeaseState">Available</S>
            <S N="LeaseDuration">Infinite</S>
            <S N="PublicAccess">BlobContainer</S>
            <B N="HasImmutabilityPolicy">false</B>
            <B N="HasLegalHold">false</B>
            <S N="DefaultEncryptionScope">$account-encryption-key</S>
            <B N="PreventEncryptionScopeOverride">false</B>
            <S N="ETag">"0x8D7F039D3D0C5C5"</S>
            <Obj N="Metadata" RefId="9">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <Obj N="Context" RefId="10">
            <TN RefId="9">
            <T>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
            <Props>
            <S N="StorageAccountName">aadeploymentstor</S>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <Ref N="Context" RefId="10" />
            <S N="Name"></S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="TableStorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</S>
            <Nil N="Track2OauthToken" />
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="11">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <S N="Name">psdepend</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Get-AzStorageAccountKey {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.Azure.Management.Storage.Models.StorageAccountKey</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.Azure.Management.Storage.Models.StorageAccountKey</ToString>
        <Props>
        <S N="KeyName">key1</S>
        <S N="Value">aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
        <Obj N="Permissions" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Management.Storage.Models.KeyPermission</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Full</ToString>
            <I32>1</I32>
        </Obj>
        </Props>
    </Obj>
    <Obj RefId="2">
        <TNRef RefId="0" />
        <ToString>Microsoft.Azure.Management.Storage.Models.StorageAccountKey</ToString>
        <Props>
        <S N="KeyName">key2</S>
        <S N="Value">lCvSampwF8ZkAgjaDJXpw3akynx5aEecS3Wg/WDeygQd7l+/bXMZD+uk0Dd0Jbk2tZ7nBO39W0fGXsZBQtK0zQ==</S>
        <Obj N="Permissions" RefId="3">
            <TNRef RefId="1" />
            <ToString>Full</ToString>
            <I32>1</I32>
        </Obj>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzStorageContainer {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer</T>
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer</ToString>
        <Props>
        <Obj N="CloudBlobContainer" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Storage.Blob.CloudBlobContainer</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.CloudBlobContainer</ToString>
            <Props>
            <S N="ServiceClient">Microsoft.Azure.Storage.Blob.CloudBlobClient</S>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend</URI>
            <S N="StorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/psdepend'; Secondary = ''</S>
            <S N="Name">psdepend</S>
            <Obj N="Metadata" RefId="2">
                <TN RefId="2">
                <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
                <T>System.Object</T>
                </TN>
                <DCT />
            </Obj>
            <S N="Properties">Microsoft.Azure.Storage.Blob.BlobContainerProperties</S>
            </Props>
        </Obj>
        <Obj N="Permission" RefId="3">
            <TN RefId="3">
            <T>Microsoft.Azure.Storage.Blob.BlobContainerPermissions</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.BlobContainerPermissions</ToString>
            <Props>
            <S N="PublicAccess">Container</S>
            <Obj N="SharedAccessPolicies" RefId="4">
                <TN RefId="4">
                <T>Microsoft.Azure.Storage.Blob.SharedAccessBlobPolicies</T>
                <T>System.Object</T>
                </TN>
                <IE />
            </Obj>
            </Props>
        </Obj>
        <Obj N="PublicAccess" RefId="5">
            <TN RefId="5">
            <T>Microsoft.Azure.Storage.Blob.BlobContainerPublicAccessType</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>Container</ToString>
            <I32>1</I32>
        </Obj>
        <Obj N="LastModified" RefId="6">
            <TN RefId="6">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/04/2020 14:45:45 +00:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-04T14:45:45</DT>
            <DT N="UtcDateTime">2020-05-04T14:45:45Z</DT>
            <DT N="LocalDateTime">2020-05-04T17:45:45+03:00</DT>
            <DT N="Date">2020-05-04T00:00:00</DT>
            <I32 N="Day">4</I32>
            <S N="DayOfWeek">Monday</S>
            <I32 N="DayOfYear">125</I32>
            <I32 N="Hour">14</I32>
            <I32 N="Millisecond">0</I32>
            <I32 N="Minute">45</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT0S</TS>
            <I32 N="Second">45</I32>
            <I64 N="Ticks">637242003450000000</I64>
            <I64 N="UtcTicks">637242003450000000</I64>
            <TS N="TimeOfDay">PT14H45M45S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="ContinuationToken" />
        <Obj N="BlobContainerClient" RefId="7">
            <TN RefId="7">
            <T>Azure.Storage.Blobs.BlobContainerClient</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.BlobContainerClient</ToString>
            <Props>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend</URI>
            <S N="AccountName">aadeploymentstor</S>
            <S N="Name">psdepend</S>
            </Props>
        </Obj>
        <Obj N="BlobContainerProperties" RefId="8">
            <TN RefId="8">
            <T>Azure.Storage.Blobs.Models.BlobContainerProperties</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.Models.BlobContainerProperties</ToString>
            <Props>
            <S N="LastModified">05/04/2020 14:45:45 +00:00</S>
            <S N="LeaseStatus">Unlocked</S>
            <S N="LeaseState">Available</S>
            <S N="LeaseDuration">Infinite</S>
            <S N="PublicAccess">BlobContainer</S>
            <B N="HasImmutabilityPolicy">false</B>
            <B N="HasLegalHold">false</B>
            <S N="DefaultEncryptionScope">$account-encryption-key</S>
            <B N="PreventEncryptionScopeOverride">false</B>
            <S N="ETag">"0x8D7F039D3D0C5C5"</S>
            <Obj N="Metadata" RefId="9">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <Obj N="Context" RefId="10">
            <TN RefId="9">
            <T>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
            <Props>
            <S N="StorageAccountName">aadeploymentstor</S>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <Ref N="Context" RefId="10" />
            <S N="Name"></S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="TableStorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</S>
            <Nil N="Track2OauthToken" />
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="11">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <S N="Name">psdepend</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzStorageContext {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
        <Props>
        <S N="StorageAccountName">aadeploymentstor</S>
        <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
        <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
        <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
        <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
        <Obj N="Context" RefId="1">
            <TNRef RefId="0" />
            <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
            <Props>
            <S N="StorageAccountName">aadeploymentstor</S>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <Ref N="Context" RefId="1" />
            <S N="Name"></S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="TableStorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</S>
            <Nil N="Track2OauthToken" />
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="2">
                <TN RefId="1">
                <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
                <T>System.Object</T>
                </TN>
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <S N="Name"></S>
        <Obj N="StorageAccount" RefId="3">
            <TN RefId="2">
            <T>Microsoft.Azure.Storage.CloudStorageAccount</T>
            <T>System.Object</T>
            </TN>
            <ToString>BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=[key hidden]</ToString>
            <Props>
            <URI N="BlobEndpoint">https://aadeploymentstor.blob.core.windows.net/</URI>
            <URI N="QueueEndpoint">https://aadeploymentstor.queue.core.windows.net/</URI>
            <URI N="TableEndpoint">https://aadeploymentstor.table.core.windows.net/</URI>
            <URI N="FileEndpoint">https://aadeploymentstor.file.core.windows.net/</URI>
            <S N="BlobStorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/'; Secondary = ''</S>
            <S N="QueueStorageUri">Primary = 'https://aadeploymentstor.queue.core.windows.net/'; Secondary = ''</S>
            <S N="TableStorageUri">Primary = 'https://aadeploymentstor.table.core.windows.net/'; Secondary = ''</S>
            <S N="FileStorageUri">Primary = 'https://aadeploymentstor.file.core.windows.net/'; Secondary = ''</S>
            <S N="Credentials">Microsoft.Azure.Storage.Auth.StorageCredentials</S>
            </Props>
        </Obj>
        <Obj N="TableStorageAccount" RefId="4">
            <TN RefId="3">
            <T>Microsoft.Azure.Cosmos.Table.CloudStorageAccount</T>
            <T>System.Object</T>
            </TN>
            <ToString>BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</ToString>
            <Props>
            <URI N="TableEndpoint">https://aadeploymentstor.table.core.windows.net/</URI>
            <S N="TableStorageUri">Primary = 'https://aadeploymentstor.table.core.windows.net/'; Secondary = ''</S>
            <S N="Credentials">Microsoft.Azure.Cosmos.Table.StorageCredentials</S>
            </Props>
        </Obj>
        <Nil N="Track2OauthToken" />
        <S N="EndPointSuffix">core.windows.net/</S>
        <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
        <Ref N="ExtendedProperties" RefId="2" />
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock New-AzStorageBlobSASToken {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <S>https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip?sv=2019-02-02&amp;sr=b&amp;sig=if5HREXrRThQDVCvfCQI3ukJTvGtsJvQMNB6nkBkX4E%3D&amp;se=2020-05-12T12%3A30%3A57Z&amp;sp=r</S>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }
            Mock Set-AzStorageBlobContent {
                #region MockData
                $mockedSerializedData = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <Obj RefId="0">
        <TN RefId="0">
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob</T>
        <T>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBase</T>
        <T>System.Object</T>
        </TN>
        <ToString>Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob</ToString>
        <Props>
        <Obj N="ICloudBlob" RefId="1">
            <TN RefId="1">
            <T>Microsoft.Azure.Storage.Blob.CloudBlockBlob</T>
            <T>Microsoft.Azure.Storage.Blob.CloudBlob</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.Azure.Storage.Blob.CloudBlockBlob</ToString>
            <Props>
            <I32 N="StreamWriteSizeInBytes">4194304</I32>
            <S N="ServiceClient">Microsoft.Azure.Storage.Blob.CloudBlobClient</S>
            <I32 N="StreamMinimumReadSizeInBytes">4194304</I32>
            <S N="Properties">Microsoft.Azure.Storage.Blob.BlobProperties</S>
            <Obj N="Metadata" RefId="2">
                <TN RefId="2">
                <T>System.Collections.Generic.Dictionary`2[[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.String, System.Private.CoreLib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]</T>
                <T>System.Object</T>
                </TN>
                <DCT />
            </Obj>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip</URI>
            <S N="StorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip'; Secondary = ''</S>
            <Nil N="SnapshotTime" />
            <B N="IsSnapshot">false</B>
            <B N="IsDeleted">false</B>
            <URI N="SnapshotQualifiedUri">https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip</URI>
            <S N="SnapshotQualifiedStorageUri">Primary = 'https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip'; Secondary = ''</S>
            <Nil N="CopyState" />
            <S N="Name">PSDepend.zip</S>
            <S N="Container">Microsoft.Azure.Storage.Blob.CloudBlobContainer</S>
            <S N="Parent">Microsoft.Azure.Storage.Blob.CloudBlobDirectory</S>
            <S N="BlobType">BlockBlob</S>
            </Props>
        </Obj>
        <Obj N="BlobType" RefId="3">
            <TN RefId="3">
            <T>Microsoft.Azure.Storage.Blob.BlobType</T>
            <T>System.Enum</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>BlockBlob</ToString>
            <I32>2</I32>
        </Obj>
        <I64 N="Length">2274</I64>
        <B N="IsDeleted">false</B>
        <Obj N="BlobClient" RefId="4">
            <TN RefId="4">
            <T>Azure.Storage.Blobs.BlobClient</T>
            <T>Azure.Storage.Blobs.Specialized.BlobBaseClient</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.BlobClient</ToString>
            <Props>
            <URI N="Uri">https://aadeploymentstor.blob.core.windows.net/psdepend/PSDepend.zip</URI>
            <S N="AccountName">aadeploymentstor</S>
            <S N="BlobContainerName">psdepend</S>
            <S N="Name">PSDepend.zip</S>
            </Props>
        </Obj>
        <Obj N="BlobProperties" RefId="5">
            <TN RefId="5">
            <T>Azure.Storage.Blobs.Models.BlobProperties</T>
            <T>System.Object</T>
            </TN>
            <ToString>Azure.Storage.Blobs.Models.BlobProperties</ToString>
            <Props>
            <S N="LastModified">05/12/2020 11:22:11 +00:00</S>
            <S N="CreatedOn">05/04/2020 14:45:45 +00:00</S>
            <Obj N="Metadata" RefId="6">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            <S N="BlobType">Block</S>
            <S N="CopyCompletedOn">01/01/0001 00:00:00 +00:00</S>
            <Nil N="CopyStatusDescription" />
            <Nil N="CopyId" />
            <Nil N="CopyProgress" />
            <Nil N="CopySource" />
            <S N="CopyStatus">Pending</S>
            <B N="IsIncrementalCopy">false</B>
            <Nil N="DestinationSnapshot" />
            <S N="LeaseDuration">Infinite</S>
            <S N="LeaseState">Available</S>
            <S N="LeaseStatus">Unlocked</S>
            <I64 N="ContentLength">2274</I64>
            <S N="ContentType">application/octet-stream</S>
            <S N="ETag">"0x8D7F666B761B3E1"</S>
            <BA N="ContentHash">Oz7uCTeqWbwPHzSXuNcHFw==</BA>
            <Nil N="ContentEncoding" />
            <Nil N="ContentDisposition" />
            <Nil N="ContentLanguage" />
            <Nil N="CacheControl" />
            <I64 N="BlobSequenceNumber">0</I64>
            <S N="AcceptRanges">bytes</S>
            <I32 N="BlobCommittedBlockCount">0</I32>
            <B N="IsServerEncrypted">true</B>
            <Nil N="EncryptionKeySha256" />
            <Nil N="EncryptionScope" />
            <S N="AccessTier">Hot</S>
            <B N="AccessTierInferred">true</B>
            <Nil N="ArchiveStatus" />
            <S N="AccessTierChangedOn">01/01/0001 00:00:00 +00:00</S>
            </Props>
        </Obj>
        <Nil N="RemainingDaysBeforePermanentDelete" />
        <S N="ContentType">application/octet-stream</S>
        <Obj N="LastModified" RefId="7">
            <TN RefId="6">
            <T>System.DateTimeOffset</T>
            <T>System.ValueType</T>
            <T>System.Object</T>
            </TN>
            <ToString>05/12/2020 11:22:11 +00:00</ToString>
            <Props>
            <DT N="DateTime">2020-05-12T11:22:11</DT>
            <DT N="UtcDateTime">2020-05-12T11:22:11Z</DT>
            <DT N="LocalDateTime">2020-05-12T14:22:11+03:00</DT>
            <DT N="Date">2020-05-12T00:00:00</DT>
            <I32 N="Day">12</I32>
            <S N="DayOfWeek">Tuesday</S>
            <I32 N="DayOfYear">133</I32>
            <I32 N="Hour">11</I32>
            <I32 N="Millisecond">0</I32>
            <I32 N="Minute">22</I32>
            <I32 N="Month">5</I32>
            <TS N="Offset">PT0S</TS>
            <I32 N="Second">11</I32>
            <I64 N="Ticks">637248793310000000</I64>
            <I64 N="UtcTicks">637248793310000000</I64>
            <TS N="TimeOfDay">PT11H22M11S</TS>
            <I32 N="Year">2020</I32>
            </Props>
        </Obj>
        <Nil N="SnapshotTime" />
        <Nil N="ContinuationToken" />
        <Obj N="Context" RefId="8">
            <TN RefId="7">
            <T>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</T>
            <T>System.Object</T>
            </TN>
            <ToString>Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext</ToString>
            <Props>
            <S N="StorageAccountName">aadeploymentstor</S>
            <S N="BlobEndPoint">https://aadeploymentstor.blob.core.windows.net/</S>
            <S N="TableEndPoint">https://aadeploymentstor.table.core.windows.net/</S>
            <S N="QueueEndPoint">https://aadeploymentstor.queue.core.windows.net/</S>
            <S N="FileEndPoint">https://aadeploymentstor.file.core.windows.net/</S>
            <Ref N="Context" RefId="8" />
            <S N="Name"></S>
            <S N="StorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=[key hidden]</S>
            <S N="TableStorageAccount">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;DefaultEndpointsProtocol=https</S>
            <Nil N="Track2OauthToken" />
            <S N="EndPointSuffix">core.windows.net/</S>
            <S N="ConnectionString">BlobEndpoint=https://aadeploymentstor.blob.core.windows.net/;QueueEndpoint=https://aadeploymentstor.queue.core.windows.net/;TableEndpoint=https://aadeploymentstor.table.core.windows.net/;FileEndpoint=https://aadeploymentstor.file.core.windows.net/;AccountName=aadeploymentstor;AccountKey=aYnf1etfwPfXJ2viMYc/DdUcZPo2ysm/42Ov8zEewRGvv32c0VtumseRzoRDG75a7BgCNFiDR28y//xqqBB+Rw==</S>
            <Obj N="ExtendedProperties" RefId="9">
                <TNRef RefId="2" />
                <DCT />
            </Obj>
            </Props>
        </Obj>
        <S N="Name">PSDepend.zip</S>
        </Props>
    </Obj>
</Objs>
'@
                #endregion

                $data = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockedSerializedData)
                $data
            }

            It 'should get an Automation account' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled Get-AzAutomationAccount -Exactly 1 -Scope It
                }
            }

            It 'should query the Automation account for already imported module' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled Get-AzAutomationModule -Exactly 1 -Scope It
                }
            }

            It 'should import the module into Automation account' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled New-AzAutomationModule -Exactly 1 -Scope It
                }
            }

            It 'should use a Storage account' {
                {
                    Invoke-PSDeploy @Verbose -Path "$ProjectRoot\Tests\artifacts\DeploymentsAzureAutomationModule-PublicModule.psdeploy.ps1" -Force
                    Assert-MockCalled Get-AzStorageAccount -Exactly 1 -Scope It
                    Assert-MockCalled Get-AzStorageContainer -Exactly 1 -Scope It
                    Assert-MockCalled Get-AzStorageAccountKey -Exactly 1 -Scope It
                    Assert-MockCalled New-AzStorageContainer -Exactly 0 -Scope It
                    Assert-MockCalled New-AzStorageContext -Exactly 1 -Scope It
                    Assert-MockCalled New-AzStorageBlobSASToken -Exactly 1 -Scope It
                    Assert-MockCalled Set-AzStorageBlobContent -Exactly 1 -Scope It
                }
            }
        }
    }
}