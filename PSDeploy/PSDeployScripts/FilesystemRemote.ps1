<#
    .SYNOPSIS
        Uses PSRemoting and deploys with Robocopy or Copy-Item for folder and file deployments, respectively.
        
    .DESCRIPTION
        Uses PSRemoting and deploys with Robocopy or Copy-Item for folder and file deployments, respectively.

        Runs in the specified remoting endpoint. Keep in mind this uses kerberos by default.
        
        Some kerberos double hop workarounds:
            - Use a delegated endpoint
            - CredSSP authentication

        Deployment Options:
           If Mirror is 'True' and the source is a folder, we effectively call robocopy /MIR (Can remove folders/files...)

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER Mirror
        If specified and the source is a folder, we effectively call robocopy /MIR (Can remove folders/files...)

    .PARAMETER ComputerName
        Computername passed to Invoke-Command for remote deployment

    .PARAMETER Deployment
        Deployment passed to Invoke-Command for remote deployment

    .PARAMETER Authentication
        Authentication passed to Invoke-Command for remote deployment

    .PARAMETER ConfigurationName
        ConfigurationName passed to Invoke-Command for remote deployment

#>
[cmdletbinding()]
param (
    [switch]$Mirror,

    [string]$ComputerName,

    [pscredential]$Credential,

    [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,

    [string]$ConfigurationName,

    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment
)

Write-Verbose "Starting remote deployment on $ComputerName with $($Deployment.count) sources"
[void]$PSBoundParameters.Remove('Deployment')

Try
{
    $SourceComputer = [System.Net.Dns]::GetHostEntry([string]$env:computername).HostName
}
Catch
{
    Write-Error $_
    Throw "Could not determine remote source for $($Map.Source), skipping"
}

# Set up module functions that need to be injected into the remote session.
$FunctionsToInject = @(
    'Get-Hash',
    'Invoke-Robocopy',
    'Start-ConsoleProcess'
)
$InjectedFunctions = @()

foreach ($FunctionName in $FunctionsToInject) {
    $FunctionObject = Get-Command -Name $FunctionName -Module 'PSDeploy' -ErrorAction SilentlyContinue
    if ($FunctionObject) {
        $InjectedFunctions += "Function $FunctionName { $($FunctionObject.Definition) }"
    } else {
        Write-Warning -Message "Unable to prepare function $FunctionName for remote injection"
    }
}

#Remote deployment
Invoke-Command @PSBoundParameters -ScriptBlock {

    # Inject required functions from local variable
    foreach ($FunctionDefinition in $Using:InjectedFunctions) {
        Invoke-Expression -Command $FunctionDefinition
    }

    foreach($Map in $Using:Deployment)
    {
        if($Map.SourceExists)
        {
            $RemoteSource = $null
            $RemoteSource = $Map.Source -replace '^(.):', "\\$Using:SourceComputer\`$1$"

            $Targets = $Map.Targets
            foreach($Target in $Targets)
            {
                if($Map.SourceType -eq 'Directory')
                {
                    [string[]]$Arguments = "/XO"
                    $Arguments += "/E"
                    if($Map.DeploymentOptions.mirror -eq 'True' -or $Using:Mirror)
                    {
                        $Arguments += "/PURGE"
                    }

                    # Resolve PSDrives.
                    $Target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Target)

                    Write-Verbose "Invoking ROBOCOPY.exe $RemoteSource $Target $Arguments"
                    Invoke-Robocopy -Path $RemoteSource -Destination $Target -ArgumentList $Arguments
                }
                else
                {
                    $SourceHash = ( Get-Hash $RemoteSource ).SHA256
                    $TargetHash = ( Get-Hash $Target -ErrorAction SilentlyContinue -WarningAction SilentlyContinue ).SHA256
                    if($SourceHash -ne $TargetHash)
                    {
                        Write-Verbose "Deploying file '$RemoteSource' to '$Target'"
                        Try {
                            Copy-Item -Path $Map.Source -Destination $Target -Force
                        }
                        Catch [System.IO.IOException],[System.IO.DirectoryNotFoundException] {
                            $NewDir = $Target
                            if ($NewDir[-1] -ne '\')
                            {
                                $NewDir = Split-Path -Path $NewDir
                            }
                            $null = New-Item -ItemType Directory -Path $NewDir
                            Copy-Item -Path $Map.Source -Destination $Target -Force
                        }
                    }
                    else
                    {
                        Write-Verbose "Skipping deployment with matching hash: '$RemoteSource' = '$Target')"
                    }
                }
            }
        }
    }
}