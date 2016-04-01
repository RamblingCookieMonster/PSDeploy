<#
    .SYNOPSIS
        Deploy a MkDocs Site to a filesystem Locationas a static site or JSON object, or deploy the static site to GitHub Pages.

    .DESCRIPTION
        Build and deploy documentation with MkDocs:
        
            * As a static site to a filesystem location
            * As a JSON representation of the site to a filesystem location
            * As a static site to your GitHub Pages

    .PARAMETER Deployment
        The deployment to run; this can specify all of the remaining options, or the options below can be added at runtime. This object will, at a minimum, include the source and destinations. Note that the "To" section of the deployment (if using *.PSDeploy.ps1) determines which of the three depoyment subtypes you are calling;
        
            * If the deployment specifies a target as a path on the file system, then "mkdocs build" will be called, deploying the static site to the specified path.
            * If the deployment specifies a target as a path on the file system starting with "json:" then "mkdocs json" will be called, deploying the JSON representation of the site to the specified path.
            * If the deployment has a target of "Github", "GitHubPages", or "Github-Pages", then "mkdocs gh-deploy" will be called, deploying the static site to the github repository that is the origin of the source folder.

    .PARAMETER Clean
        If specified, removes all old files from the destination before building.
        
    .PARAMETER ConfigurationFilePath
        Provide a specific MkDocs config; if not specified, builds from 'mkdocs.yml' in the source folder.
    
    .PARAMETER Strict
        If any errors or warnings are encountered on build, the deployment will stop and write the error.
    
    .PARAMETER Theme
        Specify a particular theme and overwrite the option selected in the configuration file.
        
    .PARAMETER Quiet
        Minimize the output from the MkDocs build and deployment process.
    
    .PARAMETER Message
        The commit message you want the push to GitHub Pages to write on deployment.
    
    .PARAMETER RemoteName
        The name of the remote repository to which you want to push the static files if the target is GitHub Pages.  For this to work, you must have added this remote to the source repository.
        
    .PARAMETER RemoteBranch
        The name of the remote branch to which you want to push the static files if the target is GitHub Pages. As with the RemoteName, this remote branch must be added to the source repository.
    
    .NOTES
        Runs in the current session (i.e. as the current user)
#>

[cmdletbinding()]
param (
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [switch]$Clean,

    [ValidateScript({Test-Path -Path $_.PSPath})]
    [string]$ConfigurationFilePath,

    [switch]$Strict,

    [string]$Theme,

    [switch]$Quiet,

    [string]$Message,

    [string]$RemoteName,

    [string]$RemoteBranch

)

Write-Verbose "Starting MkDocs Deployment with $($Deployment.count) sources"

foreach($Map in $Deployment)
{
    if($Map.SourceExists)
    {
        # MkDocs requires less hand holding if the current directory is the location of the mkdocs project.
        Push-Location -Path $Map.Source
        $Targets = $Map.Targets
        foreach($Target in $Targets)
        {
            # Some DeploymentOptions are only applicable to certain targets; this switch ensures erroneous
            # options aren't added and that the correct command is passed to MkDocs initially.
            Switch ($Target) {
                {$_ -in @("Github","GitHubPages","Github-Pages")} {
                    [string]$Arguments = "gh-deploy"
                    Try{
                        If($Map.DeploymentOptions["Message"] -ne $null){
                            $Arguments += " --message $($Map.DeploymentOptions["Message"])"
                        } ElseIf($Message){$Arguments += " --message `'$Message`'"}
                        If($Map.DeploymentOptions["RemoteBranch"] -ne $null){
                            $Arguments += " --remote-branch $($Map.DeploymentOptions["RemoteBranch"])"
                        } ElseIf($RemoteBranch){$Arguments += " --remote-branch `'$RemoteBranch`'"}
                        If($Map.DeploymentOptions["RemoteName"] -ne $null){
                            $Arguments += " --remote-name $($Map.DeploymentOptions["RemoteName"])"
                        } ElseIf($RemoteName){$Arguments += " --remote-name `'$RemoteName`'"}
                    } Catch {
                        If ($_.CategoryInfo -notmatch "InvalidOperation"){Write-Error $_}
                    } # These Try/Catch blocks ensure that no "indexing into null array" errors are received.
                      # Probably a better way to do this.
                }
                "^json:*" {
                    [string]$Arguments = "json"
                }
                default {
                    [string]$arguments = "build"
                    Try{
                        If($Map.DeploymentOptions["Theme"] -ne $null){
                            $Arguments += " --theme $($Map.DeploymentOptions["Theme"])"
                        } ElseIf($Theme){$Arguments += " --theme $Theme"}
                    } Catch {
                        If ($_.CategoryInfo -notmatch "InvalidOperation"){Write-Error $_}
                    }
                }
            }
            # The Site-Dir option *must* be passed to both the JSON and filesystem targets, but not GitHub Pages.
            If($Target -notin @("Github","GitHubPages","Github-Pages")){
                If($Map.DeploymentOptions["Strict"] -or $Strict.IsPresent){$Arguments += " --strict"}
                If($Target -notmatch "^json:") {$Arguments += " --site-dir $Target"}
                Else {$Arguments += " --site-dir $($Target.Substring(5))"}
            }
            Try{
                If($Map.DeploymentOptions["Clean"] -eq $true -or $Clean.IsPresent) { $Arguments += " --clean" }
                If($Map.DeploymentOptions["ConfigurationFilePath"] -ne $null){
                    If(Test-Path -Path $Map.DeploymentOptions["ConfigurationFilePath"]) {
                        $Arguments += " --config-file $($Map.DeploymentOptions["ConfigurationFilePath"])"
                    }
                } ElseIf($ConfigurationFilePath){$Arguments += " --config-file $ConfigurationFilePath"}
                
                If($Map.DeploymentOptions["Quiet"] -eq $true -or $Quiet.IsPresent){$Arguments += " --quiet"}
                ElseIf($VerbosePreference -eq "Continue"){$Arguments += " --verbose"}
            } Catch {
                If ($_.CategoryInfo -notmatch "InvalidOperation"){Write-Error $_}
            }
            Write-Verbose "Deploying MkDocs from $($Map.Source) to $Target"
            Start-Process mkdocs -ArgumentList "$Arguments" -Wait -NoNewWindow
        }
        Pop-Location # Return the prompt to the same state it started in.
    }
}
