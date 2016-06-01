<#
    .SYNOPSIS
        Deploys file(s) to an Artifactory endpoint.

    .DESCRIPTION
        Deploys files to an Artifactory endpoint and optionally extract the file contents in Artifactory
        if the source file is an archive (zip, tar, tar.gz, or tgz).

    .PARAMETER Deployment
        Deployment to run
        
    .PARAMETER Credential
        The credential with 'deploy' permissions in Artifactory
        
    .PARAMETER Repository
        Specified the artifact repository to deploy in to.
        
        Example: 'powershell-scripts'
    
     .PARAMETER Path
        Specifies the Path within artifactory to deploy to
        
        Example: 'Test/Scripts'
    
    .PARAMETER OrgPath
        Identifies the artifact's organization
    
        Example: 'server_group'
        
    .PARAMETER Module
        Identifies the artifact's module
        
        Example: 'my_module'
    
    .PARAMETER BaseRev
        Identifies the base revision part of the artifact version, excluding any integration information.
        
        Example: '1.5.10', or in case of an integration revision '1.2-SNAPSHOT' the base revision is '1.2'
    
    .PARAMETER FileItegRev
        Identifies the integration revision part in the artifact's file name, excluding the base revision.
        
        Example: In case of an integration revision '1.2-20110202.144533-'" the file integration revision is '20110202.144533-3'
        
    .PARAMETER Extension
        Specify an alternate file extension for the artifact
        
    .PARAMETER Checksum
        Allows to deploy with or without checksums (Default = $true)       
            
    .PARAMETER DeployArchive
        Extract archive file (zip, tar, tar.gz, or tgz) once deployed.
    
    .PARAMETER Properties
        Specifies additional key-value pairs to be associated with the artifact.
        
        Example: @{generatedOn='2016-04-01'; generatedBy='Joe User'} 

#>
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [pscredential]$Credential,

    [Parameter(Mandatory)]
    [string]$Repository,
    
    [string]$Path,

    [string]$OrgPath,

    [string]$Module,

    [string]$BaseRev,

    [string]$FileItegRev,

    [string]$Extension,
    
    [bool]$Checksum = $true,

    [bool]$DeployArchive = $false,

    [hashtable]$Properties
)

foreach($Deploy in $Deployment) {
    Write-Verbose -Message "Starting deployment [$($Deploy.DeploymentName)] to Artifactory"

    if (Test-Path -Path $Deploy.Source) {
        
        $src = Get-Item -Path $Deploy.Source
        
        if ($src.PSIsContainer) {
            throw 'The source is a directory. Please specify an individual file or multiple files to deploy.'
        }
        
        foreach($Target in $Deploy.Targets) {

            # Get the file extension of the source file if none is specified in the deployment
            if (!$PSBoundParameters.ContainsKey('Extension')) {
                $file = Get-Item -Path $Deploy.Source
                $Extension = $file.Extension.Substring(1)
            }
            
            if ($PSBoundParameters.ContainsKey('Path')) {
                # Build URL based on hard-coded path
                $url = "$Target/$Repository/$Path"
            } else {
                # Build URL to deploy to
                $url = "$Target/$Repository/$OrgPath/$Module/$module`-$BaseRev"
                if ($PSBoundParameters.ContainsKey('FileItegRev')) {
                    $url += "-$FileItegRev`.$Extension"
                } else {
                    $url += "`.$Extension"
                }    
            }
                       
            # If extra properties are specified, append them to the URL as query parameters
            # These will be presented as additional properties on the artifact in Artifactory
            if ($PSBoundParameters.ContainsKey('Properties')) {
                foreach ($prop in $Properties.GetEnumerator()) {
                    $url += ";$($prop.Name)=$($prop.Value)"
                }
            }

            if ($Checksum) {
                # Calculate hash of source file and set in headers
                Write-Verbose -Message "Calculating checksums"
                $md5 = (Get-FileHash -Path $Deploy.Source -Algorithm MD5).Hash.ToLower()
                $sha1 = (Get-FileHash -Path $Deploy.Source -Algorithm SHA1).Hash.ToLower()
                $sha256 = (Get-FileHash -Path $Deploy.Source -Algorithm SHA256).Hash.ToLower()
                Write-Verbose -Message "MD5: $md5"
                Write-Verbose -Message "SHA1: $sha1"
                Write-Verbose -Message "SHA256: $sha256"
                $headers = @{
                    "X-Checksum-Deploy" = $true
                    "X-Checksum-Md5" = $md5
                    "X-Checksum-Sha1" = $sha1
                    "X-Checksum-Sha256" = $sha256
                }
            }

            # If we are deploying an archive (zip, tar, tar.gz, or tgz) and want to extract the contents in Artifactory
            if ($DeployArchive) {
                Write-Verbose -Message 'Deploying artifacts from archive: true'
                $headers."X-Explode-Archive" = $true
            }
            
            Write-Verbose -Message "Deploying [$($Deploy.Source)] to [$url]"
            $params = @{
                Uri = $url
                Method = 'Put'
                Headers = $headers
                InFile = $Deploy.Source
                Verbose = $false
            }
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $params.Credential =  $Credential
            } else {
                $params.UseDefaultCredentials = $true
            }
            try {
                $result = Invoke-RestMethod @params
                Write-Verbose -Message 'Deploy successful'
            } catch {
                throw $_
            }
        }
    }
    else {
        throw "Unable to find [$(Deploy.Source)]"
    }
}
