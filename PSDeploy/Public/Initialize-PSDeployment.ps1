 function Initialize-PSDeployment {
    <#
    .SYNOPSIS
        Creates a sample deployment config file, yaml or *.psdeploy.ps1

    .DESCRIPTION
        Creates a sample deployment config file, yaml or *.psdeploy.ps1.
        Use this Function to put a sample file in a Directory.
        One can then edit the ps1 or yaml file as per the project needs.

    .PARAMETER Type
        Pick between  a ps1 (*.psdeploy.ps1) or a yaml deployment configuration

        Defaults to ps1, as yaml is deprecated

    .PARAMETER Path
        Path to place deployment.yml sample file.

    .EXAMPLE
        Initialize-PSDeployment C:\Git\Module1\

        # Creates a sample deployment.yml file and puts it in the directory C:\Git\Module1

    .EXAMPLE
        Initialize-PSDeployment -Type yml -Path C:\Git\Module1\, C:\Git\Module2\

        # Places sample deployment.yml file in the two directories

    .EXAMPLE
        Initialize-PSDeployment -Path C:\Git\Module1\

        # Places sample my.psdeploy.ps1 file in the C:\Git\Module1

    .LINK
        about_PSDeploy

    .LINK
        https://github.com/RamblingCookieMonster/PSDeploy

    .LINK
        Invoke-PSDeployment

    .LINK
        Get-PSDeploymentType

    .LINK
        Get-PSDeploymentScript

    #>
     [CmdletBinding()]
     [OutputType([int])]
     Param
     (
         # Path where the sample deployment.yml file will be placed.
         [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
         [string[]]$Path,

         # Specify Force if you want to overwrite the existing deployment.yml file.
         [Switch]$Force,

         [validateset('ps1','yml')]
         [string]$Type = 'ps1'
     )
     Process
     {
        foreach($dir in $path)
        {
            $FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($dir)
            if($Type -eq 'yml')
            {
                # create the sample YAML string, Formatting sucks by using Here-String inside Process block.
                $deployfile = 'deployment.yml'
                $deploystring = @"
$(Split-Path -Path $FilePath -Leaf):                  # Deployment name. This needs to be unique. Call it whatever you want.
  Author: '$($env:USERNAME)'                 # Author. Optional.
  Source:                          # One or more sources to deploy. Absolute, or relative to deployment.yml parent
    - 'Tasks\AD\Some-ADScript.ps1'
    - 'Tasks\AllOfThisDirectory'
  Destination:                     # One or more destinations to deploy the sources to
    - '\\contoso.org\share$\Tasks'
  DeploymentType: Filesystem       # Deployment type. See Get-PSDeploymentType
  Options:
    Mirror: True                   # If the source is a folder, triggers robocopy purge. Danger.
"@

            }
            elseif($Type -eq 'ps1')
            {
                $deployfile = 'my.psdeploy.ps1'
                $deploystring = @"
Deploy $(Split-Path -Path $FilePath -Leaf) {                        # Deployment name. This needs to be unique. Call it whatever you want
    By Filesystem {                              # Deployment type. See Get-PSDeploymentType
        FromSource 'Tasks\AD\Some-ADScript.ps1', # One or more sources to deploy. Absolute, or relative to deployment.yml parent
                   'Tasks\AllOfThisDirectory'
        To '\\contoso.org\share$\Tasks'          # One or more destinations to deploy the sources to
        Tagged Prod                              # One or more tags you can use to restrict deployments or queries
        WithOptions @{
            Mirror = `$True                         # If the source is a folder, triggers robocopy purge. Danger
        }
    }
}
"@
            }

            New-Item -Path $FilePath -Name $deployfile -Value $deploystring
        }
     } # end Process
 }