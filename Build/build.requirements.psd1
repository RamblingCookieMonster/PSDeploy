@{
    # Some defaults for all dependencies
    PSDependOptions    = @{
        Target    = '$ENV:USERPROFILE\Documents\WindowsPowerShell\Modules'
        AddToPath = $True
        <# Parameters = @{
            Force = $True
        } #>
    }

    # Grab some modules without depending on PowerShellGet
    'psake'            = @{
        DependencyType = 'PSGalleryNuget'
        Force = $True
    }
    'PSDeploy'         = @{
        DependencyType = 'PSGalleryNuget'
        Force = $True
    }
    'BuildHelpers'     = @{
        DependencyType = 'PSGalleryNuget'
        Force = $True
    }
    'Pester'           = @{
        DependencyType = 'PSGalleryNuget'
        Version        = '3.4.6'
        Force = $True
    }
    # Module dependencies for Azure-related deployment types
    'Az.Automation'    = @{
        DependencyType = 'PSGalleryNuget'
        Force = $True
        DependsOn      = 'UninstallAzureRM'
    }
    'Az.Storage'       = @{
        DependencyType = 'PSGalleryNuget'
        Force = $True
        DependsOn      = 'UninstallAzureRM'
    }

    'UninstallAzureRm' = @{
        DependencyType = 'Command'
        Source         = '
        if (Get-Module -ListAvailable AzureRM*) {
            foreach ($module in (Get-Module -ListAvailable AzureRM*).Name |Get-Unique) {
                Uninstall-module $module
            }
        }
        '
    }
}