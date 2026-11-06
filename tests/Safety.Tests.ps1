# Uses the Pester 3 syntax installed on the preparation host.
Import-Module (Join-Path $PSScriptRoot '../scripts/TV.Common.psm1') -Force

# Pester 3's Throw assertion does not reliably recognize PowerShell 7 exceptions.
# Assert the observed terminating-error behavior explicitly.
function Test-Throws {
    param([scriptblock]$Action)
    try { & $Action | Out-Null; return $false } catch { return $true }
}

Describe 'USB connection parser and safety' {
    It 'recognizes devices without selecting or exposing them' {
        $devices = @(ConvertFrom-AdbDevices "List of devices attached`nTEST-USB device product:tv model:Example transport_id:1`nTEST-OTHER unauthorized usb:1-2")
        $devices.Count | Should Be 2
        $devices[1].State | Should Be 'unauthorized'
    }
    It 'accepts positively verified USB transport' {
        { Assert-UsbTransport 'TEST-USB' 'usb:1-2' } | Should Not Throw
    }
    It 'rejects a network serial even with misleading USB metadata' {
        (Test-Throws { Assert-UsbTransport '192.0.2.1:5555' 'usb:1-2' }) | Should Be $true
    }
    It 'rejects unverified transport' {
        (Test-Throws { Assert-UsbTransport 'TEST-USB' 'local' }) | Should Be $true
    }
    It 'rejects mdns wireless serials' {
        (Test-Throws { Assert-UsbTransport 'adb-TEST._adb-tls-connect._tcp' 'usb:1-2' }) | Should Be $true
    }
    It 'does not treat a header or daemon text as a device' {
        @(ConvertFrom-AdbDevices "List of devices attached`n* daemon started successfully *").Count | Should Be 0
    }
}

Describe 'Read-only configuration and inventory handling' {
    It 'accepts the reviewed query allowlist' {
        $config = Get-AuditConfiguration
        ($config.queries.Count -gt 20) | Should Be $true
    }
    It 'rejects dangerous package text and returns only parsed package ids' {
        $packages = @(Get-PackageNames "package:org.example.safe installer=null`npackage:org.example.other`npackage:org.example.bad;reboot`npackage:../../escape")
        $packages.Count | Should Be 2
        ($packages -contains 'org.example.safe') | Should Be $true
    }
    It 'rejects output inside the repository before creating it' {
        (Test-Throws { New-PrivateAuditDirectory (Join-Path (Get-ProjectRoot) 'reports/private') }) | Should Be $true
    }
    It 'rejects a known cloud sync path before creating it' {
        (Test-Throws { New-PrivateAuditDirectory 'C:\Users\Example\OneDrive\private' }) | Should Be $true
    }
    It 'rejects network output' {
        (Test-Throws { New-PrivateAuditDirectory '\\example\share\private' }) | Should Be $true
    }
}

InModuleScope TV.Common {
    Describe 'Standalone workflow session ownership' {
        Mock Test-Path { $true }
        It 'blocks a live owner before any standalone operation' {
            Mock Get-Content { '{"Active":true}' }
            $rejected=$false; try{Assert-NoTVWorkSession}catch{$rejected=$true}
            $rejected | Should Be $true
        }
        It 'blocks an unresolved restoration even after the owner ended' {
            Mock Get-Content { '{"Active":false,"RestoreRequired":true}' }
            $rejected=$false; try{Assert-NoTVWorkSession}catch{$rejected=$true}
            $rejected | Should Be $true
        }
        It 'allows a verified closed session' {
            Mock Get-Content { '{"Active":false,"RestoreRequired":false}' }
            { Assert-NoTVWorkSession } | Should Not Throw
        }
    }
    Describe 'Local ADB daemon startup regression' {
        It 'uses the literal localhost socket instead of a numeric remote host' {
            $info = New-AdbStartInfo -AdbPath 'TEST-ADB-NOT-EXECUTED' -Arguments @('devices','-l')
            ($info.ArgumentList -join ' ') | Should Be '-L tcp:localhost:5037 devices -l'
            $info.UseShellExecute | Should Be $false
        }
        It 'disables automatic mdns connections for a newly started daemon' {
            $info = New-AdbStartInfo -AdbPath 'TEST-ADB-NOT-EXECUTED' -Arguments @('devices','-l')
            $info.Environment['ADB_MDNS_AUTO_CONNECT'] | Should Be '0'
        }
    }
    Describe 'Connection failures stop before inventory' {
        Mock Resolve-Adb { 'TEST-ADB-NOT-EXECUTED' }
        Mock Invoke-AdbProcess {
            if ($Arguments[0] -eq 'version') {
                return [pscustomobject]@{ Available=$true; Output='Android Debug Bridge version 1.0.41'; ExitCode=0; Error='' }
            }
            return [pscustomobject]@{ Available=$true; Output='List of devices attached'; ExitCode=0; Error='' }
        }
        It 'rejects an empty device list' {
            $rejected = $false
            try { Get-TVConnection | Out-Null } catch { $rejected = $_.Exception.Message -like 'No ADB device*' }
            $rejected | Should Be $true
        }
        It 'requires explicit selection if multiple devices appear' {
            Mock ConvertFrom-AdbDevices {
                [pscustomobject]@{Serial='TEST-ONE';State='device';Detail=''}
                [pscustomobject]@{Serial='TEST-TWO';State='device';Detail=''}
            }
            $rejected = $false
            try { Get-TVConnection | Out-Null } catch { $rejected = $_.Exception.Message -like 'Multiple devices*' }
            $rejected | Should Be $true
        }
        It 'stops at RSA authorization' {
            Mock ConvertFrom-AdbDevices { [pscustomobject]@{Serial='TEST-ONE';State='unauthorized';Detail=''} }
            $rejected = $false
            try { Get-TVConnection | Out-Null } catch { $rejected = $_.Exception.Message -like 'Accept the RSA*' }
            $rejected | Should Be $true
        }
        It 'rejects an unavailable explicitly selected device' {
            Mock ConvertFrom-AdbDevices { [pscustomobject]@{Serial='TEST-ONE';State='device';Detail=''} }
            $rejected = $false
            try { Get-TVConnection -Serial 'TEST-MISSING' | Out-Null } catch { $rejected = $_.Exception.Message -like 'The explicitly selected device*' }
            $rejected | Should Be $true
        }
    }
}
