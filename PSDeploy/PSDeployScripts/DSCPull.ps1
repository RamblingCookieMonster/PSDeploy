<#
    .SYNOPSIS
        Deploy a DSC Resource module to a Pull server.

    .DESCRIPTION
        Deploy a DSC Resource module to a Pull server.

        Runs in the current session (i.e. as the current user)

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER Certificate
        If specified, use the certificate, friendly name provided, sign the module

	.EXAMPLE
		Deploy PullServerDeployment {

			By DSCPull {
				FromSource .\ModuleSource
				To "\\pull.domain.com\c$\Program Files\WindowsPowerShell"
				WithOptions @{
					CertificateFriendlyName = 'DSCSign'
				}
				Tagged PullServer
			}
		}
#>
[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [string]$CertificateFriendlyName
)

Write-Verbose "Starting Pull server deployment with $($Deployment.count) sources"

#DSC Pull Server Deployment
foreach($Map in $Deployment)
{
    if($Map.SourceExists)
    {
        $Targets = $Map.Targets
        foreach($Target in $Targets)
        {
            if($Map.SourceType -eq 'Directory')
            {
                Write-Verbose "DSCPull: Starting DSCPull script"
                $moduleName = Split-Path -Path $Map.Source -Leaf
                $version = (Test-ModuleManifest -Path "$($Map.Source)\$moduleName.psd1").Version
                if($CertificateFriendlyName){
                    Write-Verbose "DSCPull: Using certificate"
                    $certCode = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object{$_.FriendlyName -eq $CertificateFriendlyName}
                    Write-Verbose "`tFriendly Name: $($certCode.FriendlyName)"
                    Write-Verbose "`tThumbprint: $($certificate.Thumbprint) "
                }
                $tempFolder = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName()))
                Invoke-Robocopy -Path $Map.Source -Destination $tempFolder -ArgumentList '/E','/PURGE'
                $catFile = New-FileCatalog -Path $tempFolder -CatalogFilePath "$tempFolder\$moduleName.cat"
                if($certCode){
                    Set-AuthenticodeSignature -Certificate $certCode -FilePath $catFile.FullName > $null
                }
                $compressedModuleName = "$($moduleName)_$($version.Major).$($version.Minor).$($version.Build).$($version.Revision).zip"
                Compress-Archive -Path $tempFolder -DestinationPath "$tempFolder\$compressedModuleName" -Force
                New-DscChecksum -Path "$tempFolder\$compressedModuleName"
                Copy-item -Path "$tempFolder\$compressedModuleName*" -Destination "$Target\DscService\Modules"
                Write-Verbose "DSCPull: ZIP file $compressedModuleName"
                Write-Verbose "DSCPull: Checksum file $compressedModuleName.checksum"
                Remove-Item -Path $tempFolder -Recurse -Confirm:$false
            }
            else
            {
				Write-Verbose "Source should be a module directory"
            }
        }
    }
}
