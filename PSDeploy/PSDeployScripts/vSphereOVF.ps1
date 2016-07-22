<#
    .SYNOPSIS
        Deploys a OVF/OVA to a VMWare vSphere Infrastructure.

    .DESCRIPTION
        Deploys a OVF/OVA to a VMWare vSphere Infrastructure.
        You have to be connected to a vCenter Server or an ESXi before deploying the OVF/OVA.

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER OvfConfiguration
        Specifies values for a set of user-configurable OVF properties.

    .PARAMETER Name
        Specifies the name of the virtual machine.
    
    .PARAMETER Datastore
        Specifies a datastore or a datastore cluster where you want to store the virtual machine.

    .PARAMETER DiskStorageFormat
        Specifies the storage format for the disks of the imported VMs. By default, the storage format is thick.
        When you set this parameter, you set the storage format for all virtual machine disks in the OVF package. 
        This parameter accepts Thin, Thick, and EagerZeroedThick values.

    .PARAMETER PowerOn
        Specifies if the VM is powered on after the deployment. By default, the VM is powered off.
#>

[cmdletbinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory=$false)]
    [System.Collections.Hashtable]$OvfConfiguration,

    [Parameter(Mandatory)]
    [string]$Name, 

    [Parameter(Mandatory=$false)]
    [string]$Datastore, 

    [Parameter(Mandatory=$false)]
    [string]$DiskStorageFormat,

    [Parameter(Mandatory=$false)]
    [bool]$PowerOn = $false
)

foreach($deploy in $Deployment) {
    foreach($target in $deploy.Targets) {

        Write-Verbose -Message "Starting deployment [$($deploy.DeploymentName)] to [$Target]"

        # Get informations about the target
    
        $VMHost = Get-VMHost -Name $Target

        If ($VMHost) {
            # If not specified in the parameters, load OVF/OVA configuration into a variable
            if ($PSBoundParameters.ContainsKey('OvfConfiguration')) {
                $OvfConfiguration = $deploy.DeploymentOptions.OvfConfiguration
            } else {
                $OvfConfiguration = Get-OvfConfiguration $deploy.Source
            }

            # If not specified in the parameters, select one datastore
            if (-not $PSBoundParameters.ContainsKey('Datastore')) {
                $Datastore = $VMHost | Get-datastore | Sort FreeSpaceGB -Descending | Select -first 1
            }

            Write-Verbose "[$($deploy.DeploymentOptions.Name)] will be deployed on datastore [$Datastore]"

            # If not specified in the parameters, set the disk format to 'thick'
            if (-not $PSBoundParameters.ContainsKey('DiskStorageFormat')) {
                $DiskStorageFormat = 'thick'
            } else {
                $DiskStorageFormat = $deploy.DeploymentOptions.DiskStorageFormat
            }

            Write-Verbose "[$($deploy.DeploymentOptions.Name)] disk format will be [$DiskStorageFormat]"
            
            # Deploy the OVF/OVA with the config parameters
            Write-Verbose "Deploying VM [$($deploy.DeploymentOptions.Name)]"
            $VM = Import-VApp -Source $deploy.Source -OvfConfiguration $OvfConfiguration -Name $deploy.DeploymentOptions.Name -VMHost $VMHost -Datastore $Datastore -DiskStorageFormat $DiskStorageFormat

            If ($deploy.DeploymentOptions.PowerOn) {
                Write-Verbose "Powering on VM [$($VM.Name)]"
                Start-VM -VM $VM
            }
        } else {
            Write-Verbose "VMHost [$Target] Not found"
        }
    }
}
