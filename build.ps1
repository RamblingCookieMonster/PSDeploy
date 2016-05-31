# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Install-Module Psake, PSDeploy, Pester, BuildHelpers -force
Import-Module Psake, BuildHelpers

Set-BuildEnvironment

Invoke-psake .\psake.ps1