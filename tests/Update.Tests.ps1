Import-Module (Join-Path $PSScriptRoot '../scripts/TV.Update.psm1') -Force
Describe 'Update-check action safety' {
    It 'targets the enabled Check control owned by the verified system handler' {
        [xml]$tree='<hierarchy><node text="Check for updates" enabled="true" package="org.example.system" bounds="[100,200][300,260]"/></hierarchy>'
        $point=Get-VerifiedUpdateCheckTap $tree 'org.example.system'
        $point.X | Should Be 200
        $point.Y | Should Be 230
    }
    It 'never treats Install as an update-check action' {
        [xml]$tree='<hierarchy><node text="Install" enabled="true" package="org.example.system" bounds="[100,200][300,260]"/></hierarchy>'
        $rejected=$false
        try {Get-VerifiedUpdateCheckTap $tree 'org.example.system' | Out-Null} catch {$rejected=$true}
        $rejected | Should Be $true
    }
    It 'rejects a spoofed Check label from a different package' {
        [xml]$tree='<hierarchy><node text="Check for updates" enabled="true" package="org.example.other" bounds="[100,200][300,260]"/></hierarchy>'
        $rejected=$false
        try {Get-VerifiedUpdateCheckTap $tree 'org.example.system' | Out-Null} catch {$rejected=$true}
        $rejected | Should Be $true
    }
    It 'rejects disabled, ambiguous, and out-of-bounds controls' {
        foreach($xmlText in @('<hierarchy><node text="Check for updates" enabled="false" package="org.example.system" bounds="[100,200][300,260]"/></hierarchy>','<hierarchy><node text="Check now" enabled="true" package="org.example.system" bounds="[100,200][300,260]"/><node text="Check for updates" enabled="true" package="org.example.system" bounds="[100,200][300,260]"/></hierarchy>','<hierarchy><node text="Check for updates" enabled="true" package="org.example.system" bounds="[100,200][9999,260]"/></hierarchy>')) {
            $rejected=$false
            try {Get-VerifiedUpdateCheckTap ([xml]$xmlText) 'org.example.system' | Out-Null} catch {$rejected=$true}
            $rejected | Should Be $true
        }
    }
}
