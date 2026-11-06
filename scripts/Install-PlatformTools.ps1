#requires -Version 7.0
[CmdletBinding()]
param([switch]$AcceptGoogleSdkLicense)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $AcceptGoogleSdkLicense) { throw 'Review https://developer.android.com/tools/releases/platform-tools and the Google SDK license, then explicitly pass -AcceptGoogleSdkLicense.' }
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Assert-NoTVWorkSession
$toolRoot = Join-Path (Split-Path -Parent $PSScriptRoot) '.tools'
New-Item -ItemType Directory -Path $toolRoot -Force | Out-Null
$metadataPath = Join-Path $toolRoot 'google-repository.xml'
Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/repository2-1.xml' -OutFile $metadataPath
[xml]$metadata = Get-Content -LiteralPath $metadataPath -Raw
$package = @($metadata.SelectNodes("//*[local-name()='remotePackage'][@path='platform-tools']")) | Where-Object { $_.GetAttribute('obsolete') -ne 'true' } | Select-Object -First 1
if (-not $package) { throw 'Official Platform Tools package metadata not found.' }
$archive = @($package.archives.archive) | Where-Object { $_.'host-os' -eq 'windows' } | Select-Object -First 1
$complete = $archive.complete
$fileName = [string]$complete.url
if ($fileName -notmatch '^platform-tools_r[0-9.]+-win\.zip$') { throw 'Unexpected Google archive URL; refusing download.' }
$checksum = [string]$complete.checksum
if ($checksum -notmatch '^[a-fA-F0-9]{40}$') { throw 'Unsupported or missing Google archive checksum; review metadata before proceeding.' }
$zipPath = Join-Path $toolRoot $fileName
Invoke-WebRequest -Uri ('https://dl.google.com/android/repository/' + $fileName) -OutFile $zipPath
if ((Get-Item -LiteralPath $zipPath).Length -ne [long]$complete.size) { throw 'Google archive size mismatch.' }
if ((Get-FileHash -LiteralPath $zipPath -Algorithm SHA1).Hash -ine $checksum) { throw 'Google archive checksum mismatch.' }
# Extract only the official tool package into the ignored tool directory; do not execute archive scripts.
Expand-Archive -LiteralPath $zipPath -DestinationPath $toolRoot -Force
$adb = Join-Path $toolRoot 'platform-tools/adb.exe'
if (-not (Test-Path -LiteralPath $adb)) { throw 'Verified archive did not contain adb.exe.' }
@{ Archive = $fileName; Origin = 'https://dl.google.com/android/repository/'; GoogleSha1 = $checksum; LocalSha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash; AcceptedLicense = $true } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $toolRoot 'provenance.json') -Encoding utf8
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
$result = Invoke-AdbProcess $adb @('version')
if (-not $result.Available -or $result.Output -notmatch 'Android Debug Bridge version') { throw 'Installed ADB version verification failed.' }
Write-Output $result.Output
Write-Output 'Installed verified official Google Platform Tools in ignored .tools. No TV changes performed.'
