#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TV.WorkSession.psm1') -Force
$privateRoot=Join-Path (Split-Path -Parent $PSScriptRoot) '.local'
$connection=Get-ActiveTVWorkConnection -MinimumSeconds 60
$adb=$connection.AdbPath
function Read-PrivateTree([string]$Name){
    $result=Invoke-AdbProcess $adb @('-s',$connection.Serial,'exec-out','uiautomator','dump','/dev/stdout') -TimeoutSeconds 20
    $result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot ('privacy-'+$Name+'-private.json')) -Encoding utf8
    if(-not $result.Available -or $result.Output -notmatch '(?s)(<\?xml.*?</hierarchy>)'){throw 'Native privacy UI could not be read. No privacy setting changed.'}
    return [xml]$Matches[1]
}
function Open-ReadOnlyEntry([xml]$Tree,[string]$LabelPattern,[string]$OwnerPackage){
    $nodes=@($Tree.SelectNodes('//node') | Where-Object {$_.GetAttribute('text') -match $LabelPattern -and $_.GetAttribute('enabled') -eq 'true' -and $_.GetAttribute('package') -ceq $OwnerPackage})
    if($nodes.Count -ne 1){return $false}
    if($nodes[0].GetAttribute('bounds') -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$'){return $false}
    $x1=[int]$Matches[1];$y1=[int]$Matches[2];$x2=[int]$Matches[3];$y2=[int]$Matches[4]
    if($x2 -le $x1 -or $y2 -le $y1 -or $x2 -gt 4096 -or $y2 -gt 4096){return $false}
    $result=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','input','tap',([string][int](($x1+$x2)/2)),([string][int](($y1+$y2)/2)))
    return $result.Available
}
$summary=[ordered]@{AboutOpened=$false;LegalPageOpened=$false;AnokiEntryVisible=$false;AnokiPageOpened=$false;CheckboxCount=0;CheckedCheckboxCount=0;DisagreeOrDeclineControlVisible=$false;PrivacySettingsChanged=$false;ConsentState='UNVERIFIED'}
try{
    $resolve=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','cmd','package','resolve-activity','--brief','--user','0','-a','android.settings.DEVICE_INFO_SETTINGS')
    $components=@($resolve.Output -split '\r?\n' | Where-Object {$_ -cmatch '^[A-Za-z][A-Za-z0-9_.]+/[A-Za-z0-9_.$]+$'})
    if(-not $resolve.Available -or $components.Count -ne 1){throw 'Supported About screen did not resolve.'}
    $package=$components[0].Split('/')[0]
    $detail=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','dumpsys','package',$package)
    if(-not $detail.Available -or $detail.Output -notmatch '(?m)^\s*pkgFlags=\[.*\bSYSTEM\b'){throw 'About screen is not a verified system handler.'}
    $launch=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','am','start','-W','-n',$components[0],'-a','android.settings.DEVICE_INFO_SETTINGS')
    if(-not $launch.Available){throw 'Could not open supported About screen.'}
    $summary.AboutOpened=$true
    $tree=Read-PrivateTree 'about'
    if(Open-ReadOnlyEntry $tree '(?i)^legal information$' $package){
        $summary.LegalPageOpened=$true
        $tree=Read-PrivateTree 'legal'
        $summary.AnokiEntryVisible=@($tree.SelectNodes('//node') | Where-Object {$_.GetAttribute('text') -match '(?i)^Anoki Viewing Information Service$'}).Count -eq 1
        if($summary.AnokiEntryVisible -and (Open-ReadOnlyEntry $tree '(?i)^Anoki Viewing Information Service$' $package)){
            $summary.AnokiPageOpened=$true
            $tree=Read-PrivateTree 'anoki'
            $checkboxes=@($tree.SelectNodes('//node') | Where-Object {$_.GetAttribute('checkable') -eq 'true'})
            $summary.CheckboxCount=$checkboxes.Count
            $summary.CheckedCheckboxCount=@($checkboxes | Where-Object {$_.GetAttribute('checked') -eq 'true'}).Count
            $summary.DisagreeOrDeclineControlVisible=@($tree.SelectNodes('//node') | Where-Object {$_.GetAttribute('text') -match '(?i)^(?:disagree|decline|opt out)$'}).Count -gt 0
        }
    }
    $summary | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'privacy-summary-private.json') -Encoding utf8
    $summary | ConvertTo-Json
}finally{
    $null=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','am','start','-W','-a','android.intent.action.MAIN','-c','android.intent.category.HOME')
}
# No Agree/Disagree control or checkable preference is activated. The work-session owner closes ADB.
