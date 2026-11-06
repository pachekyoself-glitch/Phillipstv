#requires -Version 7.0
Set-StrictMode -Version Latest
function Get-ApprovedGamesChange {
    param([Parameter(Mandatory)]$Approval,[Parameter(Mandatory)][string]$SelectedEndpoint)
    if($Approval.Approved -isnot [bool] -or -not $Approval.Approved -or $Approval.Action -cne 'DISABLE_GOOGLE_PLAY_GAMES_USER_0' -or $Approval.Package -cne 'com.google.android.play.games' -or $Approval.Endpoint -cne $SelectedEndpoint -or $Approval.Consumed -ne $false){throw 'No unused approval for this exact single-package action and selected TV.'}
    $expiry=[DateTimeOffset]::Parse($Approval.ExpiresUtc)
    if($expiry -le [DateTimeOffset]::UtcNow -or $expiry -gt [DateTimeOffset]::UtcNow.AddMinutes(30)){throw 'Package-change approval expired or has an invalid lifetime.'}
    if($Approval.RollbackApproved -isnot [bool] -or -not $Approval.RollbackApproved){throw 'The exact default-state recovery was not approved.'}
    [pscustomobject]@{Package='com.google.android.play.games';ExpectedEnabledState='0';Command=@('shell','pm','disable-user','--user','0','com.google.android.play.games');Rollback=@('shell','pm','default-state','--user','0','com.google.android.play.games')}
}
Export-ModuleMember -Function Get-ApprovedGamesChange
