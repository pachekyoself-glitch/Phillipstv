#requires -Version 7.0
[CmdletBinding()]
param([switch]$RequireActualTarget,[switch]$RequirePublicMetadata,[ValidatePattern('^[a-fA-F0-9]{40}$')][string]$HistoryCommit)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$addresses = @()
$targetFile = Join-Path $root '.local/tv-address.txt'
if (Test-Path -LiteralPath $targetFile) {
    $addresses += @(Get-Content -LiteralPath $targetFile | ForEach-Object {$_.Trim()} | Where-Object {$_ -match '^\d{1,3}(?:\.\d{1,3}){3}$'})
}
$sessionFile = Join-Path $root '.local/lan-session.json'
if (Test-Path -LiteralPath $sessionFile) {
    try { $addresses += (Get-Content -LiteralPath $sessionFile -Raw | ConvertFrom-Json -ErrorAction Stop).address }
    catch { throw 'The private session file is invalid; inspect it locally. Publication stopped.' }
}
$addresses = @($addresses | Where-Object {$_} | Sort-Object -Unique)
if($RequireActualTarget -and -not $addresses.Count){throw 'No private target is available for comparison. Publication stopped; enter the TV target locally.'}
$tracked = @(& git -C $root ls-files)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect tracked publication paths.' }
if (@($tracked | Where-Object {$_ -match '^(\.local|\.tools)/'}).Count) { throw 'A private/tool path is tracked. Publication stopped.' }
foreach ($path in @('.local/tv-address.txt','.local/lan-session.json','.local/lan-connection-private.json')) {
    & git -C $root check-ignore --quiet -- $path
    if ($LASTEXITCODE -ne 0) { throw 'A private TV target file is not ignored. Publication stopped.' }
}
$blobsChecked = 0
[string[]]$historyArguments=@(if($HistoryCommit){$HistoryCommit}else{'--all'})
if($RequirePublicMetadata){
    $emails=@(& git -C $root log '--format=%ae%n%ce' @historyArguments)
    if($LASTEXITCODE -ne 0){throw 'Commit-identity inspection failed.'}
    if(@($emails|Where-Object {$_ -notmatch '^(?:[0-9]+\+)?[A-Za-z0-9-]+@users\.noreply\.github\.com$|^[A-Za-z0-9._+-]+@example\.invalid$'}).Count){
        throw 'Non-noreply author or committer metadata exists in the publication history. Keep the repository private; identities omitted.'
    }
}
if ($addresses.Count) {
    foreach ($address in $addresses) {
        & git -C $root grep --cached --quiet --fixed-strings -e $address
        if ($LASTEXITCODE -eq 0) { throw 'Actual TV address found in staged content. Publication stopped; address omitted.' }
        if ($LASTEXITCODE -ne 1) { throw 'Staged private-address check could not complete.' }
    }
    $objects = @(& git -C $root rev-list --objects @historyArguments)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect reachable Git history.' }
    foreach ($entry in $objects) {
        if ($entry -notmatch '^([a-fA-F0-9]{40})(?:\s|$)') { throw 'Unexpected Git object format.' }
        $objectId = $Matches[1]
        if($entry -match '^[a-fA-F0-9]{40}\s+(?:\.local|\.tools)/'){throw 'A private/tool path exists in reachable history. Publication stopped.'}
        foreach($address in $addresses){if($entry.Contains($address,[StringComparison]::Ordinal)){throw 'Actual TV address found in a historical path. Publication stopped; address omitted.'}}
        $type = & git -C $root cat-file -t $objectId
        if ($LASTEXITCODE -ne 0) { throw 'Git object type check failed.' }
        if ($type -notin @('blob','commit','tag')) { continue }
        $content = (& git -C $root cat-file $type $objectId) -join "`n"
        if ($LASTEXITCODE -ne 0) { throw 'Git blob privacy inspection failed.' }
        if($type -eq 'blob'){$blobsChecked++}
        foreach ($address in $addresses) {
            if ($content.Contains($address,[StringComparison]::Ordinal)) { throw 'Actual TV address found in reachable Git history. Stop publication and review remediation; address omitted.' }
        }
    }
}
[pscustomobject]@{PrivateFilesIgnored=$true;ActualTargetCompared=($addresses.Count -gt 0);ReachableGitBlobsChecked=$blobsChecked;ActualAddressMatch=$false;PublicCommitMetadataChecked=$RequirePublicMetadata.IsPresent;HistoryScope=if($HistoryCommit){'Selected commit ancestry'}else{'All reachable refs'}}
