# This example provdes a better experience when using -verbose if running interactively

# For a silent authentication to Azure, you will need to use a Service Principle.
# See the following article for details on configuring this option.
# http://go.microsoft.com/fwlink/?LinkID=623000&clcid=0x409

# If running interactively, this would be another option to authenticate
<#
$SubscriptionID = 'INSERT_GUID'
$ResourceGroupName = 'testrg1'
$ResourceGroupLocation = 'central us'
$s = Get-AzSubscription -SubscriptionID $SubscriptionID -ErrorAction SilentlyContinue
if (!$s) {Login-AzAccount}
#>

# Map variables from Build system (store encrypted).  This might not be required, depending on the build service, thought it is nice for keeping track of needed variables.
[string]$registrationKey = [string]$registrationKey
[string]$tenant = [string]$tenant
[string]$ID = [string]$ID
[string]$key = [string]$key
[string]$subscriptionId = [string]$subscriptionId
[string]$ResourceGroupName = [string]$ResourceGroupName
[string]$ResourceGroupLocation = [string]$ResourceGroupLocation
[string]$administratorLogin = [string]$administratorLogin
[string]$administratorLoginPassword = [string]$administratorLoginPassword

# SPN based authentication to Azure
$key = $key | ConvertTo-SecureString -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $ID, $key
Add-AzAccount -ServicePrincipal -Tenant $Tenant -Credential $Credential
Select-AzSubscription -SubscriptionId $SubscriptionID

# Convert string values from Build in to securestring values for Azure cmdlets
$registrationKey = $registrationKey | ConvertTo-SecureString -AsPlainText -Force
$administratorLoginPassword = $administratorLoginPassword | ConvertTo-SecureString -AsPlainText -Force

# Verify Resource Group
$rg = Get-AzResourceGroup -name $ResourceGroupName -ErrorAction SilentlyContinue
if (!$rg) {$rg = New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation}

# PSDeploy
Deploy TemplateExample {
    By ARM {
        FromSource 'ARM\Template1.json'
        To $rg.ResourceGroupName
        Tagged 'Azure'
        WithOptions @{
            # note that the ARM script is splatting options as they are passed, it is not a list that will be known ahead of time
            registrationKey = $registrationKey
            administratorLogin = $administratorLogin
            administratorLoginPassword = $administratorLoginPassword
        }
    }
    # Todo - Azure Stack tagged example
}