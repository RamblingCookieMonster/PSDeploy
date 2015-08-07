function Add-CastingFunctions($value) {
    if ($PSVersionTable.PSVersion -ge "3.0") { return $value }
    return Add-CastingFunctionsForPosh2($value)
}

function Add-CastingFunctionsForPosh2($value) {
    $parms = @{MemberType = 'ScriptMethod'; Passthru = $True; ErrorAction = 'SilentlyContinue'}
    
    Add-Member @parms -InputObject $value -Name ToInt -Value { [int] $this } |
        Add-Member @parms -Name ToLong -Value { [long] $this } |
        Add-Member @parms -Name ToDouble -Value { [double] $this } |
        Add-Member @parms -Name ToDecimal -Value { [decimal] $this } |
        Add-Member @parms -Name ToByte -Value { [byte] $this } |
        Add-Member @parms -Name ToBoolean -Value { [System.Boolean]::Parse($this) }
}

