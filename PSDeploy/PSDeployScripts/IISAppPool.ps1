<#
    .SYNOPSIS
        Deploys an IIS AppPool using Powershell

    .DESCRIPTION
        Deploys an IIS AppPool using Powershell
    
        By IISAppPool MyAppPool {
            WithOptions @{
                name = "AppPoolName"
                StartMode = "AlwaysRunning"
                IdentityType = 2
            }
        }

    .PARAMETER Deployment
        Deployment to process

    .PARAMETER Name
        Name of the IIS AppPool

    .PARAMETER Enable32Bit
        Set this parameter to True if you want to run a 32Bit App on a 64Bit IIS        

    .PARAMETER StartMode
        AlwaysRunning or OnDemand, Default: OnDemand

        AlwaysRunning:  Specifies that the Windows Process Activation Service (WAS) will always start the application pool. 
                        This behavior allows an application to load the operating environment before any serving any HTTP requests, 
                        which reduces the start-up processing for initial HTTP requests for the application.

        OnDemand:   Specifies that the Windows Process Activation Service (WAS) will start the application pool when an HTTP request 
                    is made for an application that is hosted in the application pool. This behavior resembles the WAS behavior in 
                    previous versions of IIS.

    .PARAMETER ManagedRuntimeVersion
        v1.1, v2.0 or v4.0, Default: None

        Optional string attribute.
        Specifies the .NET Framework version to be used by the application pool.

    .PARAMETER IdleTimeout
        One way to conserve system resources is to configure idle time-out settings for the worker processes in an 
        application pool. When these settings are configured, a worker process will shut down after a specified period 
        of inactivity. The default value for idle time-out is 20 minutes.
        
    .PARAMETER PeriodicRestartTime
        The PeriodicRestartTime element contains configuration settings that allow you to control when an application pool is recycled.

    .PARAMETER IdentityType
        0 = LocalSystem, 1 = LocalService, 2 = NetworkService, 3 = SpecificUser, 4 = ApplicationPoolIdentity  

    .PARAMETER User
        User for the IdentityType SpecificUser

    .PARAMETER Password
        Password for the IdentityType SpecificUser
        
    .PARAMETER LoadUserProfile
        Defines if the AppPool should load the user Profile or not     
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$Name                  = $null,
        
    [bool]  $Enable32Bit           = $false,
        
    [string]$StartMode             = $null, 
    [string]$ManagedRuntimeVersion = $null,
    [string]$IdleTimeout           = $null,
    [string]$PeriodicRestartTime   = $null,

            $IdentityType          = $null,
    [string]$User                  = $null,
    [string]$Password              = $null,
    [bool]  $LoadUserProfile       = $true
)

<#
    Create an application pool an set the configuration.
#>
function Create-IISApplicationPool
{
    param(
        # Application Pool Settings
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name                  = $null,
        
        [bool]  $enable32Bit           = $false,
        
        [string]$startMode             = $null, # AlwaysRunning, 
        [string]$managedRuntimeVersion = $null,
        [string]$idleTimeout           = $null,
        [string]$periodicRestartTime   = $null,
        
                $identityType          = $null,
        [string]$user                  = $null,
        [string]$password              = $null,
        [bool]  $loadUserProfile       = $true
    )
    
    begin
    {
        # IIS Directory Settings
        [string]$iisPool = "IIS:\AppPools\$($name)\"
        
        # Sets the application pool settings for the given parameter
        function Set-AppPoolProperties([PSObject]$pool)
        {
            if(-not $pool) { throw "Empty application pool, Argument -Pool is missing" }
            
            Write-Verbose "Configuring ApplicationPool properties"
            
            if ($startMode            ) { $pool.startMode                      = $startMode             }
            if ($managedRuntimeVersion) { $pool.managedRuntimeVersion          = $managedRuntimeVersion }
            if ($idleTimeout          ) { $pool.processModel.idleTimeout       = $idleTimeout           }
            if ($periodicRestartTime  ) { $pool.recycling.periodicRestart.time = $periodicRestartTime   }
            
            if ($identityType -ne $null)
            { 
                $pool.processModel.identityType = $identityType
                
                if($identityType -eq 3) # 3 = SpecificUser
                {
                    if(-not $user    ) { throw "Empty user name, Argument -User is missing"  }
                    if(-not $password) { throw "Empty password, Argument -Password is missing" }
                    
                    Write-Verbose "Setting AppPool to run as $user"
                    
                    $pool.processmodel.username = $user
                    $pool.processmodel.password = $password
                }
            }
            
            $pool.processModel.loadUserProfile = $loadUserProfile
            
            $pool | Set-Item
            
            if($enable32Bit)
            {
                Set-ItemProperty $iisPool -Name enable32BitAppOnWin64 -Value "True"
            }
            else
            {
                Set-ItemProperty $iisPool -Name enable32BitAppOnWin64 -Value "False"
            }
        }
    }
    
    process
    {
        Write-Verbose "Creating IIS ApplicationPool: $name"
        
        $pool = New-WebAppPool $name 
        
        Set-AppPoolProperties $pool
    }
    
    End {}
}

<#
    Removes the IIS application pool for the given name.
#>
function Remove-IISApplicationPool
{
    param(        
        # Application Pool Settings
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name = $null
    )
    
    begin
    {
        # IIS Directory Settings
        [string]$iisPoolPath = "IIS:\AppPools\$($name)\"
    }
    
    process
    {
        if(Test-Path $iisPoolPath)
        {
            Write-Verbose "Removing Application Pool: $name"
            
            Stop-IISAppPool $name
            
            Remove-WebAppPool $name
        }
    }
    
    End {}
}

<#
    Stop the AppPool if it exists and is running, and throws no error if it doesn't.
#>
function Stop-IISAppPool
{
    param(
        # Application Pool Settings
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name  = $null,
        [bool]  $sleep = $false # seconds
    )
    
    begin
    {
        # IIS Directory Settings
        [string]$iisPoolPath = "IIS:\AppPools\$($name)\"
    }
    
    process
    {
        Write-Verbose "Trying to stop the AppPool: $name"
        
        if (Test-Path $iisPoolPath)
        {
            if ((Get-WebAppPoolState -Name $name).Value -ne "Stopped")
            {
                Stop-WebAppPool -Name $name
                
                if (-not [string]::IsNullOrWhiteSpace($sleep))
                {
                    Start-Sleep -s $sleep
                }
                
                Write-Verbose "Stopped AppPool: $name"
            }
            else 
            {
                Write-Verbose "WARNING: AppPool $name was already stopped. Have you already run this?"
            }
        }
        else
        {
            Write-Verbose "WARNING: Could not find an AppPool called: $name to stop. Assuming this is a new installation."
        }
    }
    
    End {}
}

foreach($site in $Deployment)
{
    if (!(Get-Module WebAdministration))
    {
        ## Load it nested, and we'll automatically remove it during clean up.
        Import-Module WebAdministration -ErrorAction Stop
        Sleep 2 #see http://stackoverflow.com/questions/14862854/powershell-command-get-childitem-iis-sites-causes-an-error
    }

    Remove-IISApplicationPool -name $Name
    Create-IISApplicationPool -name $Name `
                                -enable32Bit $Enable32Bit `
                                -startMode $StartMode `
                                -managedRuntimeVersion $ManagedRuntimeVersion `
                                -identityType $IdentityType `
                                -idleTimeout $IdleTimeout `
                                -periodicRestartTime $PeriodicRestartTime `
                                -user $User `
                                -password $Password `
                                -loadUserProfile $LoadUserProfile
}