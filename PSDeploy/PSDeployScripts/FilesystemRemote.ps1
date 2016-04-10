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
    'Get-Hash'
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
                    Write-Verbose "Invoking ROBOCOPY.exe $RemoteSource $Target $Arguments"
                    ROBOCOPY.exe $RemoteSource $Target @Arguments
                }       
                else
                {
                    $SourceHash = Get-Hash $RemoteSource
                    $TargetHash = Get-Hash $Target -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if($SourceHash -ne $TargetHash)
                    {
                        Write-Verbose "Deploying file '$RemoteSource' to '$Target'"
                        Copy-Item -Path $RemoteSource -Destination $Target -Force
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