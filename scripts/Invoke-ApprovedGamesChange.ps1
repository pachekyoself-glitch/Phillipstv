#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ApprovalFile)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TV.ChangeGate.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TV.WorkSession.psm1') -Force
$privateRoot=Join-Path (Split-Path -Parent $PSScriptRoot) '.local'
$connection=Get-ActiveTVWorkConnection -MinimumSeconds 300
$approval=Get-Content -LiteralPath $ApprovalFile -Raw | ConvertFrom-Json
$plan=Get-ApprovedGamesChange $approval $connection.Serial
$adb=$connection.AdbPath
$required=@('com.netflix.ninja','com.google.android.youtube.tv','com.plexapp.android','com.disney.disneyplus','com.crunchyroll.crunchyroid','com.android.vending','com.google.android.gms')
function Read-Route([string]$Package){
    foreach($category in @('android.intent.category.LEANBACK_LAUNCHER','android.intent.category.LAUNCHER')){
        $result=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','cmd','package','resolve-activity','--brief','--user','0','-a','android.intent.action.MAIN','-c',$category,'-p',$Package)
        $routes=@($result.Output -split '\r?\n' | Where-Object {$_ -cmatch '^[A-Za-z][A-Za-z0-9_.]+/[A-Za-z0-9_.$]+$'})
        if($result.Available -and $routes.Count -eq 1 -and $routes[0].StartsWith($Package+'/',[StringComparison]::Ordinal)){return $routes[0]}
    }
    throw 'A retained-app launch route is unavailable; stop before further changes.'
}
$installed=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','pm','list','packages','--user','0')
$names=@(Get-PackageNames $installed.Output)
if(-not $installed.Available -or @($required | Where-Object {$_ -cnotin $names}).Count){throw 'A required app/service is missing; no package change allowed.'}
$before=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','dumpsys','package',$plan.Package)
if(-not $before.Available -or $before.Output -notmatch '(?m)^\s*User 0:.*\benabled=0\b'){throw 'Games package state differs from the approved original default state.'}
$routes=@{}
foreach($package in $required[0..5]){$routes[$package]=Read-Route $package}
$homeBefore=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','cmd','package','resolve-activity','--brief','--user','0','-a','android.intent.action.MAIN','-c','android.intent.category.HOME')
$settingsBefore=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','cmd','package','resolve-activity','--brief','--user','0','-a','android.settings.SETTINGS')
if(-not $homeBefore.Available -or -not $settingsBefore.Available -or $homeBefore.Output -notmatch '(?m)^[A-Za-z][A-Za-z0-9_.]+/[A-Za-z0-9_.$]+\s*$' -or $settingsBefore.Output -notmatch '(?m)^[A-Za-z][A-Za-z0-9_.]+/[A-Za-z0-9_.$]+\s*$'){throw 'Home or Settings unavailable before change.'}
$ledger=[ordered]@{Approved=$true;Action=$approval.Action;Package=$plan.Package;Endpoint=$connection.Serial;PreState='default (0)';ExactArguments=$plan.Command;RollbackArguments=$plan.Rollback;RollbackApproved=$true;Attempted=$false;Applied=$false;RolledBack=$false;LaunchChecksPassed=$false;LicensedPlayback='NOT TESTED';PhysicalRemoteWake='UNRESOLVED; NOT TESTED';ObservedResult='Pending'}
$ledgerPath=Join-Path $privateRoot 'games-change-private.json'
$ledger | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ledgerPath -Encoding utf8
$approval.Consumed=$true
$approval | ConvertTo-Json | Set-Content -LiteralPath $ApprovalFile -Encoding utf8
try{
    Assert-LANTVSession $connection
    $ledger.Attempted=$true
    $ledger | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ledgerPath -Encoding utf8
    $change=Invoke-AdbProcess $adb (@('-s',$connection.Serial)+$plan.Command)
    $after=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','dumpsys','package',$plan.Package)
    if(-not $change.Available -or -not $after.Available -or $after.Output -notmatch '(?m)^\s*User 0:.*\benabled=3\b'){throw 'The exact disabled-user state was not verified.'}
    $ledger.Applied=$true
    $disabled=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','pm','list','packages','-d','--user','0')
    $disabledNames=@(Get-PackageNames $disabled.Output)
    if(-not $disabled.Available -or $plan.Package -cnotin $disabledNames -or @($required | Where-Object {$_ -cin $disabledNames}).Count){throw 'Post-change package protection check failed.'}
    $homeAfter=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','cmd','package','resolve-activity','--brief','--user','0','-a','android.intent.action.MAIN','-c','android.intent.category.HOME')
    $settingsAfter=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','cmd','package','resolve-activity','--brief','--user','0','-a','android.settings.SETTINGS')
    if(-not $homeAfter.Available -or -not $settingsAfter.Available -or $homeAfter.Output -cne $homeBefore.Output -or $settingsAfter.Output -cne $settingsBefore.Output){throw 'Home/Settings resolution changed; stop and recover.'}
    foreach($package in $required[0..5]){
        if((Read-Route $package) -cne $routes[$package]){throw 'A retained-app launch route changed.'}
        $launch=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','am','start','-W','-n',$routes[$package])
        if(-not $launch.Available -or $launch.Output -notmatch '(?m)^Status:\s+ok\s*$'){throw 'A retained app did not report a successful activity launch.'}
    }
    $ledger.LaunchChecksPassed=$true
    $ledger.ObservedResult='Single-package disabled-user state verified; all six retained activities launched; licensed playback and physical remote verification remain pending.'
    $null=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','am','start','-W','-a','android.intent.action.MAIN','-c','android.intent.category.HOME')
}catch{
    $ledger.ObservedResult='Verification failed; only the approved rollback was attempted. No further changes allowed.'
    if($ledger.Attempted){$null=Invoke-AdbProcess $adb (@('-s',$connection.Serial)+$plan.Rollback);$restored=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','dumpsys','package',$plan.Package);$ledger.RolledBack=$restored.Available -and $restored.Output -match '(?m)^\s*User 0:.*\benabled=0\b'}
    $ledger | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ledgerPath -Encoding utf8
    throw 'Verification did not pass; the local change ledger records the approved rollback outcome. Stop further changes.'
}
$ledger | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ledgerPath -Encoding utf8
[pscustomobject]@{Package=$plan.Package;DisabledForUser0Verified=$ledger.Applied;AllSixActivityLaunchesPassed=$ledger.LaunchChecksPassed;LicensedPlayback='NOT TESTED';RemoteWake='UNRESOLVED';RollbackApplied=$ledger.RolledBack}
# The bounded work-session owner handles timeout restoration and ADB disconnect.
