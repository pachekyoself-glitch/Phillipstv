#requires -Version 7.0
[CmdletBinding()]
param([switch]$CheckGit)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failures = [Collections.Generic.List[string]]::new()
$scripts = @(Get-ChildItem -LiteralPath (Join-Path $root 'scripts'),(Join-Path $root 'tests') -Recurse -File | Where-Object Extension -In '.ps1','.psm1')
foreach ($file in $scripts) {
    $tokens = $null; $parseErrors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$parseErrors)
    if ($parseErrors.Count) { $failures.Add('PowerShell parse failed: ' + $file.Name) }
}
foreach ($directory in @('config','kids-learning')) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root $directory) -Recurse -File -Filter '*.json') {
        try { $null = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -ErrorAction Stop }
        catch { $failures.Add('Invalid JSON: ' + $file.Name) }
    }
}
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
try { $null = Get-AuditConfiguration } catch { $failures.Add($_.Exception.Message) }
$sources = Get-Content -LiteralPath (Join-Path $root 'kids-learning/sources.json') -Raw | ConvertFrom-Json
if (@($sources.approvedItems).Count -ne 0) { $failures.Add('Approved content requires a new explicit evidence review; baseline must have an empty library.') }
if ($CheckGit) {
    $tracked = @(& git -C $root ls-files)
    if ($LASTEXITCODE -ne 0) { throw 'Git file enumeration failed.' }
    foreach ($path in $tracked) {
        $allowed = $path -cmatch '^(README\.md|AGENTS\.md|CONTRIBUTING\.md|SECURITY\.md|THIRD-PARTY-NOTICES\.md|LICENSE|\.gitignore|(?:docs|launcher-research)/[A-Za-z0-9_-]+\.md|(?:scripts|tests)/[A-Za-z0-9_.-]+\.(?:ps1|psm1)|config/[A-Za-z0-9_.-]+\.json|kids-learning/(?:APPROVAL\.md|IMPLEMENTATION\.md|PARENT-REVIEW\.md|INSTITUTIONAL-REVIEW\.md|sources\.json|content-item\.template\.json|library/README\.md)|reports/README\.md|rollback/README\.md)$'
        if (-not $allowed) { $failures.Add('Non-allowlisted publication path: ' + $path) }
    }
    foreach ($sensitivePath in @('.tools/provenance.json','reports/device.json','rollback/device.json','kids-learning/library/lesson.pdf','.local/approval.json')) {
        & git -C $root check-ignore --quiet -- $sensitivePath
        if ($LASTEXITCODE -ne 0) { $failures.Add('Missing ignore coverage: ' + $sensitivePath) }
    }
    & (Join-Path $PSScriptRoot 'Test-PrivatePublication.ps1') | Out-Null
}
if ($failures.Count) { throw ($failures -join "`n") }
Write-Output ('Project checks passed: ' + $scripts.Count + ' PowerShell files parsed; JSON and read-only allowlist validated. Device checks remain separate.')
