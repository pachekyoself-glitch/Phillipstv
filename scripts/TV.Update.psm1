#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Get-VerifiedUpdateCheckTap {
    param([Parameter(Mandatory)][xml]$Tree,[Parameter(Mandatory)][string]$SystemPackage)
    $buttons=@($Tree.SelectNodes('//node') | Where-Object {$_.GetAttribute('text') -match '(?i)^check (?:now|for updates?)$' -and $_.GetAttribute('enabled') -eq 'true' -and $_.GetAttribute('package') -ceq $SystemPackage})
    if ($buttons.Count -ne 1) {throw 'A unique enabled Check for updates control owned by the verified system updater was not found. No input sent.'}
    if ($buttons[0].GetAttribute('bounds') -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {throw 'Update-check control bounds unavailable. No input sent.'}
    $x1=[int]$Matches[1];$y1=[int]$Matches[2];$x2=[int]$Matches[3];$y2=[int]$Matches[4]
    if ($x2 -le $x1 -or $y2 -le $y1 -or $x2 -gt 4096 -or $y2 -gt 4096) {throw 'Unexpected update-check control bounds. No input sent.'}
    [pscustomobject]@{X=[int](($x1+$x2)/2);Y=[int](($y1+$y2)/2)}
}
Export-ModuleMember -Function Get-VerifiedUpdateCheckTap
