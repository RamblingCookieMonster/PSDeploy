# This example provdes a better experience when using -verbose if running interactively

# Static
$SubscriptionName = 'mySubscriptionName'
$ResourceGroupName = 'testrg1'
$ResourceGroupLocation = 'central us'

# Tasks to complete before deployment
$s = Get-AzureRMSubscription -SubscriptionName $SubscriptionName -ErrorAction SilentlyContinue
if (!$s) {Login-AzureRMAccount}

$rg = Get-AzureRmResourceGroup -name $ResourceGroupName -ErrorAction SilentlyContinue
if (!$rg) {$rg = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation}

# PSDeploy
Deploy TemplateExample {
    By ARM {
        FromSource 'ARM\Template1.json'
        To $rg.ResourceGroupName
        Tagged 'Azure'
        WithOptions @{
            # note that the ARM script is splatting options as they are passed, it is not a list that will be known ahead of time
            administratorLogin = 'tmpadmin'
            # this wouldtake a Build variable or it could retrieve information from a secure service
            administratorLoginPassword = Read-Host -AsSecureString -Prompt 'please type the name to use for the administrator password inside the VM'
        }
    }
    # Todo - Azure Stack tagged example
}