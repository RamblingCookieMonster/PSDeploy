<#
    .SYNOPSIS
        Deploys a runbook to an Azure Automation account.

    .DESCRIPTION
        Deploys a runbook from a local source file to an Azure Automation account.
        Supports the same deployment runbook types as Import-AzAutomationRunbook cmdlet
        (https://docs.microsoft.com/en-us/powershell/module/az.automation/import-azautomationrunbook).

    .EXAMPLE
        Sample snippet for 'MyRunbook01.ps1' configuration:

        By AzureAutomationRunbook {
            FromSource "C:\Source\MyRunbook01.ps1"
            To "MyAutomationAccountName"
            WithOptions @{
                RunbookName        = "MyRunbook01"
                RunbookDescription = "My Runbook version 01" # Optional
                RunbookTags        = @{key0="value0";key1="value1"} # Optional
                RunbookType        = "PowerShell" # Optional. If not specified, will try to import the source as a PowerShell runbook.
                Published          = $false # Optional
                LogProgress        = $false # Optional
                LogVerbose         = $false # Optional
                Force              = $false # Optional
                ResourceGroupName  = "MyAutomationAccount_ResourceGroupName"
            }
        }

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER RunbookName
        Runbook name to use

    .PARAMETER RunbookDescription
        Runbook description

    .PARAMETER RunbookTags
        Tags to assign to the imported runbook

    .PARAMETER RunbookType
        Azure Automation runbook type

    .PARAMETER Published
        Runbook should be published after import

    .PARAMETER LogProgress
        Runbook should log progress information

    .PARAMETER LogVerbose
        Runbook should log detailed information

    .PARAMETER Force
        Overwrite an existing runbook with the same name if there is any

    .PARAMETER ResourceGroupName
        The resource group of target Azure Automation account

    .OUTPUTS
        Microsoft.Azure.Commands.Automation.Model.Runbook
#>

#Requires -modules Az.Automation
[CmdletBinding()]
[OutputType([Microsoft.Azure.Commands.Automation.Model.Runbook])]
param(
    [ValidateScript( { $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RunbookName,

    [Parameter(Mandatory = $false)]
    [string]$RunbookDescription,

    [Parameter(Mandatory = $false)]
    [hashtable]$RunbookTags,

    [Parameter(Mandatory = $false)]
    [ValidateSet('PowerShell', 'GraphicalPowerShell', 'PowerShellWorkflow', 'GraphicalPowerShellWorkflow', 'Graph', 'Python2')]
    [string]$RunbookType = 'PowerShell',

    [Parameter(Mandatory = $false)]
    [switch]$Published,

    [Parameter(Mandatory = $false)]
    [switch]$LogProgress,

    [Parameter(Mandatory = $false)]
    [switch]$LogVerbose,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName
)

foreach ($deploy in $Deployment) {

    foreach ($target in $deploy.Targets) {
        Write-Verbose "Starting deployment '$($deploy.DeploymentName)' to Azure Automation account '$target' in '$ResourceGroupName' resource group."

        # Import-AzAutomationRunbook parameters
        $params = @{
            Path                  = $deploy.Source
            Name                  = $RunbookName
            Type                  = $RunbookType
            AutomationAccountName = $target
            ResourceGroupName     = $ResourceGroupName
            Verbose               = $VerbosePreference
        }

        if ($RunbookDescription) {
            $params['RunbookDescription'] = $RunbookDescription
        }

        if ($RunbookTags) {
            $params['RunbookTags'] = $RunbookTags
        }

        if ($Published) {
            $params['Published'] = $Published
        }

        if ($LogProgress) {
            $params['LogProgress'] = $LogProgress
        }

        if ($LogVerbose) {
            $params['LogVerbose'] = $LogVerbose
        }

        if ($Force) {
            $params['Force'] = $Force
        }

        Import-AzAutomationRunbook @params

        Write-Verbose "The deployment '$($deploy.DeploymentName)' completed."
    }
}