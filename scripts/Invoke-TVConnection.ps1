#requires -Version 7.0
[CmdletBinding()]
param([string]$AdbPath, [string]$Serial)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Assert-NoTVWorkSession
$connection = Get-TVConnection -AdbPath $AdbPath -Serial $Serial
# Identifiers remain in memory; do not print an adb devices listing or the connection object.
Write-Output 'Authorized USB transport and Philips-compatible Android TV identity verified. Confirm this is your TV physically before the audit. No retail model is inferred.'
