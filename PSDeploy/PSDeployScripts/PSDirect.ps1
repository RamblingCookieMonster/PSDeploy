<#
    .SYNOPSIS
        Uses PowerShell direct (PSDirect) for deploying to a VM & Hyper-V host (running Windows Server 2016 & above)

    .DESCRIPTION
    Uses PowerShell direct introduced in Windows Server 2016. In order to run this deployment type, the PSDeploy deployment needs to
    be run on the Hyper-V host.
    Note the below OS & Configuration requirements for both Hyper-V host and VM.
    Operating system requirements:
        Host: Windows 10, Windows Server Technical Preview 2, or later running Hyper-V.
        Guest/Virtual Machine: Windows 10, Windows Server Technical Preview 2, or later.

    Configuration requirements:
        The virtual machine must be running locally on the host.
        The virtual machine must be turned on and running with at least one configured user profile.
        You must be logged into the host computer as a Hyper-V administrator.
        You must supply valid user credentials for the virtual machine.
    
        
    .PARAMETER Deployment
        Deployment to run
    
    .NOTES
    Read the MSDN link below to read more about PowerShell direct.
    https://msdn.microsoft.com/en-us/virtualization/hyperv_on_windows/user_guide/vmsession
        
#>
[CmdletBinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    # Name of the VM
    [string]$VMName,

    # credentials to connect to the VM using PSDirect
    [PSCredential]$Credential,

    # Filter for the Copy-Item cmdlet
    [String]$Filter,

    # Include for the Copy-Item cmdlet
    [String[]]$Include,

    # Exclude for the Copy-Item cmdlet
    [String[]]$Exclude,

    # Switch Container for the Copy-Item cmdlet,
    # Indicates that this cmdlet preserves container objects during the copy operation.
    [Switch]$Container,

    # Switch Recurse for the Copy-Item cmdlet
    [Switch]$Recurse,

    # Switch Force for the Copy-Item cmdlet
    [Switch]$Force
)
    [void]$PSBoundParameters.Remove('Deployment')
    TRY 
    {
        # check if the vmicvmsession (PS Direct) service is present & try to start it  on the Server 2016 HOST.
        # If the service does not exist then the Deployment type 'PSDirect' is not usable.
        # Note the below does not have any effect if the service is already started.
        Start-Service -Name vmicvmsession -ErrorAction Stop
        $service = Get-Service -Name vmicvmsession
        
        if ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::Running) 
        {
            Write-Verbose -Message 'Hyper-V PowerShell Direct service running. Continuing.'
        }
        else 
        {
            throw 'Hyper-V PowerShell Direct Service not running. Terminating.'
        }
    }
    CATCH 
    {
        if ($PSItem.Exception.Message -eq "Cannot find any service with service name 'vmicvmsession'") 
        {
            # throw customized error message
            throw 'Hyper-V PowerShell Direct Service not found. Terminating.'
        }
        else 
        {
            # Throw back the error to halt execution
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }
    
    foreach($Deploy in $Deployment)
    {
        # try to create a PSSession to the VM using the Credential supplied
        $Session = New-PSSession -VMName $VMName -Credential $Credential
        
        # Remove the above parameters from the PSBoundParameters
        [Void]$PSBoundParameters.Remove('Credential')
        [Void]$PSBoundParameters.Remove('VMName')

        foreach($Target in $Deploy.Targets)
        {
            Copy-Item -ToSession $Session -Path $Deploy.Source -Destination $Target @PSBoundParameters 
        }
    }
