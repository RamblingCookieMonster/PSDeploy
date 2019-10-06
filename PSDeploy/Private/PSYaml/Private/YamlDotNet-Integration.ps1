function Load-YamlDotNetLibraries([string] $dllPath, $shadowPath = (Join-Path -Path (Get-TempPath) -ChildPath "poweryaml\shadow")) {

    if ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? Location -Match "YamlDotNet.dll") {
        # YamlDotNet is already loaded
        return
    }

    # Select appropriate assembly for the PowerShell edition/version
    $assemblies = @{
        "core" = Join-Path $dllPath "netstandard1.3";
        "net45" = Join-Path $dllPath "net45";
        "net35" = Join-Path $dllPath "net35";
    }

    $assemblyVersion = $(
        if ($PSVersionTable.PSEdition -eq "Core") {
            "core"
        } elseif ($PSVersionTable.PSVersion.Major -ge 4) {
            "net45"
        } else {
            "net35"
        }
    )

    Get-ChildItem $assemblies[$assemblyVersion] -Filter *.dll | ForEach-Object {
        $shadow = Shadow-Copy -File $_.FullName -ShadowPath (Join-Path $shadowPath $assemblyVersion)
        Add-Type -Path $Shadow
    } | Out-Null
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

    if($ModernPS -and $As -eq "Object")
    {
        $hash = [ordered]@{}
    }

    $yamlNodes = $node.Children

    foreach($key in $yamlNodes.Keys)
    {
        $hash[$key.Value] = Explode-Node $yamlNodes[$key]
    }

    if($As -eq "Hash")
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

