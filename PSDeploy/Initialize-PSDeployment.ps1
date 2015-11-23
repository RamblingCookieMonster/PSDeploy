 function Initialize-PSDeployment {
    <#
    .SYNOPSIS
        Creates a sample Deployment.yml file to be placed in Folder

    .DESCRIPTION
        Creates a sample Deployment.yml file. Use this Function to put a sample file in a Directory.
        One can then edit the yaml file as per the project needs.

    .PARAMETER Path
        Path to place deployment.yml sample file.

    .EXAMPLE
        Initialize-PSDeployment C:\Git\Module1\

        # Creates a sample deployment.yml file and puts it in the directory C:\Git\Module1

    .EXAMPLE
        Initialize-PSDeployment -Path C:\Git\Module1\, C:\Git\Module2\ 

        # Places sample deployment.yml file in the two directories

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
     [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium")]
     [OutputType([int])]
     Param
     (
         # Path where the sample deployment.yml file will be placed.
         [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
         [string[]]$Path,            

         # Specify Force if you want to overwrite the existing deployment.yml file.
         [Switch]$Force
     )
 
     Begin
     {
        $RejectAll = $false;
        $ConfirmAll = $false;
     }
     Process
     {
        
        foreach($dir in $Path) {
           $FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($dir)
           
           # create the sample YAML string, Formatting sucks by using Here-String inside Process block.
                    $YamlString = @"
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


           if($PSCmdlet.ShouldProcess( "Creating the sample deployment.yml file in the directory ",
                                       "Create the sample deployment.yml file in the directory '$($FilePath)'?",
                                       "Creating sample deployment.yml File" )) {
              if($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to create the sample deployment.yml in directory '$($FilePath)'?", 
                                                        "Creating sample Deployment.yml file in directory '$($FilePath)'", 
                                                        [ref]$ConfirmAll, [ref]$RejectAll)) {
                    

                 # Create the sample Deployment.yml file now
                 New-Item -Path $FilePath -Name deployment.yml -Value $YamlString 
              } # end if ($Force -Or $PSCmdlet.ShouldContinue
           } # end if $PSCmdlet.ShouldProcess
        } # end foreach
     } # end Process
     End
     {
     }
 }