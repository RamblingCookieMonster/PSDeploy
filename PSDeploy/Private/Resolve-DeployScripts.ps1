# Borrowed from Pester and stripped down
# This might be overkill
function Resolve-DeployScripts
{
    param ([object[]] $Path, [bool]$Recurse = $True)

    $resolvedScriptInfo = @(
        foreach ($object in $Path)
        {
            $unresolvedPath = [string] $object

            if ($unresolvedPath -notmatch '[\*\?\[\]]' -and
                (Test-Path -LiteralPath $unresolvedPath -PathType Leaf) -and
                (Get-Item -LiteralPath $unresolvedPath) -is [System.IO.FileInfo])
            {
                $extension = [System.IO.Path]::GetExtension($unresolvedPath)
                if ($extension -ne '.ps1')
                {
                    Write-Error "Script path '$unresolvedPath' is not a ps1 file."
                }
                else
                {
                    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($unresolvedPath)
                }
            }
            else
            {
                $RecurseParam = @{Recurse = $False}
                if($Recurse)
                {
                    $RecurseParam.Recurse = $True
                }
                # World's longest pipeline?

                Resolve-Path -Path $unresolvedPath |
                    Where-Object { $_.Provider.Name -eq 'FileSystem' } |
                    Select-Object -ExpandProperty ProviderPath |
                    Get-ChildItem -Include *.PSDeploy.ps1 @RecurseParam |
                    Where-Object { -not $_.PSIsContainer } |
                    Select-Object -ExpandProperty FullName -Unique
            }
        }
    )

    $resolvedScriptInfo | Select -Unique
}