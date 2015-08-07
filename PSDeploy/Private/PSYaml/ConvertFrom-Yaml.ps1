function ConvertFrom-Yaml
{
    <# 
     .SYNOPSIS
          Convert a yaml file or string into a PowerShell object

     .PARAMETER Path
        Path to a yaml document

     .PARAMETER Text
        Yaml string to be converted

    .EXAMPLE
        $Yaml = ConvertFrom-Yaml -path C:\GitHub\PSYaml\sample.yml
        $Yaml.Parent.Child

            a       b       c      
            -       -       -      
            a value b value c value

        # Convert yaml file to a PowerShell object
        # View the parent.child node

    #>
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter( Mandatory = $True,
                    ParameterSetName = 'Path')]
        [validatescript({Validate-YamlFile $_})]
        [string] $Path,

        [parameter( Mandatory = $True,
                    ParameterSetName = 'Text')]
        [string] $Text,

        [validateset('Object','Hash')]
        [string]$As = 'Hash'
    )

    Switch ($PSCmdlet.ParameterSetName )
    {
        'Text' { $yaml = Get-YamlDocumentFromString $Text }
        'Path' {
        
            Try
            {
                #Resolve relative paths... Thanks Oisin! http://stackoverflow.com/a/3040982/3067642
                $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            }
            Catch
            {
                Write-Error "Could not resolve path for '$Path': $_"
                continue
            }
        
            $yaml = Get-YamlDocumentFromFile -file $Path
        
        }
    }

    Explode-Node $yaml.RootNode -As $As
}