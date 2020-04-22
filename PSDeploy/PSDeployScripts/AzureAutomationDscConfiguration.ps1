<#
    .SYNOPSIS
        Deploys a DSC configuration to an Azure Automation account.

    .DESCRIPTION
        Deploys a DSC configuration from a local source file to an Azure Automation account.


        Sample snippet for 'hybridWorkerConfiguration.ps1' configuration:

        By AzureAutomationDscConfiguration {
            FromSource "C:\Source\hybridWorkerConfiguration.ps1"
            To "MyAutomationAccountName"
            WithOptions @{
                ConfigurationDescription        = "My DSC configuration" # Optional
                ConfigurationTags               = @{key0="value0";key1="value1"} # Optional
                Published                       = $false # Optional
                LogVerbose                      = $false # Optional
                Published                       = $false # Optional
                Force                           = $false # Optional
                ResourceGroupName               = "MyAutomationAccount_ResourceGroupName"
                Compile                         = $false # Optional
                CompilationParameters           = @{parameter0="value0";parameter1="value1"} # Optional
                ConfigurationData               = @{AllNodes = @(@{NodeName = "localhost";Modules = @("PSDscResources")})}; # Optional
                IncrementNodeConfigurationBuild = $false # Optional
        }

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER ResourceGroupName
        The resource group of target Azure Automation account

    .PARAMETER ConfigurationDescription
        Configuration description

    .PARAMETER ConfigurationTags
        Tags to assign to the imported configuration

    .PARAMETER Published,
        Configuration should be published after import

    .PARAMETER LogVerbose,
        Configuration should log detailed information for compilation jobs

    .PARAMETER Force
        Overwrite an existing configuration with the same name if there is any

    .PARAMETER Compile
        Configuration should be compiled after import

    .PARAMETER CompilationParameters
        A dictionary of parameters to compile the DSC configuration

    .PARAMETER ConfigurationData
        A dictionary of configuration data to compile DSC configuration

    .PARAMETER IncrementNodeConfigurationBuild
        Create a new Node Configuration build version

    .OUTPUTS
        Microsoft.Azure.Commands.Automation.Model.DscConfiguration
#>

#Requires -modules Az.Automation
[CmdletBinding()]
[OutputType([Microsoft.Azure.Commands.Automation.Model.DscConfiguration])]
param(
    [ValidateScript( { $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    #region Import parameters
    [Parameter(Mandatory = $false)]
    [string]$ConfigurationDescription,

    [Parameter(Mandatory = $false)]
    [hashtable]$ConfigurationTags,

    [Parameter(Mandatory = $false)]
    [switch]$Published,

    [Parameter(Mandatory = $false)]
    [switch]$LogVerbose,

    [Parameter(Mandatory = $false)]
    [switch]$Force,
    #endregion

    #region Compilation parameters
    [Parameter(Mandatory = $false)]
    [switch]$Compile,

    [Parameter(Mandatory = $false)]
    [hashtable]$CompilationParameters,

    [Parameter(Mandatory = $false)]
    [hashtable]$ConfigurationData,

    [Parameter(Mandatory = $false)]
    [switch]$IncrementNodeConfigurationBuild
    #endregion
)

function New-DscNodeConfiguration {
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Automation.Model.CompilationJob])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConfigurationName,

        [Parameter(Mandatory = $false)]
        [hashtable]$CompilationParameters,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConfigurationData,

        [Parameter(Mandatory = $false)]
        [switch]$IncrementNodeConfigurationBuild,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AutomationAccountName
    )

    begin {
        Write-Verbose "Initiating '$ConfigurationName' configuration compilation job..."
    }

    process {
        #region Start-AzAutomationDscCompilationJob parameters
        $params = @{
            ConfigurationName     = $ConfigurationName
            AutomationAccountName = $AutomationAccountName
            ResourceGroupName     = $ResourceGroupName
            Verbose               = $VerbosePreference
        }

        if ($CompilationParameters) {
            $params['CompilationParameters'] = $CompilationParameters
        }

        if ($ConfigurationData) {
            $params['ConfigurationData'] = $ConfigurationData
        }

        if ($IncrementNodeConfigurationBuild) {
            $params['IncrementNodeConfigurationBuild'] = $IncrementNodeConfigurationBuild
        }
        #endregion

        $compilationJob = Start-AzAutomationDscCompilationJob @params

        while ($null -eq $compilationJob.EndTime -and $null -eq $compilationJob.Exception) {
            Write-Verbose "Compilation job status is: $($compilationJob.Status)"
            $compilationJob = $compilationJob | Get-AzAutomationDscCompilationJob
            Start-Sleep -Seconds 5
        }

        if ($compilationJob.Status -eq 'Completed') {
            Write-Verbose "Compilation job status is: $($compilationJob.Status)"

            #region Get-AzAutomationDscNodeConfiguration parameters
            $params = @{
                AutomationAccountName = $compilationJob.AutomationAccountName
                ResourceGroupName     = $compilationJob.ResourceGroupName
                Verbose               = $VerbosePreference
            }
            #endregion

            $compiledConfiguration = Get-AzAutomationDscNodeConfiguration @params | Where-Object -Property ConfigurationName -EQ $ConfigurationName
        }
        else {
            throw "The compilation job has failed. Check the Azure portal for the exception details."
        }
    }

    end {
        # Return the compilation job
        Write-Output $compiledConfiguration
    }
}

foreach ($deploy in $Deployment) {

    foreach ($target in $deploy.Targets) {
        Write-Verbose "Starting deployment '$($deploy.DeploymentName)' to Azure Automation account '$target' in '$ResourceGroupName' resource group."

        #region Import-AzAutomationDscConfiguration parameters
        $params = @{
            SourcePath            = $deploy.Source
            AutomationAccountName = $target
            ResourceGroupName     = $ResourceGroupName
            Verbose               = $VerbosePreference
        }

        if ($ConfigurationDescription) {
            $params['ConfigurationDescription'] = $ConfigurationDescription
        }

        if ($ConfigurationTags) {
            $params['ConfigurationTags'] = $ConfigurationTags
        }

        if ($ConfigurationTags) {
            $params['ConfigurationTags'] = $ConfigurationTags
        }

        if ($Published) {
            $params['Published'] = $Published
        }

        if ($LogProgress) {
            $params['LogProgress'] = $LogProgress
        }

        if ($Force) {
            $params['Force'] = $Force
        }
        #endregion

        $importedDscConfiguration = Import-AzAutomationDscConfiguration @params

        Write-Verbose "The configuration '$($importedDscConfiguration.Name)' has been imported to '$target' Azure Automation account."

        if ($Compile -and $importedDscConfiguration) {

            # New-DscCompiledConfiguration parameters
            $params = @{
                ConfigurationName     = $importedDscConfiguration.Name
                AutomationAccountName = $importedDscConfiguration.AutomationAccountName
                ResourceGroupName     = $importedDscConfiguration.ResourceGroupName
                Verbose               = $VerbosePreference
            }

            if ($CompilationParameters) {
                $params['CompilationParameters'] = $CompilationParameters
            }

            if ($ConfigurationData) {
                $params['ConfigurationData'] = $ConfigurationData
            }

            if ($IncrementNodeConfigurationBuild) {
                $params['IncrementNodeConfigurationBuild'] = $IncrementNodeConfigurationBuild
            }

            $compiledConfiguration = New-DscNodeConfiguration @params
        }

        if ($importedDscConfiguration) {
            # Return the imported configuration
            Write-Output $importedDscConfiguration
        }

        Write-Verbose "The deployment '$($deploy.DeploymentName)' completed."
    }
}