Import-Module (Join-Path $PSScriptRoot '../scripts/TV.WorkSession.psm1') -Force
Describe 'Target-bound single-use timeout approval' {
    BeforeEach {
        $approval=[pscustomobject]@{approved=$true;action='TEMP_SCREEN_TIMEOUT_300000_TO_3600000_WITH_RESTORE';endpoint='192.0.2.10:5555';consumed=$false;expiresUtc=[DateTimeOffset]::UtcNow.AddMinutes(10).ToString('o')}
    }
    It 'accepts an unused exact approval' {
        {Assert-TimeoutApproval $approval '192.0.2.10:5555'} | Should Not Throw
    }
    It 'rejects a different target' {
        $rejected=$false; try{Assert-TimeoutApproval $approval '192.0.2.11:5555'}catch{$rejected=$true}
        $rejected | Should Be $true
    }
    It 'rejects reuse' {
        $approval.consumed=$true
        $rejected=$false; try{Assert-TimeoutApproval $approval $approval.endpoint}catch{$rejected=$true}
        $rejected | Should Be $true
    }
    It 'rejects excessive or expired lifetimes' {
        foreach($minutes in @(-1,60)){
            $approval.expiresUtc=[DateTimeOffset]::UtcNow.AddMinutes($minutes).ToString('o')
            $rejected=$false; try{Assert-TimeoutApproval $approval $approval.endpoint}catch{$rejected=$true}
            $rejected | Should Be $true
        }
    }
}
InModuleScope TV.WorkSession {
    Describe 'Bounded work consumer expiry' {
        Mock Get-Content { '{"Active":true,"ExpiresUtc":"2000-01-01T00:00:00Z"}' }
        Mock Assert-LANTVSession { throw 'Must not reach device' }
        It 'rejects stale Active=true state before contacting the TV' {
            $rejected=$false; try{Get-ActiveTVWorkConnection|Out-Null}catch{$rejected=$_.Exception.Message -like 'No live bounded*'}
            $rejected | Should Be $true
            Assert-MockCalled Assert-LANTVSession -Times 0
        }
    }
}
