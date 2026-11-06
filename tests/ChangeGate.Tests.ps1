Import-Module (Join-Path $PSScriptRoot '../scripts/TV.ChangeGate.psm1') -Force
Describe 'Single-package approval gate' {
    It 'permits only the selected target and exact approved Games action' {
        $approval=[pscustomobject]@{Approved=$true;Action='DISABLE_GOOGLE_PLAY_GAMES_USER_0';Package='com.google.android.play.games';Endpoint='TEST-TV';Consumed=$false;RollbackApproved=$true;ExpiresUtc=[DateTimeOffset]::UtcNow.AddMinutes(10).ToString('o')}
        ((Get-ApprovedGamesChange $approval 'TEST-TV').Command -join ' ') | Should Be 'shell pm disable-user --user 0 com.google.android.play.games'
    }
    It 'rejects declined, wrong-package, wrong-target, consumed, expired or recovery-less approvals' {
        foreach($case in @('declined','package','target','consumed','expired','recovery')){
            $approval=[pscustomobject]@{Approved=$true;Action='DISABLE_GOOGLE_PLAY_GAMES_USER_0';Package='com.google.android.play.games';Endpoint='TEST-TV';Consumed=$false;RollbackApproved=$true;ExpiresUtc=[DateTimeOffset]::UtcNow.AddMinutes(10).ToString('o')}
            switch($case){'declined'{$approval.Approved=$false};'package'{$approval.Package='com.google.android.gms'};'target'{$approval.Endpoint='OTHER-TV'};'consumed'{$approval.Consumed=$true};'expired'{$approval.ExpiresUtc='2000-01-01T00:00:00Z'};'recovery'{$approval.RollbackApproved=$false}}
            $rejected=$false
            try{Get-ApprovedGamesChange $approval 'TEST-TV' | Out-Null}catch{$rejected=$true}
            $rejected | Should Be $true
        }
    }
}
