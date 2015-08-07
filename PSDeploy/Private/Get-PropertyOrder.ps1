#function to extract properties
Function Get-PropertyOrder {
    <#
    .SYNOPSIS
        Gets property order for specified object

    .DESCRIPTION
        Gets property order for specified object

    .PARAMETER InputObject
        A single object to convert to an array of property value pairs.

    .PARAMETER Membertype
        Membertypes to include

    .PARAMETER ExcludeProperty
        Specific properties to exclude

    .FUNCTIONALITY
        PowerShell Language
    #>
    [cmdletbinding()]
     param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromRemainingArguments=$false)]
            [PSObject]$InputObject,

        [validateset("AliasProperty", "CodeProperty", "Property", "NoteProperty", "ScriptProperty",
            "Properties", "PropertySet", "Method", "CodeMethod", "ScriptMethod", "Methods",
            "ParameterizedProperty", "MemberSet", "Event", "Dynamic", "All")]
        [string[]]$MemberType = @( "NoteProperty", "Property", "ScriptProperty" ),

        [string[]]$ExcludeProperty = $null
    )

    begin {

        if($PSBoundParameters.ContainsKey('inputObject')) {
            $firstObject = $InputObject[0]
        }
    }
    process{

        #we only care about one object...
        $firstObject = $InputObject
    }
    end{

        #Get properties that meet specified parameters
        $firstObject.psobject.properties |
            Where-Object { $memberType -contains $_.memberType } |
            Select -ExpandProperty Name |
            Where-Object{ -not $excludeProperty -or $excludeProperty -notcontains $_ }
    }
} #Get-PropertyOrder