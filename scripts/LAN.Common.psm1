#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1')

function Assert-PrivateTVAddress {
    param([string]$Address)
    $parsed = $null
    if ($Address -notmatch '^\d{1,3}(?:\.\d{1,3}){3}$' -or -not [Net.IPAddress]::TryParse($Address,[ref]$parsed) -or $parsed.ToString() -cne $Address) { throw 'Enter a canonical private IPv4 address for the TV only.' }
    $bytes = $parsed.GetAddressBytes()
    if (-not ($bytes[0] -eq 10 -or ($bytes[0] -eq 172 -and $bytes[1] -ge 16 -and $bytes[1] -le 31) -or ($bytes[0] -eq 192 -and $bytes[1] -eq 168))) { throw 'Only an owner-confirmed private LAN address is allowed.' }
}

function Get-LANTarget {
    param([Parameter(Mandatory)][string]$SessionFile)
    $session = Get-Content -LiteralPath $SessionFile -Raw | ConvertFrom-Json
    Assert-PrivateTVAddress $session.address
    if ($session.schemaVersion -ne 1 -or $session.port -ne 5555 -or $session.ownerConfirmedTV -isnot [bool] -or $session.ownerConfirmedTV -ne $true -or $session.readOnlyAudit -isnot [bool] -or $session.readOnlyAudit -ne $true) { throw 'Invalid or unconfirmed LAN audit session.' }
    $expires = [DateTimeOffset]::Parse($session.expiresUtc)
    $now = [DateTimeOffset]::UtcNow
    if ($expires -le $now -or $expires -gt $now.AddMinutes(30)) { throw 'LAN audit session expired or has an invalid lifetime. Confirm the target locally again.' }
    [pscustomobject]@{Endpoint=($session.address + ':5555');Expires=$expires}
}

function Get-LANTVConnection {
    param([Parameter(Mandatory)][string]$SessionFile,[string]$AdbPath,[ValidateRange(0,90)][int]$AuthorizationWaitSeconds = 0)
    $target = Get-LANTarget $SessionFile
    $adb = Resolve-Adb $AdbPath
    $version = Invoke-AdbProcess $adb @('version')
    if (-not $version.Available -or $version.Output -notmatch 'Android Debug Bridge version') { throw 'ADB version verification failed.' }
    # One explicitly confirmed endpoint; no subnet/port scan or listener enabling.
    $connect = Invoke-AdbProcess $adb @('connect',$target.Endpoint) -TimeoutSeconds 15
    $success = $false
    try {
        $listing = Invoke-AdbProcess $adb @('devices','-l')
        if (-not $listing.Available) { throw 'ADB device enumeration unavailable.' }
        $selected = @(ConvertFrom-AdbDevices $listing.Output | Where-Object Serial -CEQ $target.Endpoint)
        if ($selected.Count -ne 1) { throw 'No ADB device answered at the owner-confirmed TV endpoint. No TV service was enabled or changed.' }
        if ($selected[0].State -eq 'unauthorized' -and $AuthorizationWaitSeconds -gt 0) {
            Write-Information 'Waiting briefly for this PC''s RSA authorization on the TV. No shell query has run.' -InformationAction Continue
            $deadline = [DateTimeOffset]::UtcNow.AddSeconds($AuthorizationWaitSeconds)
            while ($selected.Count -eq 1 -and $selected[0].State -eq 'unauthorized' -and [DateTimeOffset]::UtcNow -lt $deadline) {
                Start-Sleep -Seconds 1
                $listing = Invoke-AdbProcess $adb @('devices','-l') -TimeoutSeconds 3
                if (-not $listing.Available) { throw 'ADB authorization-state query unavailable.' }
                $selected = @(ConvertFrom-AdbDevices $listing.Output | Where-Object Serial -CEQ $target.Endpoint)
            }
            if ($selected.Count -ne 1) { throw 'The confirmed TV endpoint disconnected while awaiting authorization.' }
        }
        if ($selected[0].State -eq 'unauthorized') { throw 'Accept this trusted PC''s RSA authorization on the TV, then retry within the local session lifetime.' }
        if ($selected[0].State -ne 'device') { throw 'The confirmed LAN endpoint is not ready for an audit.' }
        $values = @{}
        foreach ($property in @('ro.product.manufacturer','ro.product.brand','ro.product.model','ro.product.vendor.model','ro.adb.secure')) {
            $result = Invoke-AdbProcess $adb @('-s',$target.Endpoint,'shell','getprop',$property)
            if (-not $result.Available) { throw 'Read-only TV identity/authentication query failed.' }
            $values[$property] = $result.Output
        }
        if (($values['ro.product.manufacturer'] + ' ' + $values['ro.product.brand']) -notmatch '(?i)philips|phillips|tpv|funai') { throw 'Connected endpoint is not confirmed as a Philips-compatible TV. Disconnected.' }
        if ($values['ro.adb.secure'] -ne '1') { throw 'Secure ADB authentication configuration could not be confirmed. Stop before the audit; no unrestricted remote-management session is accepted.' }
        $features = Invoke-AdbProcess $adb @('-s',$target.Endpoint,'shell','pm','list','features')
        if (-not $features.Available -or $features.Output -notmatch 'android\.software\.leanback|android\.hardware\.type\.television') { throw 'Android TV identity was not confirmed.' }
        $success = $true
        [pscustomobject]@{AdbPath=$adb;Serial=$target.Endpoint;Transport='AuthorizedLAN';ExpiresUtc=$target.Expires.ToString('o');Manufacturer=$values['ro.product.manufacturer'];Brand=$values['ro.product.brand'];Model=$values['ro.product.model'];VendorModel=$values['ro.product.vendor.model'];Version=$version.Output;DevPath='Explicitly authorized LAN endpoint; legacy transport is not TLS'}
    }
    finally { if (-not $success) { $null = Invoke-AdbProcess $adb @('disconnect',$target.Endpoint) } }
}

function Assert-LANTVSession {
    param([Parameter(Mandatory)]$Connection)
    if ($Connection.Transport -cne 'AuthorizedLAN' -or [DateTimeOffset]::Parse($Connection.ExpiresUtc) -le [DateTimeOffset]::UtcNow) { throw 'LAN audit session expired or wrong transport.' }
    $state = Invoke-AdbProcess $Connection.AdbPath @('-s',$Connection.Serial,'get-state')
    if (-not $state.Available -or $state.Output -cne 'device') { throw 'The authorized TV disconnected; stop the audit.' }
}

Export-ModuleMember -Function Assert-PrivateTVAddress,Get-LANTarget,Get-LANTVConnection,Assert-LANTVSession
