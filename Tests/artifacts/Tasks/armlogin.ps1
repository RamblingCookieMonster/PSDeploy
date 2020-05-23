# SPN based authentication to Azure
param(
    [string]$SubscriptionID,
    [string]$Tenant,
    [pscredential]$Credential
)
Write-Verbose "Logging in to tenant $Tenant"
Add-AzAccount -ServicePrincipal -Tenant $Tenant -Credential $Credential
Write-Verbose "Selecting scubscription $SubscriptionID"
Select-AzSubscription -SubscriptionId $SubscriptionID