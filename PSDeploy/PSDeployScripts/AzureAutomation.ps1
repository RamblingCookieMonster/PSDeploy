<#
    .SYNOPSIS
        Deploy a Powershell Runbook to Azure Automation.
    .DESCRIPTION
        Deploy a Powershell Runbook to Azure Automation.
    .PARAMETER Deployment
        Deployment to run
    .PARAMETER ResourceGroupName
        Resource Group to deploy to
    .PARAMETER AutomationAccountName
        Automation Account to deploy to
    .PARAMETER AzureServicePrincipalCredential
        Credential of Azure Service Principal
        User is Application (client) ID
        Password is Secret string / Application Password
    .PARAMETER AzureTenantID
        Tenant ID of Service Principal
    .PARAMETER RunbookType
        Type of runbook being deployed, one of "PowerShell", "GraphicalPowerShell", "PowerShellWorkflow", "GraphicalPowerShellWorkflow", "Python2"
    .PARAMETER CreateRunbook
        If true, will create runbook if it doesn't already exist, otherwise runbook must already exist


#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory)][string]$ResourceGroupName,
    
    [Parameter(Mandatory)][string]$AutomationAccountName,

    [Parameter(Mandatory)][pscredential]$AzureServicePrincipalCredential,

    [Parameter(Mandatory)][string]$AzureTenantID,

    [Parameter(Mandatory)]
    [ValidateSet("PowerShell", "GraphicalPowerShell", "PowerShellWorkflow", "GraphicalPowerShellWorkflow", "Python2")]
    [string]$RunbookType,

    [bool]$CreateRunbook
)

try 
{
    Write-Verbose "Connecting to Azure"
    $null = Connect-AzAccount -Credential $AzureServicePrincipalCredential -ServicePrincipal -Tenant $AzureTenantID -ErrorAction Stop
}
catch
{
    throw "Unable to connect to Azure with credentials provided $_"
}
    foreach ($deploy in $Deployment)
    {
        If ($deploy.SourceExists)
        {
            if($Deploy.SourceType -eq 'File')
            {
                $rbname = (Split-Path $deploy.source -Leaf).split('.')[0]
                Write-Verbose "looking for runbook $rbname"
                $get = Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue -Name $rbname
                Write-Verbose "got $($get.count) runbooks"
                if ((-not $get) -and (-not $CreateRunbook))
                {
                    Write-Warning "Runbook $rbname does not exist, please create before deploying or specify CreateRunbook"
                }
                else
                {
                    try
                    {
                        Write-Verbose "Import-AzAutomationRunbook -Path $($deploy.source) -Type $RunbookType -Published -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force  -ErrorAction Stop"
                        $null = Import-AzAutomationRunbook -Path $deploy.source -Type $RunbookType -Published -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force -ErrorAction Stop
                    }
                    catch
                    {
                        Write-Warning "Unable to update Runbook $_"
                    }
                }
            }
            else
            {
                Write-Warning "This can ony be used to deploy individual scripts, not directories"
            }
        }
    }

    $null = Disconnect-AzAccount