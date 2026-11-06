#requires -Version 7.0
[CmdletBinding()]
param([string]$SessionFile=(Join-Path (Split-Path -Parent $PSScriptRoot) '.local/lan-session.json'))
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Assert-NoTVWorkSession
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
$adb=Resolve-Adb
$connection=$null
try {
    $connection=Get-LANTVConnection -SessionFile $SessionFile -AdbPath $adb -AuthorizationWaitSeconds 90
    $results=[ordered]@{}
    $queries=[ordered]@{
        Power=@('shell','dumpsys','power')
        Uptime=@('shell','cat','/proc/uptime')
        BootReason=@('shell','getprop','ro.boot.bootreason')
        SystemBootReason=@('shell','getprop','sys.boot.reason')
        FirmwareIncremental=@('shell','getprop','ro.build.version.incremental')
        HdmiControl=@('shell','settings','get','global','hdmi_control_enabled')
        HdmiAutoOff=@('shell','settings','get','global','hdmi_control_auto_device_off_enabled')
        HdmiAutoWake=@('shell','settings','get','global','hdmi_control_auto_wakeup_enabled')
        StayOn=@('shell','settings','get','global','stay_on_while_plugged_in')
        LowPower=@('shell','settings','get','global','low_power')
        TheaterMode=@('shell','settings','get','global','theater_mode_on')
        SleepTimeout=@('shell','settings','get','secure','sleep_timeout')
        ScreenOffTimeout=@('shell','settings','get','system','screen_off_timeout')
    }
    foreach ($name in $queries.Keys) {
        Assert-LANTVSession $connection
        $results[$name]=Invoke-AdbProcess $adb (@('-s',$connection.Serial)+$queries[$name])
    }
    $results | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path (Split-Path -Parent $SessionFile) 'power-inspection-private.json') -Encoding utf8
    $summary=[ordered]@{Snapshot='Current operating state, not a capture of the failed wake';SettingsChanged=$false;StandbyOrRebootTestPerformed=$false}
    foreach ($field in @('mWakefulness','mIsPowered','mLastWakeReason','mLastSleepReason','mLastGlobalWakeTime','mLastGlobalSleepTime')) {
        $value='Unavailable'
        if ($results.Power.Output -match ('(?m)^\s*'+$field+'=([A-Za-z0-9_]+)\s*$')) {$value=$Matches[1]}
        $summary[$field]=$value
    }
    foreach ($field in @('HdmiControl','HdmiAutoOff','HdmiAutoWake','StayOn','LowPower','TheaterMode','SleepTimeout','ScreenOffTimeout')) {
        $value=$results[$field].Output
        $summary[$field]=if ($results[$field].Available -and $value -match '^-?\d+$') {$value} else {'Unavailable'}
    }
    foreach ($field in @('BootReason','SystemBootReason')) {
        $reason=($results[$field].Output -split ',')[0]
        $summary[$field]=if ($results[$field].Available -and $reason -in @('cold','hard','reboot','shutdown','powerkey','kernel_panic','watchdog','brownout','unknown','wakeup','rtc')) {$reason} else {'Unavailable or unrecognized; retained locally'}
    }
    $summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path (Split-Path -Parent $SessionFile) 'power-summary-private.json') -Encoding utf8
    $summary | ConvertTo-Json -Depth 4
} finally {
    if ($connection) {$null=Invoke-AdbProcess $adb @('disconnect',$connection.Serial)}
    $null=Invoke-AdbProcess $adb @('kill-server')
}
