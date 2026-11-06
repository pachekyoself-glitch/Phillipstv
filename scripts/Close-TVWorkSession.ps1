#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$privateRoot=Join-Path (Split-Path -Parent $PSScriptRoot) '.local'
$statusPath=Join-Path $privateRoot 'work-session-status.json'
if(-not(Test-Path -LiteralPath $statusPath)){Write-Output 'No bounded work-session record exists.';return}
$status=Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
if($status.Active){
    if($status.CloseRequestFile -notmatch '^close-work-session-[a-f0-9]{32}\.flag$'){throw 'Invalid local session-close request name.'}
    [IO.File]::WriteAllText((Join-Path $privateRoot $status.CloseRequestFile),'')
    $deadline=[DateTimeOffset]::UtcNow.AddSeconds(30)
    do{Start-Sleep -Seconds 1;$status=Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json}while($status.Active -and [DateTimeOffset]::UtcNow -lt $deadline)
}
if($status.Active){throw 'The work session has not confirmed closure. Do not claim restoration complete.'}
if(-not $status.Restored -or $status.RestoreRequired){throw 'The original timeout has not been confirmed restored. Inspect the private rollback ledger.'}
Write-Output 'Bounded work session closed; original 5-minute screen timeout restoration verified.'
