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
        
#>
[cmdletbinding()]
# Invoke-PSDeploy fails if there is a parameter set here
param (
    
    [Parameter(ValueFromPipeLine=$True)]
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    # Specify the name of the VM, this is where the artifcats will be deployed
    [string]$name,

    # Specify the Hyper-V host name where the VM resides. Default - Localhost.
    [String]$ComputerName=$env:COMPUTERNAME,

    #Specify the FileSource, at present only possible value is 'Host'
    [String]$FileSource,

    # Create full path if required on the VM.
    [Switch]$createFullPath
)
BEGIN {
    Write-Verbose "Starting CopyVM deployment on VMnamed $VMName running on Host $ComputerName with $($Deployment.count) sources"
    [void]$PSBoundParameters.Remove('Deployment')
}
PROCESS {
   # Runs the local Copy-VMFile cmdlet (comes with Hyper-V module on Server 2012R2 + )
    foreach($deploy in $Deployment){
        $LocalCopyVMFileHash = @{}
        # add fail safe for FileSource & CreateFullPath
        if (-not $deploy.DeploymentOptions.FileSource) {
            # At the moment the cmdlet only supports specifying host as the file source.
            # This will add this if the deployment options does not have it mentioned
            $LocalCopyVMFileHash.Add('FileSource','Host')
        }
        else {
            $LocalCopyVMFileHash.Add('FileSource',$deploy.DeploymentOptions.FileSource)
        }

        
        if(-not $deploy.DeploymentOptions.CreateFullPath) {
            $LocalCopyVMFileHash.Add('CreateFullPath',$true)
        }
        else {
            $LocalCopyVMFileHash.Add('CreateFullPath',$deploy.DeploymentOptions.CreateFullPath)
        }

        if (-not $deploy.DeploymentOptions.Name) {
            Write-Warning -Message "No Name (VMName) specified for the deployment. Skipping the deployment $($Deploy | Out-String)."
            return
        }
        else {
            $LocalCopyVMFileHash.Add('Name',$($deploy.DeploymentOptions.Name)) 
        }

        if ($deploy.DeploymentOptions.ComputerName) {
            # if the ComputerName specified, do a name resolution.
            Try {
                $SourceHyperVHost = [System.Net.Dns]::GetHostEntry($deploy.DeploymentOptions.ComputerName).HostName
                $LocalCopyVMFileHash.Add('ComputerName',$SourceHyperVHost)
            }
            Catch
            {
                Write-Warning -Message "Could not resolve the $ComputerName. Skipping the Deployment $($Deploy | Out-String)."
                return # return the control back, we are skipping the computer
                #Throw "Could not determine Hyper-V host for $($Map.Source), skipping"
            }
        }
        else {
            # use the local machine name as the Hyper-V host where the VM is running
            $LocalCopyVMFileHash.Add('ComputerName',$env:COMPUTERNAME)
        }

        if ($deploy.SourceExists) {
            foreach($target in ($deploy.Targets)) {
                if($Deploy.SourceType -eq 'Directory') {
                    # logic to copy the folder into the VM using Copy-VMFile cmdlet.
                    # Credits to Ravi's tip -> http://www.powershellmagazine.com/2013/12/17/pstip-copying-folders-using-copy-vmfile-cmdlet-in-windows-server-2012-r2-hyper-v/
                    Get-Childitem -Path $($deploy.Source) -Recurse -File |
                        Foreach-Object -Process { 
                            $FileName = Split-Path -Path $PSitem.FullName -Leaf
                            $Target = $Target.trimend('\')
                            Write-Verbose "Invoking Copy-VMFile. Source -> $($PSitem.Fullname) Destination -> $("$Target\$Filename")"
                            #Write-Host "$($LocalCopyVMFileHash | out-String)"
                            Copy-VMFile @LocalCopyVMFileHash -SourcePath $PSitem.FullName -DestinationPath "$Target\$Filename"
                        }

                }
                elseif ($Deploy.SourceType -eq 'File')
                {
                    # logic to copy file into the VM using Copy-VMfile cmdlet.
                    $FileName = Split-Path -Path $Deploy.Source -Leaf
                    $Target = $Target.trimend('\')
                    Write-Verbose "Invoking Copy-VMFile. Source -> $($Deploy.Source) Destination -> $("$Target\$Filename")"
                    #Write-Host "$($LocalCopyVMFileHash | out-String)"
                    Copy-VMFile @LocalCopyVMFileHash -SourcePath $Deploy.Source -DestinationPath "$Target\$Filename"
                }
                else {
                    Write-Warning -Message 'Only recognized SourceType are File/Directory'
                }
            }
        }
        else {
            Write-Warning -Message "Source does not exist -> $($deploy.Source)"
        }
    }
}
END {

}


