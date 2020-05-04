<#
    .SYNOPSIS
        Deploys a module to an Azure Automation account.

    .DESCRIPTION
        Deploys a PowerShell module to an Azure Automation account from a repository like the PowerShell Gallery.
        Supports credentials to access private repositories.
        Inspired by https://blog.tyang.org/2017/02/17/managing-azure-automation-module-assets-using-myget/

        Sample snippet for PSDeploy configuration:

        By AzureAutomationModule {
            FromSource "https://www.powershellgallery.com/api/v2"
            To "MyAutomationAccountName"
            WithOptions @{
                SourceIsAbsolute  = $true # Should be true if deploying from a gallery, and false if deploying from a local path
                ModuleName        = "PSDepend"
                ModuleVersion     = '0.3.0' # Optional. If not specified, the latest module version will be used.
                ResourceGroupName = "MyAutomationAccount_ResourceGroupName"
                Force             = $true # Optional. Use if you want to overwrite an already imported module with the same or lower module version.
        }
    }

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER ModuleName
        Module to deploy

    .PARAMETER ModuleVersion
        Specific module version to use for deployment

    .PARAMETER Credential
        Credential to use for accessing the PowerShell repository

    .PARAMETER Force
        Deploy the module even if the same module version is already imported into Azure Automation account

    .PARAMETER ResourceGroupName
        The resource group of target Azure Automation account

    .PARAMETER StorageAccountName
        The Storage account to use for module upload
#>

#Requires -modules Az.Automation
[CmdletBinding()]
param(
    [ValidateScript( { $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory = $true)]
    [string]$ModuleName,

    [Parameter(Mandatory = $false)]
    [string]$ModuleVersion,

    [Parameter(Mandatory = $false)]
    [pscredential]$Credential,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName
)

function Get-ModuleRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceLocation,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        [Parameter(Mandatory = $false)]
        [pscredential]$Credential
    )

    begin {
        Write-Verbose "Starting the configuration of target module repository to work with..."
    }

    process {
        Write-Verbose "Searching for a registered PowerShell repository with SourceLocation '$SourceLocation'..."

        $existingPSRepository = Get-PSRepository | Where-Object -Property SourceLocation -eq $SourceLocation

        if ($existingPSRepository) {
            Write-Verbose "An already registered repository '$($existingPSRepository.Name)' with the same SourceLocation has been found."

            # Setting target repository name
            $targetRepositoryName = $existingPSRepository.Name
        }
        else {
            Write-Verbose "No registered repository has been found. Registering a new PowerShell repository..."

            # Register-PSRepository parameters
            $params = @{
                Name           = $ModuleName + '-repository'
                SourceLocation = $SourceLocation
                Verbose        = $VerbosePreference
            }

            if ($Credential) {
                $params['Credential'] = $Credential
            }

            # Register a new repository
            Register-PSRepository @params

            # Setting target repository name
            $targetRepositoryName = $ModuleName + '-repository'
        }
    }

    end {
        Write-Verbose "The following PowerShell repository will be used as the target repository '$targetRepositoryName'."
        # Return the target repository
        Get-PSRepository -Name $targetRepositoryName | Write-Output
    }
}

function Get-PublicModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        [Parameter(Mandatory = $false)]
        [string]
        $RequiredVersion
    )

    begin {
        if ($ModuleVersion) {
            Write-Verbose "Searching for version '$RequiredVersion' of module '$ModuleName' in the repository '$Repository'..."
        }
        else {
            Write-Verbose "Searching for the latest version of module '$ModuleName' in the repository '$Repository'..."
        }
    }

    process {
        #region Get source module repository
        # Get-ModuleRepository parameters
        $params = @{
            ModuleName     = $ModuleName
            SourceLocation = $Repository
            Verbose        = $VerbosePreference
        }

        $sourceModuleRepository = Get-ModuleRepository @params
        #endregion

        if ($sourceModuleRepository) {
            # Find-Module parameters
            $params = @{
                Name       = $ModuleName
                Repository = $Repository
                Verbose    = $VerbosePreference
            }

            if ($ModuleVersion) {
                $params['RequiredVersion'] = $RequiredVersion
            }

            # Look for the module
            $sourceModule = Find-Module @params
        }
        else {
            throw "Cannot register source module repository."
        }
    }

    end {
        if ($sourceModule) {
            Write-Verbose "The version '$($sourceModule.Version)' of module '$($sourceModule.Name)' is found in the repository '$Repository'."

            # Create and return a source module object
            $result = [PSCustomObject]@{
                Name        = $sourceModule.Name
                Version     = $sourceModule.Version
                ContentLink = "$($sourceModule.RepositorySourceLocation)/package/$($sourceModule.Name)/$($sourceModule.Version)/"
            }

            Write-Output $result
        }
        else {
            Write-Verbose "No target version of module '$ModuleName' is found in the repository '$Repository'."
        }
    }
}

function Get-PrivateModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential,

        [Parameter(Mandatory = $false)]
        [string]
        $RequiredVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Azure.Commands.Management.Storage.Models.PSStorageAccount]
        $StorageAccount
    )

    begin {
        if ($ModuleVersion) {
            Write-Verbose "Searching for version '$RequiredVersion' of module '$ModuleName' in the repository '$Repository'..."
        }
        else {
            Write-Verbose "Searching for the latest version of module '$ModuleName' in the repository '$Repository'..."
        }
    }

    process {
        #region Get source module repository
        # Get-ModuleRepository parameters
        $params = @{
            ModuleName     = $ModuleName
            SourceLocation = $Repository
            Credential     = $Credential
            Verbose        = $VerbosePreference
        }

        $sourceModuleRepository = Get-ModuleRepository @params
        #endregion

        if ($sourceModuleRepository) {
            # Find-Module parameters
            $params = @{
                Name       = $ModuleName
                Repository = $Repository
                Credential = $Credential
                Verbose    = $VerbosePreference
            }

            if ($ModuleVersion) {
                $params['RequiredVersion'] = $RequiredVersion
            }

            # Look for the module
            $sourceModule = Find-Module @params

            if ($sourceModule) {
                Write-Verbose "The version '$($sourceModule.Version)' of module '$($sourceModule.Name)' is found in the repository '$Repository'."

                Write-Verbose "Saving the module locally..."
                $sourceModule | Save-Module -Path $env:TEMP -Credential $Credential

                Write-Verbose "Creating a module zip file..."
                $zippedModuleFile = New-ModuleZipFile -Path (Join-Path -Path $env:TEMP -ChildPath $sourceModule.Name)
                Write-Verbose "Module zip file: $zippedModuleFile"

                Write-Verbose "Uploading the module zip file to a storage account..."
                $contentLink = New-ContentLinkUri -FileInfo $zippedModuleFile -StorageAccount $StorageAccount

                # Create and return a source module object
                $result = [PSCustomObject]@{
                    Name        = $sourceModule.Name
                    Version     = $sourceModule.Version
                    ContentLink = $contentLink
                }

                Write-Output $result
            }
            else {
                Write-Verbose "No target version of module '$ModuleName' is found in the repository '$Repository'."
            }
        }
        else {
            throw "Cannot register source module repository."
        }
    }

    end {
    }
}

function Get-ModuleImportStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        $ModuleImportJob
    )

    begin {
        $importCompleted = $false
    }

    process {
        do {
            Write-Verbose 'Checking module import status...'
            $importedModule = Get-AzAutomationModule -Name $ModuleImportJob.Name -ResourceGroupName $ModuleImportJob.ResourceGroupName -AutomationAccountName $ModuleImportJob.AutomationAccountName
            if (($importedModule.ProvisioningState -eq 'Succeeded') -or ($importedModule.ProvisioningState -eq 'Failed')) {
                $importCompleted = $true
            }
            Start-Sleep -Seconds 5
        }
        until ($importCompleted -eq $true)
    }

    end {
        Write-Verbose "Module import status is: $($importedModule.ProvisioningState)"
        # Return the import job status
        # Write-Output $importedModule
    }
}

function Get-ImportedModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AutomationAccountName,

        [Parameter(Mandatory = $false)]
        [string]
        $ResourceGroupName
    )

    begin {
        Write-Verbose "Searching for an existing module '$ModuleName' in the Automation account '$AutomationAccountName'..."
    }

    process {
        # Get-AzAutomationModule parameters
        $params = @{
            Name                  = $ModuleName
            AutomationAccountName = $AutomationAccountName
            ResourceGroupName     = $ResourceGroupName
            Verbose               = $VerbosePreference
            ErrorAction           = 'SilentlyContinue'
        }

        $importedModule = Get-AzAutomationModule @params
    }

    end {
        if ($importedModule) {
            Write-Verbose "An existing module '$($importedModule.Name)' version '$($importedModule.Version)' was found in the Automation account '$($importedModule.AutomationAccountName)'."

            # Return the imported module
            Write-Output $importedModule
        }
        else {
            Write-Verbose "No existing module '$ModuleName' was found in the Automation account '$AutomationAccountName'."
        }
    }
}

function Import-SourceModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        $Module,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Azure.Commands.Automation.Model.AutomationAccount]
        $AutomationAccount
    )

    begin {

    }

    process {
        #region Searching for the source module in the Azure Automation account
        # Get-PublicModule parameters
        $params = @{
            ModuleName            = $Module.Name
            AutomationAccountName = $AutomationAccount.AutomationAccountName
            ResourceGroupName     = $AutomationAccount.ResourceGroupName
            Verbose               = $VerbosePreference
        }

        $targetModule = Get-ImportedModule @params
        #endregion

        #region Check the target Automation account for existing module and set import flag
        $startImport = $false

        if ($targetModule) {
            if ($Force) {
                Write-Warning "Forcing the target module import!"

                # Remove-AzAutomationModule parameters
                $removeParams = @{
                    Name                  = $targetModule.Name
                    AutomationAccountName = $target
                    ResourceGroupName     = $deploy.DeploymentOptions.ResourceGroupName
                    Force                 = $deploy.DeploymentOptions.Force
                    Verbose               = $VerbosePreference
                }

                Write-Warning "Removing the version '$($targetModule.Version)' of module '$($targetModule.Name)' from the the Automation Account '$target'..."
                Remove-AzAutomationModule @removeParams

                $startImport = $true
            }
            elseif ($Module.Version -gt ([version]::Parse($targetModule.Version))) {
                Write-Verbose "The source module version is '$($Module.Version)', which is greater than the existing version in the Automation Account. Updating now..."
                $startImport = $true
            }
            elseif ($Module.Version -eq ([version]::Parse($targetModule.Version))) {
                Write-Verbose "The source module version is '$($Module.Version)', which is the same as the existing version in the Automation Account. Update is not required."
            }
            else {
                Write-Verbose "The source module version is '$($Module.Version)', which is lower than the existing version '$($targetModule.Version)' in the Automation Account. Update is not required."
            }
        }
        else {
            $startImport = $true
        }
        #endregion

        #region Import the module
        if ($startImport) {
            Write-Verbose "Importing the version '$($Module.Version)' of module '$($Module.Name)' into the Automation Account '$target'..."

            # New-AzAutomationModule parameters
            $params = @{
                Name                  = $Module.Name
                AutomationAccountName = $AutomationAccount.AutomationAccountName
                ResourceGroupName     = $AutomationAccount.ResourceGroupName
                ContentLink           = $Module.ContentLink
                Verbose               = $VerbosePreference
            }

            $moduleImportJob = New-AzAutomationModule @params
        }
        #endregion
    }

    end {
        # Return module import job
        if ($moduleImportJob) {
            $moduleImportJob | Get-ModuleImportStatus
        }
    }
}

function New-ContentLinkUri {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $FileInfo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Azure.Commands.Management.Storage.Models.PSStorageAccount]
        $StorageAccount
    )

    begin {
    }

    process {
        $context = $StorageAccount.Context

        # Check if a container with the same name exist in the Storage account
        $existingContainer = Get-AzStorageContainer -Name $FileInfo.BaseName.ToLower().Replace('.', '-') -Context $context

        if ($existingContainer) {
            # Use the existing container
            $container = $existingContainer
        }
        else {
            # Create a new container
            $container = New-AzStorageContainer -Name $FileInfo.BaseName.ToLower().Replace('.', '-') -Context $context -Permission Container
        }


        # Set-AzStorageBlobContent parameters
        $params = @{
            Container = $container.Name
            File      = $FileInfo.FullName
            Blob      = $FileInfo.Name
            Force     = $true
            Context   = $context
            Verbose   = $VerbosePreference
        }

        # Upload the file
        $blob = Set-AzStorageBlobContent @params

        # Get secure context
        $key = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName).Value[0]
        $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $key

        # New-AzStorageBlobSASToken parameters
        $params = @{
            Context    = $context
            Container  = $container.Name
            Blob       = $blob.Name
            Permission = 'r'
            ExpiryTime = (Get-Date).AddHours(2.0)
            FullUri    = $true
            Verbose    = $VerbosePreference
        }

        # Generate a SAS token
        $contentLinkUri = New-AzStorageBlobSASToken @params
    }

    end {
        Write-Output $contentLinkUri
    }
}

function New-ModuleZipFile {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'PSRepository')]
        [ValidateNotNullOrEmpty()]
        [psobject]
        $Module,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSRepository')]
        [pscredential]$Credential,
        [Parameter(Mandatory = $true, ParameterSetName = 'Local source')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    begin {

    }

    process {
        # Creating a zip file from the module in the source repository
        if ($Module) {

            # Save-Module parameters
            $params = @{
                InputObject = $Module
                Path        = $PSScriptRoot
                Force       = $true
                Verbose     = $VerbosePreference
            }

            if ($Credential) {
                $params['Credential'] = $Credential
            }

            $sourceModulePath = Save-Module @params
        }
        # Creating a zip file from the local source path
        elseif ($Path) {
            $sourceModulePath = $Path
        }

        $moduleZipFilePath = "{0}.zip" -f (Get-Item -Path $sourceModulePath).FullName

        Compress-Archive -Path $sourceModulePath -DestinationPath $moduleZipFilePath -Force

        Get-Item -Path $moduleZipFilePath
    }

    end {
    }
}


foreach ($deploy in $Deployment) {

    foreach ($target in $deploy.Targets) {
        Write-Verbose "Starting deployment '$($deploy.DeploymentName)' to Azure Automation account '$target' in '$ResourceGroupName' resource group."

        #region Get the source module
        if ($deploy.DeploymentOptions.SourceIsAbsolute -and (-not $deploy.DeploymentOptions.Credential)) {
            Write-Verbose "Deploying from a public repository at '$($deploy.Source)'..."

            # Get-PublicModule parameters
            $params = @{
                ModuleName = $deploy.DeploymentOptions.ModuleName
                Repository = $deploy.Source
                Verbose    = $VerbosePreference
            }

            if ($ModuleVersion) {
                $params['RequiredVersion'] = $ModuleVersion
            }

            $sourceModule = Get-PublicModule @params
        }
        elseif ($deploy.DeploymentOptions.SourceIsAbsolute -and $deploy.DeploymentOptions.Credential) {
            Write-Verbose "Deploying from a private repository at '$($deploy.Source)'..."

            #region Get the Storage account for uploading the module
            # Get-PrivateModule parameters
            $params = @{
                Name              = $deploy.DeploymentOptions.StorageAccountName
                ResourceGroupName = $deploy.DeploymentOptions.ResourceGroupName
                Verbose           = $VerbosePreference
            }

            $storageAccount = Get-AzStorageAccount @params
            #endregion

            if ($storageAccount) {
                # Get-PrivateModule parameters
                $params = @{
                    ModuleName     = $deploy.DeploymentOptions.ModuleName
                    Repository     = $deploy.Source
                    Credential     = $deploy.DeploymentOptions.Credential
                    StorageAccount = $storageAccount
                    Verbose        = $VerbosePreference
                }

                if ($ModuleVersion) {
                    $params['RequiredVersion'] = $ModuleVersion
                }

                $sourceModule = Get-PrivateModule @params
            }
            else {
                throw "The '$($deploy.DeploymentOptions.StorageAccountName)' storage account  was not found in the '$($deploy.DeploymentOptions.ResourceGroupName)' resource group"
            }
        }
        elseif (-not $deploy.DeploymentOptions.SourceIsAbsolute) {
            Write-Verbose "Deploying from a local path '$($deploy.Source)'..."
        }
        #endregion

        #region Importing the target module into an Azure Automation account
        if ($sourceModule) {

            $targetAzureAutomationAccount = Get-AzAutomationAccount -Name $target -ResourceGroupName $deploy.DeploymentOptions.ResourceGroupName

            if ($targetAzureAutomationAccount) {
                # Import-SourceModule parameters
                $params = @{
                    Module            = $sourceModule
                    AutomationAccount = $targetAzureAutomationAccount
                    Verbose           = $VerbosePreference
                }

                Import-SourceModule @params
            }
            else {
                throw "The target Azure Automation account '$target' was not found in '$($deploy.DeploymentOptions.ResourceGroupName)' resource group."
            }
        }
        else {
            if ($ModuleVersion) {
                throw "The version '$ModuleVersion' of source module '$($deploy.DeploymentOptions.ModuleName)' was not found at the source location '$($deploy.Source)'."
            }
            else {
                throw "The source module '$($deploy.DeploymentOptions.ModuleName)' was not found at the source location '$($deploy.Source)'."
            }
        }
        #endregion
    }
}