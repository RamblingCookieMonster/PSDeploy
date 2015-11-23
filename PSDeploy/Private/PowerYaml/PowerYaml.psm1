Add-Type -Path $PSScriptRoot\YamlDotNet.dll

function Convert-YamlNode($node, $h) {
    
    if(!$h) {$h=[Ordered]@{}}

    foreach ($item in $node) {
        switch ($item) {

            {$_.Value -is [YamlDotNet.RepresentationModel.YamlScalarNode]} {
                $h.$($_.key.Value) = $_.Value.Value
            }

            {$_.Value -is [YamlDotNet.RepresentationModel.YamlSequenceNode]} {                
                foreach ($element in $_.Value) {                    
                    $h.$($_.key.value)+=@([PSCustomObject](Convert-YamlNode $element))
                }
            }

            {$_.Value -is [YamlDotNet.RepresentationModel.YamlMappingNode]} {
                $inner=[Ordered]@{}                
                foreach ($element in $_.Value) {
                    $inner+=Convert-YamlNode $element
                }
                $h.$($_.key.value)=[PSCustomObject]$inner
            }

            default {
                return $_.Value
            }
        }
    }

    $h
}

function ConvertFrom-Yaml {
    param(
        [Parameter(ValueFromPipeline)]
        [string]$yaml
    )

    Process {
        $reader     = New-Object System.IO.StringReader $yaml
        $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
        $yamlStream.Load($reader)
        $reader.Close()

        [PSCustomObject](Convert-YamlNode $yamlStream.Documents.Rootnode)
    }
}

function ConvertFrom-YamlUri {
    param($uri)

    Invoke-RestMethod $uri | ConvertFrom-Yaml
}

function Import-Yaml {
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $FullName
    )
 
    Process {   
        [System.IO.File]::ReadAllText($FullName) | ConvertFrom-Yaml        
    }
}