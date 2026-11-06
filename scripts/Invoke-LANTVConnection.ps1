#requires -Version 7.0
[CmdletBinding()]
param([string]$SessionFile = (Join-Path (Split-Path -Parent $PSScriptRoot) '.local/lan-session.json'),[string]$AdbPath)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Assert-NoTVWorkSession
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
$connection = $null
$adb = Resolve-Adb $AdbPath
try {
$connection = Get-LANTVConnection -SessionFile $SessionFile -AdbPath $adb -AuthorizationWaitSeconds 45
$privateRoot = Split-Path -Parent $SessionFile
$connection | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'lan-connection-private.json') -Encoding utf8
[pscustomobject]@{Result='Philips-compatible Android TV identity and secure ADB configuration confirmed';ReportedModel=$connection.Model;ReportedVendorModel=$connection.VendorModel;RetailModel='Not inferred; inspect exact reported value';Transport='Authorized LAN; legacy connection is not TLS'}
} finally {
    if ($connection) { $null = Invoke-AdbProcess $adb @('disconnect',$connection.Serial) }
    $null = Invoke-AdbProcess $adb @('kill-server')
}
