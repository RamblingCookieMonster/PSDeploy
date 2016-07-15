<#
    .SYNOPSIS
        Deploys / Push to a Git repository.

    .DESCRIPTION
        Deploys / Push to a Git repository.

    .PARAMETER Deployment
        Deployment to run

    .PARAMETER CommitMessage
        Message added to each commit
#>
[cmdletbinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,

    [Parameter(Mandatory)]
    [string]$CommitMessage
)

foreach($deploy in $Deployment) {
    foreach($target in $deploy.Targets) {

        Write-Verbose -Message "Starting deployment [$($deploy.DeploymentName)] to branch [$Target]"

        # Store current path
        $CurrentPath = (Get-Item -Path ".\" -Verbose).FullName

        Write-Verbose "Invoking cd $($deploy.Source)"
        cd $deploy.Source

        # Get git status
        $status = git status

        # If git status doesn't throw an error, continue the deployment. 
        If ($lastExitCode -eq 0) {

            # Checkout to the branch specified in $target
            Write-Verbose "Invoking git checkout $target"
            git checkout $target

            # add all new / modified files to the git index
            Write-Verbose "Invoking git add *"
            git add *

            # Commit the git index with a message specified in the parameter CommitMessage
            Write-Verbose "Invoking git commit -m `"$($deploy.DeploymentOptions.CommitMessage)`""
            git commit -m "$($deploy.DeploymentOptions.CommitMessage)"

            # Push the modifications 
            Write-Verbose "Invoking git push origin $target"
            git push origin $target
        } Else {
            throw $status
        }

        #Go back to the current path
        cd $CurrentPath
    }
}
