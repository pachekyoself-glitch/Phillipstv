#requires -Version 7.0
[CmdletBinding()]
param([string]$AdbPath, [string]$Serial, [string]$OutputRoot, [string]$LanSessionFile)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Assert-NoTVWorkSession
$config = Get-AuditConfiguration
$connection = $null
$lanAdb = if ($LanSessionFile) { Resolve-Adb $AdbPath } else { $null }
try {
if ($LanSessionFile) {
    if ($Serial) { throw 'Do not combine a LAN session target with a separate Serial.' }
    Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
    $connection = Get-LANTVConnection -SessionFile $LanSessionFile -AdbPath $AdbPath -AuthorizationWaitSeconds 45
} else { $connection = Get-TVConnection -AdbPath $AdbPath -Serial $Serial }
$directory = New-PrivateAuditDirectory $OutputRoot
$connection | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $directory 'connection-private.json') -Encoding utf8
$results = [ordered]@{}
foreach ($property in $config.properties) {
    $result = Invoke-AdbProcess $connection.AdbPath @('-s',$connection.Serial,'shell','getprop',$property)
    if ([string]::IsNullOrWhiteSpace($result.Output) -or $result.Output -eq 'null') { $result.Available = $false }
    $results['property:' + $property] = $result
}
foreach ($query in $config.queries) {
    # A disconnect/transport change halts collection instead of silently selecting another device.
    if ($connection.Transport -ceq 'AuthorizedLAN') { Assert-LANTVSession $connection }
    else {
        $transport = Invoke-AdbProcess $connection.AdbPath @('-s',$connection.Serial,'get-devpath')
        if (-not $transport.Available) { throw 'ADB disconnected during audit; partial files remain local. Reconnect USB and rerun.' }
        Assert-UsbTransport $connection.Serial $transport.Output
    }
    $result = Invoke-AdbProcess $connection.AdbPath (@('-s',$connection.Serial) + @($query.args))
    if (($query.id -ne 'packages-disabled' -and [string]::IsNullOrWhiteSpace($result.Output)) -or $result.Output -eq 'null') { $result.Available = $false }
    $results[$query.id] = $result
    # Preserve partial results locally after every command; never stream raw output to external tools.
    $results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $directory 'technical-private.json') -Encoding utf8
}
$packages = @()
if ($results['packages-all'].Available) { $packages = @(Get-PackageNames $results['packages-all'].Output) }
$inventory = [Collections.Generic.List[object]]::new()
foreach ($package in $packages) {
    if ($connection.Transport -ceq 'AuthorizedLAN') { Assert-LANTVSession $connection }
    # The package name comes from a strict parser; no shell metacharacters reach adb shell.
    $detail = Invoke-AdbProcess $connection.AdbPath @('-s',$connection.Serial,'shell','dumpsys','package',$package)
    $detail | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $directory ($package + '.package-private.json')) -Encoding utf8
    $inventory.Add([pscustomobject]@{ Package = $package; Classification = 'REVIEW'; Evidence = 'Not yet assessed'; PermissionsAvailable = $detail.Available })
}
$inventory | ConvertTo-Json -Depth 5 -AsArray | Set-Content -LiteralPath (Join-Path $directory 'inventory-private.json') -Encoding utf8
$unavailable = @($results.Keys | Where-Object { -not $results[$_].Available })
$sanitized = [ordered]@{
    SchemaVersion = 1
    Transport = $connection.Transport + ' verified at collection'
    AuditType = 'Read-only; no application or settings changes'
    QueriesAttempted = $results.Count
    QueriesUnavailable = $unavailable
    PackagesListed = $packages.Count
    PackagesClassifiedReview = $packages.Count
    RetainedAppMappings = 'UNVERIFIED: confirm exact labels, publisher, and packages locally'
    Updates = 'UNAVAILABLE: inspect supported updater UI and exact retail model documentation; no update check triggered'
    Performance = 'Resource snapshot only; startup/navigation/playback benchmarks NOT MEASURED'
    ChildContainment = 'NOT TESTED; unsupervised use NOT APPROVED'
    SharePolicy = 'Manual review required before publication; this file remains local'
}
$sanitized | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $directory 'sanitized-review-required.json') -Encoding utf8
@"
# Local audit follow-up

Collected query results and package permission metadata. Missing or denied queries are unavailable, not inferred.
Every package initially remains REVIEW and unchanged. Inspect package detail files to identify the six retained apps and critical dependencies.
Firmware availability, ACR/advertising settings, and management/profile support require the model-specific supported UI review.
Display/codec dumps describe reported capabilities; they do not prove actual HDR rendering, licensed Widevine playback, hardware decode, or panel refresh performance.
Do not share this directory. No private app data or system partition backup was performed.
"@ | Set-Content -LiteralPath (Join-Path $directory 'FOLLOW-UP.md') -Encoding utf8
Write-Output ('Read-only audit saved locally: ' + $directory)
Write-Output ('Package count: ' + $packages.Count + '; unavailable queries: ' + $unavailable.Count + '. No changes approved or applied.')
} finally {
    if ($lanAdb) {
        if ($connection) { $null = Invoke-AdbProcess $lanAdb @('disconnect',$connection.Serial) }
        $null = Invoke-AdbProcess $lanAdb @('kill-server')
    }
}
