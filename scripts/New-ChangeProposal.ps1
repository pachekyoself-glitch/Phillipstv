#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$AuditDirectory)
$ErrorActionPreference = 'Stop'
$inventory = @(Get-Content -LiteralPath (Join-Path $AuditDirectory 'inventory-private.json') -Raw | ConvertFrom-Json)
$proposal = foreach ($item in $inventory) {
    [pscustomobject]@{
        Package = $item.Package
        Classification = 'REVIEW'
        Risk = 'Unknown until dependency review'
        Purpose = 'Unverified'
        Dependencies = @()
        PrivacyImpact = 'Unverified'
        PerformanceBenefit = 'Unmeasured'
        Evidence = @()
        CurrentState = 'Inspect package-private.json and disabled list locally'
        ProposedAction = 'No change; assess supported hide/uninstall UI first'
        ExactCommand = $null
        ReversalCommand = $null
        Approved = $false
        Verification = @('Remote','Home','Settings','All six retained apps and playback','Audio','Inputs','Network','Stability')
    }
}
$path = Join-Path $AuditDirectory 'proposal-private.json'
$proposal | ConvertTo-Json -Depth 6 -AsArray | Set-Content -LiteralPath $path -Encoding utf8
Write-Output 'Draft proposal saved alongside the local audit. All packages remain REVIEW. This script cannot apply changes.'
