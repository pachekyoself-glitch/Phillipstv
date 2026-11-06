#requires -Version 7.0
# This interactive Windows dialog is for local target entry only. It opens no TV connection.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'LAN.Common.psm1') -Force
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$privateRoot = Join-Path (Split-Path -Parent $PSScriptRoot) '.local'
New-Item -ItemType Directory -Path $privateRoot -Force | Out-Null
$form = [Windows.Forms.Form]::new()
$form.Text = 'Philips TV — local IP entry'
$form.ClientSize = [Drawing.Size]::new(540,235)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$label = [Windows.Forms.Label]::new()
$label.SetBounds(18,15,505,92)
$label.Text = "On the TV, open Settings > Network / Ethernet (or Wi-Fi) and find its IP address.`r`nEnter that TV address here, not in the chat. This stays in an ignored local file.`r`nOnly one confirmed private IPv4 endpoint on legacy ADB port 5555 will be tried. No TV settings or services will be changed."
$form.Controls.Add($label)
$addressBox = [Windows.Forms.TextBox]::new()
$addressBox.SetBounds(18,111,290,28)
$form.Controls.Add($addressBox)
$confirm = [Windows.Forms.CheckBox]::new()
$confirm.SetBounds(18,147,505,25)
$confirm.Text = 'This address is my Philips TV, not another device.'
$form.Controls.Add($confirm)
$button = [Windows.Forms.Button]::new()
$button.Text = 'Save TV target locally'
$button.SetBounds(18,185,200,32)
$button.Add_Click({
    try {
        $address = $addressBox.Text.Trim()
        Assert-PrivateTVAddress $address
        if (-not $confirm.Checked) { throw 'Confirm that this is the TV address.' }
        @{schemaVersion=1;address=$address;port=5555;ownerConfirmedTV=$true;readOnlyAudit=$true;expiresUtc=[DateTimeOffset]::UtcNow.AddMinutes(20).ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $privateRoot 'lan-session.json') -Encoding utf8
        $form.DialogResult = [Windows.Forms.DialogResult]::OK
        $form.Close()
    } catch { $null = [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Check TV target') }
})
$form.Controls.Add($button)
$form.AcceptButton = $button
$null = $form.ShowDialog()
$form.Dispose()
