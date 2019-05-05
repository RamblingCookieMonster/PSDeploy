function Load-YamlDotNetLibraries([string] $dllPath, $shadowPath = (Join-Path -Path (Get-TempPath) -ChildPath 'poweryaml\shadow')) {

    # Borrowed from powershell-yaml
    # See https://github.com/cloudbase/powershell-yaml/issues/47

    $yaml = [System.AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object {
        $_.Location -Match "YamlDotNet.dll"
    }

    if ($yaml) {
        # YamlDotNet already loaded.

        $requiredTypes = @('YamlStream')

        foreach ($i in $requiredTypes) {
            if ($i -notin $yaml.DefinedTypes.Name) {
                Throw "YamlDotNet is loaded but missing required type ($i). Older version installed on system or assembly version mismatch?"
            }
        }

        return
    }

    $assemblies = @{
        "core" = Join-Path $dllPath "netstandard1.3\YamlDotNet.dll";
        "net45" = Join-Path $dllPath "net45\YamlDotNet.dll";
        "net35" = Join-Path $dllPath "net35\YamlDotNet.dll";
    }

    if ($PSVersionTable.PSEdition -eq "Core") {
        $dllPath = $assemblies["core"]
    } elseif ($PSVersionTable.PSVersion.Major -ge 4) {
        $dllPath = $assemblies["net45"]
    } else {
        $dllPath = $assemblies["net35"]
    }

    Add-Type -Path (Shadow-Copy -File $dllPath -ShadowPath $shadowPath)
}

#Get-YamlStream returned a document. Not sure why. Swapping code directly into function
function Get-YamlDocumentFromFile([string] $file) {
    $streamReader = [System.IO.File]::OpenText($file)
    $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream

    $yamlStream.Load([System.IO.TextReader] $streamReader)
    $streamReader.Close()
    $document = $yamlStream.Documents[0]
    $document
}

function Get-YamlDocumentFromString([string] $yamlString) {
    $stringReader = new-object System.IO.StringReader($yamlString)
    $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
    $yamlStream.Load([System.IO.TextReader] $stringReader)

    $document = $yamlStream.Documents[0]
    $document
}

function Explode-Node {
    param($node, $As)
    switch ($node.GetType().Name)
    {
        "YamlScalarNode" { Convert-YamlScalarNodeToValue $node }
        "YamlMappingNode" { Convert-YamlMappingNodeToHash $node $As }
        "YamlSequenceNode" { Convert-YamlSequenceNodeToList $node $As }
    }
}

function Convert-YamlScalarNodeToValue {
    param($node)
    Add-CastingFunctions($node.Value)
}

function Convert-YamlMappingNodeToHash {
    param($node, $As)

    $hash = @{}

    if($ModernPS -and $As -eq 'Object')
    {
        $hash = [ordered]@{}
    }

    $yamlNodes = $node.Children

    foreach($key in $yamlNodes.Keys)
    {
        $hash[$key.Value] = Explode-Node $yamlNodes[$key]
    }

    if($As -eq 'Hash')
    {
        $hash
    }
    elseif($ModernPS)
    {
        [pscustomobject]$hash
    }
    else
    {
        New-Object -TypeName PSObject -Property $hash
    }
}

function Convert-YamlSequenceNodeToList($node, $As) {
    $list = @()
    $yamlNodes = $node.Children

    foreach($yamlNode in $yamlNodes) {
        $list += Explode-Node $yamlNode $As
    }

    return $list
}

