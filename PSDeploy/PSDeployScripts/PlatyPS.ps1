<#
    .SYNOPSIS
        Deploys An External Help Xml file from PlatyPS markdown.

    .DESCRIPTION
        Deploys An External Help Xml file from PlatyPS markdown to specified help folder.         

    .PARAMETER Deployment
        Deployment to run
        
    .PARAMETER Encoding
        Character encoding for your external help file.

        It should be of the type [System.Text.Encoding]. You can control precise details
        (https://msdn.microsoft.com/en-us/library/ms404377.aspx)about your encoding. 

    .PARAMETER Force
        Override existing files.
#>
[cmdletbinding()]
param(
    [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'PSDeploy.Deployment' })]
    [psobject[]]$Deployment,
    
    [System.Text.Encoding]$Encoding,

    [switch]$Force

)

foreach ($Deploy in $Deployment) 
{
    Write-Verbose -Message "Starting deployment [$($deploy.DeploymentName)] to PlatyPS"
    
    if (Test-Path -Path $Deploy.Source) 
    {
        foreach ($target in $deploy.Targets) 
        {

            $Params = @{
                Path = $deploy.Source
                OutputPath = $target
                Verbose = $VerbosePreference
            }

            if ($PSBoundParameters.ContainsKey('Encoding')) 
            {
                $params.Encoding = $Encoding
            }

            if ($PSBoundParameters.ContainsKey('Force')) 
            {
                $params.Force = $true
            }        

            Try
            {
                Write-Verbose -Message "Creating New External Help in [$($target)]"
                New-ExternalHelp @params
            }
            catch
            {
                Throw
            }
        }        
    }
    else 
    {
        Throw "[$($Deploy.Source)] does not exist"    
    }
}