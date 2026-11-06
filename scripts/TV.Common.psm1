#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot { Split-Path -Parent $PSScriptRoot }

function Assert-NoTVWorkSession {
    # Standalone workflows disconnect/stop ADB in finally. Do not let them
    # interrupt a bounded owner before its mandatory timeout restoration.
    $path=Join-Path (Get-ProjectRoot) '.local/work-session-status.json'
    if(Test-Path -LiteralPath $path){
        $status=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        if($status.Active -or ($status.PSObject.Properties.Name -contains 'RestoreRequired' -and $status.RestoreRequired)){
            throw 'Close or recover the bounded TV work session before running a standalone connection, audit or stop command.'
        }
    }
}

function Resolve-Adb {
    param([string]$AdbPath)
    $candidates = @()
    if ($AdbPath) { $candidates += $AdbPath }
    else {
        $candidates += Join-Path (Get-ProjectRoot) '.tools/platform-tools/adb.exe'
        if ($env:LOCALAPPDATA) { $candidates += Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe' }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    throw 'Verified Google ADB not found. Run Install-PlatformTools.ps1 after accepting the Google SDK license, or specify an official SDK AdbPath.'
}

function New-AdbStartInfo {
    param([Parameter(Mandatory)][string]$AdbPath, [Parameter(Mandatory)][string[]]$Arguments)
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $AdbPath
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    # Use our loopback server, never an inherited remote ADB server or all-interface listener.
    $info.Environment.Remove('ADB_SERVER_SOCKET') | Out-Null
    $info.Environment.Remove('ANDROID_ADB_SERVER_ADDRESS') | Out-Null
    $info.Environment.Remove('ANDROID_ADB_SERVER_PORT') | Out-Null
    # Disable automatic discovery connections to previously paired network devices.
    $info.Environment['ADB_MDNS_AUTO_CONNECT'] = '0'
    # adb treats explicit numeric -H addresses as remote for daemon startup.
    # The literal localhost socket permits local startup and binds only loopback.
    foreach ($arg in @('-L','tcp:localhost:5037') + $Arguments) { $info.ArgumentList.Add($arg) }
    return $info
}

function Invoke-AdbProcess {
    param([Parameter(Mandatory)][string]$AdbPath, [Parameter(Mandatory)][string[]]$Arguments, [int]$TimeoutSeconds = 25)
    $info = New-AdbStartInfo -AdbPath $AdbPath -Arguments $Arguments
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    try {
        $null = $process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill($true)
            $process.WaitForExit()
            return [pscustomobject]@{ ExitCode = -1; Output = ''; Error = 'Command timed out'; Available = $false }
        }
        $output = $stdout.GetAwaiter().GetResult().Trim()
        $errorText = $stderr.GetAwaiter().GetResult().Trim()
        $failedText = '(?im)permission denied|permission denial|unknown command|unknown option|not found|not supported|can.t find service|no service published|error:|exception|usage:'
        $available = $process.ExitCode -eq 0 -and (($output + "`n" + $errorText) -notmatch $failedText)
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $output; Error = $errorText; Available = $available }
    }
    finally { $process.Dispose() }
}

function ConvertFrom-AdbDevices {
    param([string]$Text)
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^([^\s]+)\s+(device|unauthorized|offline|recovery|sideload|bootloader)\b(.*)$') {
            [pscustomobject]@{ Serial = $Matches[1]; State = $Matches[2]; Detail = $Matches[3].Trim() }
        }
    }
}

function Assert-UsbTransport {
    param([string]$Serial, [string]$DevPath)
    if ($Serial -match '[:\s/\\]' -or $Serial -match '_adb-tls|\._tcp' -or $DevPath -notmatch '^usb:[^\s]+$') {
        throw 'USB transport could not be verified. Network debugging is not authorized.'
    }
}

function Get-TVConnection {
    param([string]$AdbPath, [string]$Serial)
    $adb = Resolve-Adb $AdbPath
    $version = Invoke-AdbProcess $adb @('version')
    if (-not $version.Available -or $version.Output -notmatch 'Android Debug Bridge version') { throw 'ADB version validation failed.' }
    $listing = Invoke-AdbProcess $adb @('devices','-l')
    if (-not $listing.Available) { throw 'ADB device enumeration failed; inspect the local connection.' }
    $devices = @(ConvertFrom-AdbDevices $listing.Output)
    if ($devices.Count -eq 0) { throw 'No ADB device detected. See docs/connection.md; no network fallback is permitted.' }
    if (-not $Serial -and $devices.Count -gt 1) { throw 'Multiple devices detected. Select the TV serial explicitly on your PC with -Serial; do not share the serial externally.' }
    if ($Serial) { $selected = @($devices | Where-Object Serial -CEQ $Serial) }
    else { $selected = @($devices[0]) }
    if ($selected.Count -ne 1) { throw 'The explicitly selected device was not found.' }
    $device = $selected[0]
    if ($device.State -eq 'unauthorized') { throw 'Accept the RSA debugging authorization on the TV for this trusted PC, then retry.' }
    if ($device.State -ne 'device') { throw 'The selected device is not ready. Resolve its offline/boot state before proceeding.' }
    $devPath = Invoke-AdbProcess $adb @('-s',$device.Serial,'get-devpath')
    if (-not $devPath.Available) { throw 'Cannot inspect transport; stop before audit.' }
    Assert-UsbTransport $device.Serial $devPath.Output
    $manufacturer = Invoke-AdbProcess $adb @('-s',$device.Serial,'shell','getprop','ro.product.manufacturer')
    $brand = Invoke-AdbProcess $adb @('-s',$device.Serial,'shell','getprop','ro.product.brand')
    $model = Invoke-AdbProcess $adb @('-s',$device.Serial,'shell','getprop','ro.product.model')
    $uiMode = Invoke-AdbProcess $adb @('-s',$device.Serial,'shell','pm','list','features')
    if (-not $manufacturer.Available -or -not $brand.Available -or -not $uiMode.Available) { throw 'Device identity queries unavailable; stop for manual identification.' }
    if (($manufacturer.Output + ' ' + $brand.Output) -notmatch '(?i)philips|phillips|tpv|funai') {
        throw 'Identity is not consistent with a Philips/TPV/Funai device. Stop and confirm locally; no device is assumed.'
    }
    if ($uiMode.Output -notmatch 'android\.software\.leanback|android\.hardware\.type\.television') { throw 'Android TV features not confirmed; stop for manual identification.' }
    [pscustomobject]@{ AdbPath = $adb; Serial = $device.Serial; Transport = 'USB'; Manufacturer = $manufacturer.Output; Brand = $brand.Output; Model = $model.Output; Version = $version.Output; DevPath = $devPath.Output }
}

function Get-AuditConfiguration {
    $config = Get-Content -LiteralPath (Join-Path (Get-ProjectRoot) 'config/audit-queries.json') -Raw | ConvertFrom-Json
    # Compare config to reviewed immutable commands. Editing JSON cannot add a device write.
    $allowed = @(
        'shell df -k /data', 'shell cat /proc/meminfo', 'shell cat /proc/uptime', 'shell uname -r',
        'shell pm list packages -i --user 0', 'shell pm list packages -3 --user 0',
        'shell pm list packages -s --user 0', 'shell pm list packages -d --user 0',
        'shell pm list features', 'shell ps -A -o PID,PPID,USER,NAME',
        'shell cmd package resolve-activity --brief --user 0 -a android.intent.action.MAIN -c android.intent.category.HOME',
        'shell cmd package query-activities --brief --user 0 -a android.intent.action.MAIN -c android.intent.category.HOME',
        'shell wm size', 'shell wm density', 'shell dumpsys display', 'shell dumpsys media.codec',
        'shell dumpsys thermalservice', 'shell ip -brief address', 'shell ss -lnt',
        'shell pm get-max-users', 'shell dumpsys device_policy',
        'shell settings get global upload_diag_enable', 'shell settings get global adb_enabled',
        'shell settings get global adb_wifi_enabled'
    )
    $allowedProperties = @('ro.product.manufacturer','ro.product.brand','ro.product.model','ro.product.device',
        'ro.build.version.release','ro.build.version.sdk','ro.build.version.security_patch','ro.build.display.id',
        'ro.build.fingerprint','ro.product.cpu.abilist','ro.boot.verifiedbootstate','ro.boot.flash.locked',
        'ro.build.type','ro.build.tags','service.adb.tcp.port','persist.adb.tcp.port','persist.sys.usb.config','sys.usb.config')
    $ids = @()
    foreach ($query in $config.queries) {
        if ($query.id -notmatch '^[a-z][a-z0-9-]+$' -or $query.id -in $ids) { throw 'Unsafe or duplicate audit query id.' }
        $ids += $query.id
        if (($query.args -join ' ') -cnotin $allowed) { throw 'Audit configuration contains a command outside the read-only allowlist.' }
        # Reject token splitting tricks as adb shell joins its arguments on the device.
        foreach ($token in $query.args) { if ($token -match '[\s;&|`$<>\r\n]') { throw 'Unsafe audit argument.' } }
    }
    foreach ($property in $config.properties) { if ($property -cnotin $allowedProperties) { throw 'Unreviewed device property in audit configuration.' } }
    return $config
}

function Get-PackageNames {
    param([string]$Text)
    @($Text -split '\r?\n' | ForEach-Object {
        if ($_ -match '^package:([A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z0-9_]+)+)(?:\s|$)') { $Matches[1] }
    } | Sort-Object -Unique)
}

function New-PrivateAuditDirectory {
    param([string]$OutputRoot)
    if (-not $OutputRoot) { $OutputRoot = Join-Path ([IO.Path]::GetTempPath()) 'Philips-TV-Cleanup' }
    $full = [IO.Path]::GetFullPath($OutputRoot)
    $repo = [IO.Path]::GetFullPath((Get-ProjectRoot)).TrimEnd('\','/')
    if ($full.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or $full -eq $repo -or $full -match '(?i)(^|[\\/])(OneDrive[^\\/]*|Dropbox|Google Drive)([\\/]|$)' -or $full.StartsWith('\\')) {
        throw 'Audit output must be outside the repository, network shares, and known cloud-sync paths.'
    }
    $name = 'audit-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8)
    $path = Join-Path $full $name
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

Export-ModuleMember -Function Get-ProjectRoot,Assert-NoTVWorkSession,Resolve-Adb,Invoke-AdbProcess,ConvertFrom-AdbDevices,Assert-UsbTransport,Get-TVConnection,Get-AuditConfiguration,Get-PackageNames,New-PrivateAuditDirectory
