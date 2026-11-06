Import-Module (Join-Path $PSScriptRoot '../scripts/LAN.Common.psm1') -Force
Describe 'Single-target private LAN validation' {
    It 'accepts a private TV address' {
        $rejected = $false
        try { Assert-PrivateTVAddress '192.168.1.25' } catch { $rejected=$true }
        $rejected | Should Be $false
    }
    It 'rejects public, loopback, hostnames, invalid and injected addresses' {
        foreach ($address in @('8.8.8.8','127.0.0.1','169.254.1.1','172.32.0.1','tv.example','192.168.1.25;reboot','192.168.001.25','192.168.1.999','::1')) {
            $rejected = $false
            try { Assert-PrivateTVAddress $address } catch { $rejected=$true }
            $rejected | Should Be $true
        }
    }
}
InModuleScope LAN.Common {
    Describe 'Scoped LAN audit lease' {
        Mock Get-Content { '{"schemaVersion":1,"address":"192.168.1.25","port":5555,"ownerConfirmedTV":true,"readOnlyAudit":true,"expiresUtc":"2000-01-01T00:00:00Z"}' }
        It 'rejects an expired session before connection' {
            $rejected = $false
            try { Get-LANTarget 'TEST-NOT-READ' | Out-Null } catch { $rejected=$true }
            $rejected | Should Be $true
        }
        It 'rejects a target the owner has not confirmed' {
            Mock Get-Content { (@{schemaVersion=1;address='192.168.1.25';port=5555;ownerConfirmedTV=$false;readOnlyAudit=$true;expiresUtc=[DateTimeOffset]::UtcNow.AddMinutes(10).ToString('o')} | ConvertTo-Json) }
            $rejected = $false
            try { Get-LANTarget 'TEST-NOT-READ' | Out-Null } catch { $rejected=$true }
            $rejected | Should Be $true
        }
        It 'accepts a confirmed short-lived session on port 5555' {
            Mock Get-Content { (@{schemaVersion=1;address='192.168.1.25';port=5555;ownerConfirmedTV=$true;readOnlyAudit=$true;expiresUtc=[DateTimeOffset]::UtcNow.AddMinutes(10).ToString('o')} | ConvertTo-Json) }
            (Get-LANTarget 'TEST-NOT-READ').Endpoint | Should Be '192.168.1.25:5555'
        }
        It 'rejects a different port' {
            Mock Get-Content { (@{schemaVersion=1;address='192.168.1.25';port=1234;ownerConfirmedTV=$true;readOnlyAudit=$true;expiresUtc=[DateTimeOffset]::UtcNow.AddMinutes(10).ToString('o')} | ConvertTo-Json) }
            $rejected = $false
            try { Get-LANTarget 'TEST-NOT-READ' | Out-Null } catch { $rejected=$true }
            $rejected | Should Be $true
        }
        It 'rejects an excessive session lifetime' {
            Mock Get-Content { (@{schemaVersion=1;address='192.168.1.25';port=5555;ownerConfirmedTV=$true;readOnlyAudit=$true;expiresUtc=[DateTimeOffset]::UtcNow.AddHours(2).ToString('o')} | ConvertTo-Json) }
            $rejected = $false
            try { Get-LANTarget 'TEST-NOT-READ' | Out-Null } catch { $rejected=$true }
            $rejected | Should Be $true
        }
    }
    Describe 'LAN authorization stops before inventory' {
        Mock Resolve-Adb { 'TEST-ADB-NOT-EXECUTED' }
        Mock Get-LANTarget { [pscustomobject]@{Endpoint='192.168.1.25:5555';Expires=[DateTimeOffset]::UtcNow.AddMinutes(10)} }
        Mock Invoke-AdbProcess {
            if ($Arguments[0] -eq 'version') { return [pscustomobject]@{Available=$true;Output='Android Debug Bridge version 1.0.41';Error='';ExitCode=0} }
            if ($Arguments[0] -eq 'devices') { return [pscustomobject]@{Available=$true;Output="List of devices attached`n192.168.1.25:5555 unauthorized";Error='';ExitCode=0} }
            return [pscustomobject]@{Available=$true;Output='';Error='';ExitCode=0}
        }
        It 'rejects unauthorized state and disconnects without shell queries' {
            $rejected = $false
            try { Get-LANTVConnection -SessionFile 'TEST-NOT-READ' | Out-Null } catch { $rejected = $_.Exception.Message -like 'Accept this trusted PC*' }
            $rejected | Should Be $true
            Assert-MockCalled Invoke-AdbProcess -Times 0 -ParameterFilter { $Arguments[0] -eq '-s' }
            Assert-MockCalled Invoke-AdbProcess -Times 1 -ParameterFilter { $Arguments[0] -eq 'disconnect' }
        }
        It 'does not select another available LAN device' {
            Mock Invoke-AdbProcess {
                if ($Arguments[0] -eq 'version') { return [pscustomobject]@{Available=$true;Output='Android Debug Bridge version 1.0.41';Error='';ExitCode=0} }
                if ($Arguments[0] -eq 'devices') { return [pscustomobject]@{Available=$true;Output="List of devices attached`n192.168.1.26:5555 device";Error='';ExitCode=0} }
                return [pscustomobject]@{Available=$true;Output='';Error='';ExitCode=0}
            }
            $rejected = $false
            try { Get-LANTVConnection -SessionFile 'TEST-NOT-READ' | Out-Null } catch { $rejected = $_.Exception.Message -like 'No ADB device answered*' }
            $rejected | Should Be $true
            Assert-MockCalled Invoke-AdbProcess -Times 0 -ParameterFilter { $Arguments[0] -eq '-s' }
        }
    }
}
