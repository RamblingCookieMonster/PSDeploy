<#
    .SYNOPSIS
        Support deployments by handling simple tasks.

    .DESCRIPTION
        Support deployments by handling simple tasks.

        You can use a Task in two ways:

        As a scriptblock:

            By Task {
                "Run some deployment code in this scriptblock!"
            }

        As a script:

            By Task {
                FromSource "Path\To\SomeDeploymentScript.ps1"
            }

    .PARAMETER Deployment
        Deployment to process
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

    [Parameter(Mandatory=$true, Position=4)]
    [string]  $ServiceArgs     = $null,

    [Parameter(Mandatory=$true, Position=5)]
    [string]  $NSSMBinaryPath     = $null
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

foreach($site in $Deployment)
{
    Stop-NSSMService -ServiceName $ServiceName -NSSMBinaryPath $NSSMBinaryPath
    Remove-NSSMService -ServiceName $ServiceName -NSSMBinaryPath $NSSMBinaryPath
    Create-NSSMService -ServiceName $ServiceName -ServiceBinaryPath $ServiceBinaryPath -ServiceArgs $ServiceArgs -NSSMBinaryPath $NSSMBinaryPath
    if($AppDirectory) {
        Set-NSSM-AppDirectory -ServiceName $ServiceName -AppDirectory $AppDirectory -NSSMBinaryPath $NSSMBinaryPath    
    }    
    Start-NSSMService -ServiceName $ServiceName -NSSMBinaryPath $NSSMBinaryPath
}