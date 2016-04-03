<#
    .SYNOPSIS
        Uses Copy-VMfile cmdlet which ships with Hyper-V on Sever 2012 R2

    .DESCRIPTION
        Uses  Copy-VMfile cmdlet (introduced in Server 2012 R2 Hyper-V) to perform the deployment.
        The cmdlet has some issues while copying to C:\windows\System32 & 'C:\Program files' folder (issue with DSC resources), 
        We workaround that by copying to a temp location and then moving the files and folders.        

        Deployment Options:
            Exposed FileSource - this is equal to 'host' in the Server2012R2 Hyper-V (can change in future versions so exposed here).
            CreateFullPath - Set this to True/False if you want the destination path to be created.
    .PARAMETER Deployment
        Deployment to run

    .PARAMETER VMName
        VMname passed to Copy-VMfile for VM deployment

    .PARAMETER Deployment
        Deployment passed to Copy-VMfile for VM deployment

    .PARAMETER Authentication
        Authentication passed to Invoke-Command for remote deployment    

#>
[cmdletbinding(DefaultParameterSetName='LocalCopyVMFile')]
param (
    [string]$VMname,

    # Specify the Hyper-V host name where the VM resides. Default - Localhost.
    [Parameter()]
    [Alias("HyperVServerName")]
    [String]$ComputerName=$env:COMPUTERNAME,

    [pscredential]$Credential,

    [Parameter(ValueFromPipeLine=$True)]
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment
)

Write-Verbose "Starting CopyVM deployment on VMnamed $ComputerName with $($Deployment.count) sources"
[void]$PSBoundParameters.Remove('Deployment')

$LocalCopyVMFileHash = @{}
Try
{
    $SourceHyperVHost = [System.Net.Dns]::GetHostEntry([string]$computername).HostName
    $LocalCopyVMFileHash.Add('ComputerName',$SourceHyperVHost)
}
Catch
{
    Write-Warning -Message "Could not resolve the $ComputerName. Skipping it."
    #Throw "Could not determine Hyper-V host for $($Map.Source), skipping"
}
# Fail safe if the CreateFullPath is not specified in the  Options under YML file
if($Deployment.DeploymentOptions.CreateFullPath) {
    $LocalCopyVMFileHash.Add('CreateFullPath',[System.Management.Automation.SwitchParameter]::Present)
}

# Add the Deployment Options to the PSBound Parameters
$Deployment.DeploymentOptions |  Get-Member -MemberType NoteProperty | 
        Where -Property Name -ne 'CreateFullpath'  | select -ExpandProperty Name | 
        foreach {$null = $LocalCopyVMFileHash.add("$PSitem",$Deployment.DeploymentOptions.$PSitem)}

# Runs the local Copy-VMFile cmdlet (comes with Hyper-V module on Server 2012R2 + )
foreach($deploy in $Deployment)
    {
        if($deploy.SourceExists)
        {
            $Targets = $deploy.Targets
            foreach($Target in $Targets)
            {
                if($Deploy.SourceType -eq 'Directory')
                {
                    # logic to copy the folder into the VM using Copy-VMFile cmdlet.
                    # Credits to Ravi's tip -> http://www.powershellmagazine.com/2013/12/17/pstip-copying-folders-using-copy-vmfile-cmdlet-in-windows-server-2012-r2-hyper-v/
                    Get-Childitem -Path $($deploy.Source) -Recurse -File |
                        Foreach-Object -Process { 
                            $FileName = Split-Path -Path $PSitem.FullName -Leaf
                            $Target = $Target.trimend('\')
                            Write-Verbose "Invoking Copy-VMFile. Source -> $($PSitem.Fullname) Destination -> $("$Target\$Filename")"
                            Copy-VMFile @LocalCopyVMFileHash -SourcePath $PSitem.FullName -DestinationPath "$Target\$Filename"
                        }

                }
                elseif ($Deploy.SourceType -eq 'File')
                {
                    # logic to copy file into the VM using Copy-VMfile cmdlet.
                    $FileName = Split-Path -Path $Deploy.Source -Leaf
                    $Target = $Target.trimend('\')
                    Write-Verbose "Invoking Copy-VMFile. Source -> $($Deploy.Source) Destination -> $("$Target\$Filename")"
                    Copy-VMFile @LocalCopyVMFileHash -SourcePath $Deploy.Source -DestinationPath "$Target\$Filename"
                }
                else {
                    Write-Warning -Message 'Only recognized SourceType are File/Directory'
                }
            }
        }
        else {
            Write-Warning -Message "Source does not exist -> $($Deploy.Source)"
        }
    }
