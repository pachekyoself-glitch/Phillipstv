#requires -Version 7.0
[CmdletBinding()]
param([string]$SessionFile=(Join-Path (Split-Path -Parent $PSScriptRoot) '.local/lan-session.json'),[Parameter(Mandatory)][string]$ApprovalFile,[ValidateRange(1,20)][int]$WorkMinutes=20)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TV.WorkSession.psm1') -Force
$privateRoot=Join-Path (Split-Path -Parent $PSScriptRoot) '.local'
if([IO.Path]::GetFullPath((Split-Path -Parent $SessionFile)).TrimEnd('\','/') -ine [IO.Path]::GetFullPath($privateRoot).TrimEnd('\','/')){throw 'Work-session files must use the project .local directory so every consumer and close command uses the same state.'}
$approval=Get-Content -LiteralPath $ApprovalFile -Raw | ConvertFrom-Json
$target=Get-LANTarget $SessionFile
Assert-TimeoutApproval $approval $target.Endpoint
$adb=Resolve-Adb
$connection=$null
$connectionAttempted=$false
$record=$null
$recordPath=Join-Path $privateRoot 'timeout-change-private.json'
$statusPath=Join-Path $privateRoot 'work-session-status.json'
$closeName='close-work-session-'+[Guid]::NewGuid().ToString('N')+'.flag'
try{$ownerLock=[IO.File]::Open((Join-Path $privateRoot 'work-session-owner.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)}catch{throw 'Another bounded work-session owner holds the local lock.'}
try{
    if(Test-Path -LiteralPath $statusPath){$oldStatus=Get-Content -LiteralPath $statusPath -Raw|ConvertFrom-Json;if($oldStatus.Active){throw 'A work-session owner is already active; close or recover it before starting another.'}}
    if(Test-Path -LiteralPath $recordPath){$old=Get-Content -LiteralPath $recordPath -Raw|ConvertFrom-Json;if($old.RestoreRequired){throw 'A prior timeout restoration remains outstanding, even if application was not verified. Recover it before starting another.'}}
    $connectionAttempted=$true
    $connection=Get-LANTVConnection -SessionFile $SessionFile -AdbPath $adb -AuthorizationWaitSeconds 90
    $before=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','settings','get','system','screen_off_timeout')
    if(-not $before.Available -or $before.Output -cne '300000'){throw 'Screen timeout no longer matches the approved 5-minute pre-state. No setting changed.'}
    $record=[ordered]@{SchemaVersion=2;Approved=$true;ApprovalAction=$approval.action;ApprovedAtUtc=$approval.approvedAtUtc;Endpoint=$connection.Serial;OriginalValue='300000';TemporaryValue='3600000';RestoreRequired=$true;Attempted=$true;Applied=$false;Restored=$false}
    Write-WorkSessionJson $record $recordPath
    $approval.consumed=$true
    Write-WorkSessionJson $approval $ApprovalFile
    $change=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','settings','put','system','screen_off_timeout','3600000')
    $after=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','settings','get','system','screen_off_timeout')
    $record.Applied=$change.Available -and $after.Available -and $after.Output -ceq '3600000'
    Write-WorkSessionJson $record $recordPath
    if(-not $record.Applied){throw 'Temporary timeout not verified. Stop and run only approved recovery.'}
    $deadline=[DateTimeOffset]::UtcNow.AddMinutes($WorkMinutes)
    $leaseEnd=[DateTimeOffset]::Parse($connection.ExpiresUtc)
    if($deadline -gt $leaseEnd){$deadline=$leaseEnd}
    Write-WorkSessionJson $connection (Join-Path $privateRoot 'work-session-connection-private.json')
    Write-WorkSessionJson @{Active=$true;ExpiresUtc=$deadline.ToString('o');CloseRequestFile=$closeName;TemporaryTimeoutVerified=$true;Restored=$false} $statusPath
    Write-Output 'Active bounded work session: approved 60-minute screen timeout verified. Automatic restoration is due at closeout or session expiry. Address omitted.'
    # No network listener or command queue: wait only for a local close flag/deadline.
    # The caller can perform separately authorized operations using this existing ADB connection.
    while([DateTimeOffset]::UtcNow -lt $deadline -and -not(Test-Path -LiteralPath (Join-Path $privateRoot $closeName))){Start-Sleep -Seconds 1}
}finally{
    try{
    if($connection -and $record -and $record.RestoreRequired){
        try{
            $current=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','settings','get','system','screen_off_timeout')
            if($current.Available -and $current.Output -ceq '3600000'){$null=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','settings','put','system','screen_off_timeout','300000');$current=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','settings','get','system','screen_off_timeout')}
            $record.Restored=$current.Available -and $current.Output -ceq '300000'
            $record.RestoreRequired=-not $record.Restored
            Write-WorkSessionJson $record $recordPath
            Write-WorkSessionJson @{Active=$false;TemporaryTimeoutVerified=$record.Applied;Restored=$record.Restored;RestoreRequired=$record.RestoreRequired} $statusPath
            if($record.Restored){Write-Output 'Original 5-minute screen timeout restored and verified.'}else{Write-Warning 'Original timeout restoration is not verified. The local rollback record remains open; do not claim closeout complete.'}
        }catch{
            try{Write-WorkSessionJson @{Active=$false;TemporaryTimeoutVerified=$record.Applied;Restored=$false;RestoreRequired=$true} $statusPath}catch{Write-Warning 'Recovery status could not be persisted. Keep the original restore obligation open.'}
            Write-Warning 'Timeout rollback encountered an error; inspect the local record. Restoration remains required.'
        }
    }
    }finally{
    try{
        if($connection){$null=Invoke-AdbProcess $adb @('disconnect',$connection.Serial)}
    }finally{
        try{if($connectionAttempted){$null=Invoke-AdbProcess $adb @('kill-server')}}finally{$ownerLock.Dispose()}
    }
    }
}
