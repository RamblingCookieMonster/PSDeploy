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

    .PARAMETER ComputerName
        Computername passed to Invoke-Command for remote deployment

    .PARAMETER Deployment
        Deployment passed to Invoke-Command for remote deployment

    .PARAMETER Deployment
        Deployment passed to Invoke-Command for remote deployment

    .PARAMETER Authentication
        Authentication passed to Invoke-Command for remote deployment

    .PARAMETER ConfigurationName
        ConfigurationName passed to Invoke-Command for remote deployment

#>
[cmdletbinding()]
param (
    [string]$ComputerName,
    
    [pscredential]$Credential,
    
    [System.Management.Automation.Runspaces.AuthenticationMechanism]$Authentication,
    
    [string]$ConfigurationName,

    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment
)

Write-Verbose "Starting remote deployment on $ComputerName with $($Deployment.count) sources"
$PSBoundParameters.Remove('Deployment')
                    
#Remote deployment
Invoke-Command @ICMParams -ScriptBlock {

    foreach($Map in $Using:Deployment)
    {
        if($Map.SourceExists)
        {
            Try
            {
                $RemoteSource = $null
                $RemoteSource = $Map.Source -replace '^(.):', "\\$([System.Net.Dns]::GetHostEntry([string]$env:computername).HostName)\`$1$"
            }
            Catch
            {
                Write-Error $_
                Write-Error "Could not determin remote source for $($Map.Source), skipping"
                continue
            }

            $Targets = $Map.Targets
            foreach($Target in $Targets)
            {
                if($Map.SourceType -eq 'Directory')
                {
                    [string[]]$Arguments = "/XO"
                    $Arguments += "/E"
                    if($Map.DeploymentOptions.mirror -eq 'True')
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