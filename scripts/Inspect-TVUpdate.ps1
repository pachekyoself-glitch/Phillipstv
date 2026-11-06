#requires -Version 7.0
[CmdletBinding()]
param([string]$SessionFile=(Join-Path (Split-Path -Parent $PSScriptRoot) '.local/lan-session.json'),[switch]$OpenUpdater,[switch]$CheckForUpdates)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TV.Common.psm1') -Force
Assert-NoTVWorkSession
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TV.Update.psm1') -Force
$adb = Resolve-Adb
$connection = $null
try {
    $connection = Get-LANTVConnection -SessionFile $SessionFile -AdbPath $adb -AuthorizationWaitSeconds 90
    $privateRoot = Split-Path -Parent $SessionFile
    $helpResult = Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','pm','help')
    $helpResult | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'pm-help-private.json') -Encoding utf8
    $resolve = Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','cmd','package','resolve-activity','--brief','--user','0','-a','android.settings.SYSTEM_UPDATE_SETTINGS')
    $resolve | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'update-resolution-private.json') -Encoding utf8
    $components = @($resolve.Output -split '\r?\n' | Where-Object {$_ -cmatch '^[A-Za-z][A-Za-z0-9_.]+/[A-Za-z0-9_.$]+$'})
    $summary = [ordered]@{UpdaterResolved=$false;VerifiedSystemHandler=$false;UpdaterScreenOpened=$false;UiReadAvailable=$false;UpdateCheckActionSent=$false;FreshScreenReadAfterCheck=$false;UpToDateMessageObserved=$false;UpdateAvailableMessageObserved=$false;AutomaticDownloadMessageObserved=$false;FirmwareLabels=@();InstallationRequested=$false;PackageManagerDefaultStateSupported=($helpResult.Output -match '(?m)^\s*default-state\s')}
    if (-not $resolve.Available -or $components.Count -ne 1) {
        $summary | ConvertTo-Json -Depth 5
        return
    }
    $summary.UpdaterResolved=$true
    $component=$components[0]
    $package=$component.Split('/')[0]
    $detail=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','dumpsys','package',$package)
    $detail | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'update-handler-private.json') -Encoding utf8
    if (-not $detail.Available -or $detail.Output -notmatch '(?m)^\s*pkgFlags=\[.*\bSYSTEM\b') { throw 'Update intent did not resolve to a verified system package. No UI was launched.' }
    $summary.VerifiedSystemHandler=$true
    if ($OpenUpdater -or $CheckForUpdates) {
        Assert-LANTVSession $connection
        # Explicit verified system component prevents third-party implicit-intent interception.
        # Default: open only. The explicit CheckForUpdates option can press Check;
        # Download/Install/Restart controls are never selected by this script.
        $launch=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','am','start','-W','-n',$component,'-a','android.settings.SYSTEM_UPDATE_SETTINGS')
        $launch | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'update-screen-launch-private.json') -Encoding utf8
        if (-not $launch.Available) { throw 'The supported updater screen could not be opened. No installation was requested.' }
        $summary.UpdaterScreenOpened=$true
        $ui=Invoke-AdbProcess $adb @('-s',$connection.Serial,'exec-out','uiautomator','dump','/dev/stdout') -TimeoutSeconds 20
        $ui | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'update-ui-private.json') -Encoding utf8
        if ($ui.Available -and $ui.Output -match '(?s)(<\?xml.*?</hierarchy>)') {
            [xml]$tree=$Matches[1]
            $texts=@($tree.SelectNodes('//node') | ForEach-Object {$_.GetAttribute('text')})
            $summary.UiReadAvailable=$true
            $summary.UpToDateMessageObserved=@($texts | Where-Object {$_ -match '(?i)up.to.date|already.*latest|latest.*installed'}).Count -gt 0
            $summary.UpdateAvailableMessageObserved=@($texts | Where-Object {$_ -match '(?i)(?:software |system )?update (?:is )?available|new (?:software |system )?version available'}).Count -gt 0
            $summary.FirmwareLabels=@($texts | ForEach-Object {[regex]::Matches($_,'\b(?:PHL-[A-Za-z0-9_.-]+|RTXC\.[A-Za-z0-9_.-]+)\b')} | ForEach-Object {$_.Value} | Sort-Object -Unique)
            if ($CheckForUpdates) {
                $point=Get-VerifiedUpdateCheckTap -Tree $tree -SystemPackage $package
                $x=[string]$point.X;$y=[string]$point.Y
                Assert-LANTVSession $connection
                # Exactly the freshly observed Check control; never Download/Install/Restart.
                $tap=Invoke-AdbProcess $adb @('-s',$connection.Serial,'shell','input','tap',$x,$y)
                if (-not $tap.Available) {throw 'Update-check input could not be confirmed.'}
                $summary.UpdateCheckActionSent=$true
                Start-Sleep -Seconds 4
                $after=Invoke-AdbProcess $adb @('-s',$connection.Serial,'exec-out','uiautomator','dump','/dev/stdout') -TimeoutSeconds 20
                $after | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'update-after-check-ui-private.json') -Encoding utf8
                if ($after.Available -and $after.Output -match '(?s)(<\?xml.*?</hierarchy>)') {
                    [xml]$afterTree=$Matches[1]
                    $afterTexts=@($afterTree.SelectNodes('//node') | ForEach-Object {$_.GetAttribute('text')})
                    $summary.FreshScreenReadAfterCheck=$true
                    $summary.UpToDateMessageObserved=@($afterTexts | Where-Object {$_ -match '(?i)up.to.date|already.*latest|latest.*installed'}).Count -gt 0
                    $summary.UpdateAvailableMessageObserved=@($afterTexts | Where-Object {$_ -match '(?i)(?:software |system )?update (?:is )?available|new (?:software |system )?version available'}).Count -gt 0
                    $summary.AutomaticDownloadMessageObserved=@($afterTexts | Where-Object {$_ -match '(?i)downloading|download in progress'}).Count -gt 0
                    $summary.FirmwareLabels=@($afterTexts | ForEach-Object {[regex]::Matches($_,'\b(?:PHL-[A-Za-z0-9_.-]+|RTXC\.[A-Za-z0-9_.-]+)\b')} | ForEach-Object {$_.Value} | Sort-Object -Unique)
                }
            }
        }
        elseif ($CheckForUpdates) {throw 'Cannot inspect updater controls; no Check/Download/Install action sent.'}
    }
    $summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $privateRoot 'update-summary-private.json') -Encoding utf8
    $summary | ConvertTo-Json -Depth 5
} finally {
    if ($connection) {$null=Invoke-AdbProcess $adb @('disconnect',$connection.Serial)}
    $null=Invoke-AdbProcess $adb @('kill-server')
}
