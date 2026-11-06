#requires -Version 7.0
[CmdletBinding()]
param([string]$TargetFile = (Join-Path (Split-Path -Parent $PSScriptRoot) '.local/tv-address.txt'))
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
$lines = @(Get-Content -LiteralPath $TargetFile | ForEach-Object {$_.Trim()} | Where-Object {$_ -and -not $_.StartsWith('#')})
if ($lines.Count -ne 1) { throw 'Save exactly one TV private IPv4 address in the local target file, without posting it to chat.' }
Assert-PrivateTVAddress $lines[0]
$privateRoot = Join-Path (Split-Path -Parent $PSScriptRoot) '.local'
New-Item -ItemType Directory -Path $privateRoot -Force | Out-Null
@{schemaVersion=1;address=$lines[0];port=5555;ownerConfirmedTV=$true;readOnlyAudit=$true;expiresUtc=[DateTimeOffset]::UtcNow.AddMinutes(20).ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'lan-session.json') -Encoding utf8
Write-Output 'Owner-entered TV target imported locally with a 20-minute read-only session. Address not displayed.'
