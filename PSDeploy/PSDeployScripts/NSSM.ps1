<#
    .SYNOPSIS
        Deploys a binary by using the Non-Sucking Service Manager to run the ninary as a service in Windows

    .DESCRIPTION
        Deploys a binary by using the Non-Sucking Service Manager to run the ninary as a service in Windows

        By NSSM Node {
            WithOptions @{
                ServiceName = "ServiceName"
                ServiceBinaryPath = ".\bin\runtime\node.exe"
                ServiceArgs = ".\wwwroot\dist\server.js"
                AppDirectory = ".\wwwroot"
                NSSMBinaryPath = ".\bin\runtime\nssm.exe"            
            }        
        }

        Deploying a service will always remove and install it again

    .PARAMETER Deployment
        Deployment to process

    .PARAMETER ServiceName
        The service name under which it will be installed

    .PARAMETER ServiceBinaryPath
        Path to the binary which should be started as a service

    .PARAMETER AppDirectory
        The applications directory which the service should use as working directory

    .PARAMETER ServiceArgs
        Arguments which should be passed to the binary when it is started

    .PARAMETER NSSMBinaryPath
        Path to the nssm.exe    

    .PARAMETER StartService
        Defines wether or not the service should be started after the deployment. 
        You might want to disable that as you need to copy files before you can start the service.
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory=$true, Position=1)]
    [string]  $ServiceName     = $null,

    [Parameter(Mandatory=$true, Position=2)]
    [string]  $ServiceBinaryPath     = $null,

    [Parameter(Mandatory=$false, Position=3)]
    [string]  $AppDirectory     = $null,

    [Parameter(Mandatory=$false, Position=4)]
    [string]  $ServiceArgs     = $null,

    [Parameter(Mandatory=$true, Position=5)]
    [string]  $NSSMBinaryPath     = $null

    [Parameter(Mandatory=$false, Position=6)]
    [bool]  $StartService     = $true
)

<#
    Creates an Non-Sucking Service Manager Service
#>
function Create-NSSMService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $ServiceBinaryPath     = $null,

        [Parameter(Mandatory=$true, Position=3)]
        [string]  $ServiceArgs     = $null,

        [Parameter(Mandatory=$true, Position=4)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    begin
    {
    }
    
    process
    {
        Write-Verbose "Creating Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "install $ServiceName $ServiceBinaryPath $ServiceArgs" -Verb runAs -Wait
        Write-Verbose "Service $ServiceName created"
    }
    
    End {}
}

<#
    Removes an Non-Sucking Service Manager Service
#>
function Remove-NSSMService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    begin
    {
    }
    
    process
    {
        Write-Verbose "Removing Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "remove $ServiceName confirm" -Verb runAs -Wait
        Write-Verbose "Service $ServiceName removed"
    }
    
    End {}
}

<#
    Set Non-Sucking Service Manager Parameter AppDirectory
#>
function Set-NSSM-AppDirectory
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $AppDirectory     = $null,

        [Parameter(Mandatory=$true, Position=3)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    begin
    {
    }
    
    process
    {
        Write-Verbose "Set NSSM-AppDirectory $AppDirectory on Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "set $ServiceName AppDirectory $AppDirectory" -Verb runAs -Wait        
    }
    
    End {}
}

<#
    Starts an Non-Sucking Service Manager Service
#>
function Start-NSSMService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    begin
    {
    }
    
    process
    {
        Write-Verbose "Starting Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "start $ServiceName" -Verb runAs -Wait
        Write-Verbose "Service $ServiceName started"
    }
    
    End {}
}

<#
    Stops an Non-Sucking Service Manager Service
#>
function Stop-NSSMService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    begin
    {
    }
    
    process
    {
        Write-Verbose "Stopping Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "stop $ServiceName" -Verb runAs -Wait
        Write-Verbose "Service $ServiceName stopped"
    }
    
    End {}
}

foreach($service in $Deployment)
{
    Stop-NSSMService -ServiceName $ServiceName -NSSMBinaryPath $NSSMBinaryPath
    Remove-NSSMService -ServiceName $ServiceName -NSSMBinaryPath $NSSMBinaryPath
    Create-NSSMService -ServiceName $ServiceName -ServiceBinaryPath $ServiceBinaryPath -ServiceArgs $ServiceArgs -NSSMBinaryPath $NSSMBinaryPath
    if($AppDirectory) {
        Set-NSSM-AppDirectory -ServiceName $ServiceName -AppDirectory $AppDirectory -NSSMBinaryPath $NSSMBinaryPath    
    }    
    if($StartService) {
        Start-NSSMService -ServiceName $ServiceName -NSSMBinaryPath $NSSMBinaryPath    
    }    
}