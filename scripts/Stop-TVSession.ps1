#requires -Version 7.0
[CmdletBinding()]
param([string]$AdbPath)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Assert-NoTVWorkSession
$adb = Resolve-Adb $AdbPath
$result = Invoke-AdbProcess $adb @('kill-server')
if (-not $result.Available) { throw 'Could not confirm the local ADB server stopped; inspect local processes.' }
Write-Output 'Local ADB server stopped. On the TV, disable USB debugging and revoke debugging authorizations. No network debugging was enabled by this toolkit.'
