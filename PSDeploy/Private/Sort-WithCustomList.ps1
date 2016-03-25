# Thanks to https://gallery.technet.microsoft.com/scriptcenter/Sort-With-Custom-List-07b1d93a
Function Sort-ObjectWithCustomList {
    Param (
        [parameter(ValueFromPipeline=$true)]
        [PSObject]
        $InputObject,

        [parameter(Position=1)]
        [String]
        $Property,

        [parameter()]
        [Object[]]
        $CustomList
    )

    Begin
    {
        # convert customList (array) to hash
        $hash = @{}
        $rank = 0
        $customList | Select -Unique | ForEach-Object {
            $key = $_
            $hash.Add($key, $rank)
            $rank++
        }

        # create script block for sorting
        # items not in custom list will be last in sort order
        $sortOrder = {
            $key = if ($Property) { $_.$Property } else { $_ }
            $rank = $hash[$key]
            if ($rank -ne $null) {
                $rank
            } else {
                [System.Double]::PositiveInfinity
            }
        }

        # create a place to collect objects from pipeline
        # (I don't know how to match behavior of Sort's InputObject parameter)
        $objects = @()
    }
    Process
    {
        $objects += $InputObject
    }
    End
    {
        $objects | Sort-Object -Property $sortOrder
    }
}