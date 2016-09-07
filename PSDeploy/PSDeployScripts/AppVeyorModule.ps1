<#
    .SYNOPSIS
        Deploys a module as an AppVeyor artifact

    .DESCRIPTION
        Deploys a module as an AppVeyor artifact

        Deployment source should be either:
            The path to the module folder, or;
            The path to the module manifest

        End users can follow the DSC Resource Development Build instructions:
            https://github.com/PowerShell/DscResources#development-builds

    .NOTES
        Major thanks to Microsoft and the contributors behind this code
            https://raw.githubusercontent.com/PowerShell/DscResource.Tests/dev/TestHelper.psm1
            https://github.com/PowerShell/xCredSSP/blob/cafb56015cc5099278b9b86f85272ae665e94f77/appveyor.yml

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER PackageName
        NuGet Package Name.  Defaults to module name.

    .PARAMETER Version
        NuGet Version.  Defaults to APPVEYOR_BUILD_VERSION

    .PARAMETER Author
        NuGet Author.  Defaults to Unknown

    .PARAMETER Owners
        NuGet Owners.  Defaults to the Author

    .PARAMETER LicenseUrl
        NuGet LicenseUrl.  Defaults to github.com/account/repo/LICENSE

    .PARAMETER ProjectUrl
        NuGet ProjectUrl.  Optional

    .PARAMETER Description
        NuGet Description.  Defaults to the module name

    .PARAMETER Tags
        NuGet Tags.  Optional
#>
[cmdletbinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [string]
    $PackageName,

    [string]
    $Version,

    [string]
    $Author,

    [string]
    $Owners,

    [string]
    $LicenseUrl,

    [string]
    $ProjectUrl,

    [string]
    $Description,

    [string]
    $Tags
)

# From https://raw.githubusercontent.com/PowerShell/DscResource.Tests/dev/TestHelper.psm1
# License: https://github.com/PowerShell/DscResource.Tests/blob/dev/LICENSE
function New-Nuspec
{
    <#
        .SYNOPSIS Creates a new nuspec file for nuget package.
            Will create $packageName.nuspec in $destinationPath

        .EXAMPLE
            New-Nuspec -packageName "TestPackage" -version 1.0.1 -licenseUrl "http://license" -packageDescription "description of the package" -tags "tag1 tag2" -destinationPath C:\temp
    #>
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $packageName,
        [Parameter(Mandatory=$true)]
        [string] $version,
        [Parameter(Mandatory=$true)]
        [string] $author,
        [Parameter(Mandatory=$true)]
        [string] $owners,
        [string] $licenseUrl,
        [string] $projectUrl,
        [string] $iconUrl,
        [string] $Description,
        [string] $releaseNotes,
        [string] $tags,
        [Parameter(Mandatory=$true)]
        [string] $destinationPath
    )

    $year = (Get-Date).Year

    $content +=
"<?xml version=""1.0""?>
<package xmlns=""http://schemas.microsoft.com/packaging/2011/08/nuspec.xsd"">
  <metadata>
    <id>$packageName</id>
    <version>$version</version>
    <authors>$author</authors>
    <owners>$owners</owners>"

    if (-not [string]::IsNullOrEmpty($licenseUrl))
    {
        $content += "
    <licenseUrl>$licenseUrl</licenseUrl>"
    }

    if (-not [string]::IsNullOrEmpty($projectUrl))
    {
        $content += "
    <projectUrl>$projectUrl</projectUrl>"
    }

    if (-not [string]::IsNullOrEmpty($iconUrl))
    {
        $content += "
    <iconUrl>$iconUrl</iconUrl>"
    }

    $content +="
    <requireLicenseAcceptance>true</requireLicenseAcceptance>
    <description>$Description</description>
    <releaseNotes>$releaseNotes</releaseNotes>
    <copyright>Copyright $year</copyright>
    <tags>$tags</tags>
  </metadata>
</package>"

    if (-not (Test-Path -Path $destinationPath))
    {
        New-Item -Path $destinationPath -ItemType Directory > $null
    }

    $nuspecPath = Join-Path $destinationPath "$packageName.nuspec"
    New-Item -Path $nuspecPath -ItemType File -Force > $null
    Set-Content -Path $nuspecPath -Value $content
} # New-Nuspec

$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

foreach($Deploy in $Deployment) {

    #Validate expected deployment options
    $RequiredParams = echo Version
    If( -not (Validate-DeploymentParameters -Required $RequiredParams -Parameters $Deploy.DeploymentOptions.Keys))
    {
        Write-Error "Missing required DeploymentOption.  Required DeploymentOptions:`n$($RequiredParams)"
    }

    $Source = $Deploy.Source
    $Targets = $Deploy.Targets
    if($Targets.count -eq 0){$Targets = @('Bah')}

    foreach($Target in $deploy.Targets) {
        Write-Verbose -Message "Starting deployment [$($deploy.DeploymentName)] to AppVeyor"

        $ThisSource = Get-Item $Source

        if($ThisSource.PSIsContainer)
        {
            $StagingDirectory = $ThisSource.Parent.FullName
            $Manifest = "$( Join-Path $Source $ThisSource.Name ).psd1"
            $ModuleName = $ThisSource.BaseName
            $ModulePath = $Source
            If(-not (Test-Path $Manifest))
            {
                Write-Error "Could not find expected module manifest: $($Manifest)"
                continue
            }
        }
        elseif($ThisSource.Extension -eq '.psd1')
        {
            $Parent = Split-Path $Source -Parent
            $StagingDirectory = (Get-Item $Parent).Parent.FullName
            $Manifest = $target
            $ModuleName = $Parent.BaseName
            $ModulePath = $Parent
        }
        else
        {
            Write-Error "Source [$Source)] must be a container or psd1 file"
            continue
        }

        $ZipFilePath = Join-Path $StagingDirectory "$ModuleName.zip"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($ModulePath, $ZipFilePath)

        # Set some defaults for params if not provided
        if(-not $Deploy.DeploymentOptions.Description)
        {
            $Description = $ModuleName
        }
        else
        {
            $Description = $Deploy.DeploymentOptions.Description
        }

        if(-not $Deploy.DeploymentOptions.Author)
        {
            $Author = 'Unknown'
        }
        else
        {
            $Author = $Deploy.DeploymentOptions.Author
        }

        if(-not $Deploy.DeploymentOptions.Owners)
        {
            $Owners = $Author
        }
        else
        {
            $Owners = $Deploy.DeploymentOptions.Owners
        }

        if(-not $Deploy.DeploymentOptions.LicenseUrl)
        {
            $LicenseUrl = "https://www.github.com/$env:APPVEYOR_REPO_NAME/LICENSE"
        }
        else
        {
            $LicenseUrl = $Deploy.DeploymentOptions.LicenseUrl
        }

        if(-not $Deploy.DeploymentOptions.Version)
        {
            $Version = "env:APPVEYOR_REPO_NAME"
        }
        else
        {
            $Version = $Deploy.DeploymentOptions.Version
        }

        $NuSpecParams = @{
            PackageName = $ModuleName
            Version = $Version
            Author = $Author
            Description = $Description
            DestinationPath = $StagingDirectory
            Owners = $Owners
            LicenseUrl = $LicenseUrl
        }

        foreach($Key in $Deploy.DeploymentOptions.Keys)
        {
            # These seem optional
            if('projectUrl', 'tags' -contains $Key)
            {
                $NuSpecParams.Add($Key, $Deploy.DeploymentOptions.$Key)
            }
        }

        New-Nuspec @NuSpecParams

        $null = nuget pack "$StagingDirectory\$ModuleName.nuspec" -outputdirectory $StagingDirectory
        $NuGetPackagePath = "$StagingDirectory\$ModuleName.$Version.nupkg"

        $ZipFilePath,
        $nuGetPackagePath | % {
            Write-Verbose "Pushing package [$_] as Appveyor artifact"
            Push-AppveyorArtifact $_
        }
    }
}
