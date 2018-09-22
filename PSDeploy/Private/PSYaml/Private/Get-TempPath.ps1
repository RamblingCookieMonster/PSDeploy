<#
    .SYNOPSIS
        Return the OS specific temp folder path.
#>
function Get-TempPath() {
    if($ENV:Temp) {
        # Windows Temp Folder Location
        return $ENV:Temp
    }
    elseif ($env:TMPDIR) {
        # macOS Temp Folder Location
        return $ENV:TMPDIR
    }
    else {
        # Linux Temp Folder Location
        return '/tmp'
    }
}
