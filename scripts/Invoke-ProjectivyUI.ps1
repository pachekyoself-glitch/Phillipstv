#requires -Version 7.0
[CmdletBinding()]
param([string]$Text,[ValidateSet('DPAD_DOWN','DPAD_UP','DPAD_LEFT','DPAD_RIGHT','DPAD_CENTER','BACK','HOME','MENU')][string]$Key,[switch]$DisableCheckableOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Text -and $Key){throw 'Choose one observed UI action.'}
if($Text -notin @('Accessibility service','Show Accessibility settings') -and $Text -match '(?i)factory|engineering|calibrat|root|uninstall|delete|purchase|premium|buy|override|accessibility'){throw 'This action is outside the reviewed launcher configuration scope.'}
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TV.WorkSession.psm1') -Force
$privateRoot=Join-Path (Split-Path -Parent $PSScriptRoot) '.local'
$connection=Get-ActiveTVWorkConnection
$adb=$connection.AdbPath
function Read-LauncherTree{
    $result=Invoke-AdbProcess $adb @('-s',$connection.Serial,'exec-out','uiautomator','dump','/dev/stdout')
    $result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'projectivy-current-ui-private.json') -Encoding utf8
    if(-not $result.Available -or $result.Output -notmatch '(?s)(<\?xml.*?</hierarchy>)'){throw 'Fresh native UI unavailable.'}
    return [xml]$Matches[1]
}
$tree=Read-LauncherTree
$nodes=@($tree.SelectNodes('//node'))
$owned=@($nodes | Where-Object {$_.GetAttribute('package') -ceq 'com.spocky.projengmenu'})
if(($Text -or ($Key -and $Key -notin @('BACK','HOME'))) -and $owned.Count -eq 0){throw 'The launcher is not the current UI; no configuration action sent.'}
$performed=$false
if($Text){
    $targets=@($owned | Where-Object {$_.GetAttribute('text') -ieq $Text -or $_.GetAttribute('content-desc') -ieq $Text})
    if($targets.Count -ne 1){throw 'The requested launcher label is not uniquely visible.'}
    $target=$targets[0]
    # Android preferences often put disabled text inside an enabled clickable row.
    # Ascend only within the same package; never tap a disabled row or other app.
    while($target.Name -eq 'node' -and $target.GetAttribute('package') -ceq 'com.spocky.projengmenu' -and ($target.GetAttribute('enabled') -ne 'true' -or $target.GetAttribute('clickable') -ne 'true')){$target=$target.ParentNode}
    if($target.Name -ne 'node' -or $target.GetAttribute('package') -cne 'com.spocky.projengmenu'){throw 'No enabled launcher row for this label.'}
    if($DisableCheckableOnly){
        $check=$target
        if($check.GetAttribute('checkable') -ne 'true'){
            $controls=@($target.SelectNodes('.//node[@checkable="true"]'))
            if($controls.Count -ne 1){throw 'No single verified checkable preference for this row.'}
            $check=$controls[0]
        }
        if($check.GetAttribute('checked') -ne 'true'){throw 'Refusing to toggle an already-unchecked control.'}
    }
    if($target.GetAttribute('bounds') -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$'){throw 'Observed launcher control bounds unavailable.'}
    $x1=[int]$Matches[1];$y1=[int]$Matches[2];$x2=[int]$Matches[3];$y2=[int]$Matches[4]
    if($x2 -le $x1 -or $y2 -le $y1 -or $x2 -gt 4096 -or $y2 -gt 4096){throw 'Invalid launcher bounds.'}
    $result=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','input','tap',([string][int](($x1+$x2)/2)),([string][int](($y1+$y2)/2)))
    if(-not $result.Available){throw 'Launcher UI input not confirmed.'};$performed=$true
}elseif($Key){
    $result=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','input','keyevent',('KEYCODE_'+$Key))
    if(-not $result.Available){throw 'Launcher navigation not confirmed.'};$performed=$true
}
if($performed){$tree=Read-LauncherTree;$nodes=@($tree.SelectNodes('//node'));$owned=@($nodes | Where-Object {$_.GetAttribute('package') -ceq 'com.spocky.projengmenu'})}
$labels=@($owned | ForEach-Object {$_.GetAttribute('text');$_.GetAttribute('content-desc')} | Where-Object {$_} | Sort-Object -Unique)
$wizard=@($labels | Where-Object {$_ -match '(?i)^(?:Next|Finish|Get started|Welcome!)$'}).Count -gt 0
$settings=@($labels | Where-Object {$_ -match '(?i)^(?:Projectivy settings|Projectivy Launcher settings|General|Appearance|Wallpaper|Settings)$'}).Count -ge 2
$safe=@($labels | Where-Object {$_ -match '(?i)^(?:Next|Back|Finish|Get started|Welcome!|Projectivy Launcher|Projectivy settings|Settings|Skip|Not now|No thanks|Cancel|OK|Deny|Don.t allow|Continue|Done|Netflix|YouTube|Plex|Disney\+|Crunchyroll|Play Store|Google Play Store|Installed apps|Favorites|Apps|General|Appearance|Wallpaper|Categories|Edit categories|Other|About|Help)$'})
$safe+=@($labels | Where-Object {$_ -match '^(?:Accessibility service|Change default launcher|Override current launcher.*|Enable channels|Programs per channel|Launcher related settings|Remote Control|Input|Power|Parental Control|About|Report.*|.*(?:usage|crash|analytics|diagnostic).*|Background|Background type|Solid color|Color|User interface|Other settings)$'})
[pscustomobject]@{ActionPerformed=$performed;LauncherUiPresent=($owned.Count -gt 0);Wizard=$wizard;SettingsMenu=$settings;Labels=$safe;CheckableControls=@($owned | Where-Object {$_.GetAttribute('checkable') -eq 'true'}).Count}
# All captured UI stays local. No privilege grant or default Home command is implemented here.
