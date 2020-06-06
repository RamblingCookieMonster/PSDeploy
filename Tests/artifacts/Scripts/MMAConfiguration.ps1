Configuration MMAConfiguration {

    #Importing required DSC resources
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    #Getting the configuration parameters for deployment
    $logAnalyticsWorkplaceID = Get-AutomationVariable -Name "logAnalyticsWorkplaceID"
    $logAnalyticsWorkplaceKey = Get-AutomationVariable -Name "logAnalyticsWorkplaceKey"

    #Download location for Microsoft Monitoring Agent package
    $logAnalyticsAgentPackageLocalPath = "C:\Deploy\MMASetup-AMD64.exe"

    #Download location for Microsoft Dependency Agent package
    $dependencyAgentPackageLocalPath = "C:\Deploy\InstallDependencyAgent-Windows.exe"

    Node $AllNodes.NodeName {

        #region Microsoft Monitoring Agent

        #Download installation file for Microsoft Monitoring Agent
        xRemoteFile logAnalyticsAgentPackage {
            Uri             = "https://go.microsoft.com/fwlink/?LinkId=828603" # Permalink to the 64-bit version of the agent package
            DestinationPath = $logAnalyticsAgentPackageLocalPath
        }

        #Installing Microsoft Monitoring Agent on a host
        xPackage logAnalyticsAgent {
            Name      = "Microsoft Monitoring Agent"
            Ensure    = "Present"
            Path      = $logAnalyticsAgentPackageLocalPath
            Arguments = '/C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=' + $logAnalyticsWorkplaceID + ' OPINSIGHTS_WORKSPACE_KEY=' + $logAnalyticsWorkplaceKey + ' AcceptEndUserLicenseAgreement=1"'
            ProductId = "" # ProductId to the 64-bit version of the agent. The 64-bit version has different id.
            DependsOn = "[xRemoteFile]logAnalyticsAgentPackage"
        }

        #Verifying that the agent service is running
        xService logAnalyticsAgentService {
            Name      = "HealthService"
            Ensure    = "Present"
            State     = "Running"
            DependsOn = "[xPackage]logAnalyticsAgent"
        }

        #Logging the installation in the event log (Microsoft-Windows-Desired State Configuration/Analytic event log)
        Log logAnalyticsAgentInstalled {
            Message   = "Microsoft Monitoring Agent has been successfully installed."
            DependsOn = "[xService]logAnalyticsAgentService"
        }

        #endregion

        #region Microsoft Dependency agent

        #Download installation file for Microsoft Dependency agent
        xRemoteFile dependencyAgentPackage {
            Uri             = "https://aka.ms/dependencyagentwindows" # Permalink to the agent package
            DestinationPath = $dependencyAgentPackageLocalPath
        }

        #Installing Microsoft Dependency agent on a host
        xPackage dependencyAgent {
            Name                       = "Dependency Agent"
            Ensure                     = "Present"
            Path                       = $dependencyAgentPackageLocalPath
            Arguments                  = '/S'
            ProductId                  = ""
            InstalledCheckRegKey       = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\DependencyAgent"
            InstalledCheckRegValueName = "DisplayName"
            InstalledCheckRegValueData = "Dependency Agent"
            DependsOn                  = "[xRemoteFile]dependencyAgentPackage", "[xPackage]logAnalyticsAgent"
        }

        #Verifying that the agent service is running
        xService dependencyAgentService {
            Name      = "MicrosoftDependencyAgent"
            Ensure    = "Present"
            State     = "Running"
            DependsOn = "[xPackage]dependencyAgent"
        }

        #Logging the installation in the event log (Microsoft-Windows-Desired State Configuration/Analytic event log)
        Log DependencyAgentInstalled {
            Message   = "Dependency Agent has been successfully installed."
            DependsOn = "[xService]dependencyAgentService"
        }

        #endregion
    }
}