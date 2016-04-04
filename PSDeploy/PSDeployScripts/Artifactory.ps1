param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [pscredential]$Credential,

    [Parameter(Mandatory)]
    [string]$Repository,

    # simple-default repository layout
    [Parameter(Mandatory)]
    [string]$OrgPath,

    [Parameter(Mandatory)]
    [string]$Module,

    [Parameter(Mandatory)]
    [string]$BaseRev,

    [string]$FileItegRev,

    [string]$Extension,

    [bool]$DeployArchive = $false,

    [hashtable]$Properties
)

foreach($Deploy in $Deployment) {
    Write-Verbose -Message "Starting deployment [$($Deploy.DeploymentName)] to Artifactory"

    if (Test-Path -Path $Deploy.Source) {
        if ($Deploy.SourceType -eq 'Directory') {
            Write-Verbose 'Source is a directory!'
            throw 'This is not implemented yet!'
        } else {
            Write-Verbose 'Source is a file'
        }

        foreach($Target in $Deploy.Targets) {

            # Get the file extension of the source file if none is specified in the deployment
            if (!$PSBoundParameters.ContainsKey('Extension')) {
                $file = Get-Item -Path $Deploy.Source
                $Extension = $file.Extension.Substring(1)
            }

            # Build URL to deploy to
            $url = "$Target/$Repository/$Module/$module`-$BaseRev"
            if ($PSBoundParameters.ContainsKey('FileItegRev')) {
                $url += "-$FileItegRev`.$Extension"
            } else {
                $url += "`.$Extension"
            }
            
            # If extra properties are specified, append them to the URL
            if ($PSBoundParameters.ContainsKey('Properties')) {
                foreach ($prop in $Properties.GetEnumerator()) {
                    $url += "$($prop.Name)=$($prop.Value)"
                }
            }

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