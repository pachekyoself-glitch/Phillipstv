#requires -Version 7.0
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1')

function Assert-TimeoutApproval {
    param([Parameter(Mandatory)]$Approval,[Parameter(Mandatory)][string]$Endpoint)
    if($Approval.approved -isnot [bool] -or -not $Approval.approved -or
       $Approval.action -cne 'TEMP_SCREEN_TIMEOUT_300000_TO_3600000_WITH_RESTORE' -or
       $Approval.endpoint -cne $Endpoint -or $Approval.consumed -isnot [bool] -or $Approval.consumed){
        throw 'No unused timeout approval for this exact action and TV.'
    }
    $expiry=[DateTimeOffset]::Parse($Approval.expiresUtc)
    if($expiry -le [DateTimeOffset]::UtcNow -or $expiry -gt [DateTimeOffset]::UtcNow.AddMinutes(30)){
        throw 'Timeout approval expired or has an invalid lifetime.'
    }
}

function Write-WorkSessionJson {
    param([Parameter(Mandatory)]$Value,[Parameter(Mandatory)][string]$Path)
    # Same-directory rename prevents readers seeing truncated JSON during closeout.
    $temporary=$Path+'.'+[Guid]::NewGuid().ToString('N')+'.tmp'
    try {
        [IO.File]::WriteAllText($temporary,($Value | ConvertTo-Json -Depth 8))
        [IO.File]::Move($temporary,$Path,$true)
    } finally { if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary} }
}

function Get-ActiveTVWorkConnection {
    param([ValidateRange(0,300)][int]$MinimumSeconds=30)
    $privateRoot=Join-Path (Split-Path -Parent $PSScriptRoot) '.local'
    $status=Get-Content -LiteralPath (Join-Path $privateRoot 'work-session-status.json') -Raw | ConvertFrom-Json
    if($status.Active -isnot [bool] -or -not $status.Active -or
       [DateTimeOffset]::Parse($status.ExpiresUtc) -le [DateTimeOffset]::UtcNow.AddSeconds($MinimumSeconds)){
        throw 'No live bounded work session with enough time remaining.'
    }
    $connection=Get-Content -LiteralPath (Join-Path $privateRoot 'work-session-connection-private.json') -Raw | ConvertFrom-Json
    Assert-LANTVSession $connection
    return $connection
}
Export-ModuleMember -Function Assert-TimeoutApproval,Write-WorkSessionJson,Get-ActiveTVWorkConnection
