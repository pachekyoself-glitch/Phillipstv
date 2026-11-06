# Philips-TV-Cleanup

A PowerShell toolkit for an authorized Philips Android TV audit, narrowly approved reversible changes, and private verification records. Repository: [Phillipstv](https://github.com/pachekyoself-glitch/Phillipstv).

## Current delivery

The working LAN workflow, read-only inventory, scoped update/power/privacy inspections, approval gates, rollback records, and host tests are implemented. One approved optional-app change has been verified through package and activity-launch checks. A supervised Projectivy installation and approved Accessibility Home override passed Home-return checks from all six retained activities; reporting and channels were turned off. Licensed playback, remote-wake reliability, reboot persistence and child containment still require their own acceptance evidence. See [status](docs/status.md).

The children's deliverable is a detailed implementation and formal-review plan with original-resource links. No child APK or institutionally approved lesson library is bundled. Institutional accreditation does not certify this project.

## Start in PowerShell 7

```powershell
Set-Location C:\Projects\Philipstv
# Install official Google tools only after reviewing/accepting the SDK license:
.\scripts\Install-PlatformTools.ps1 -AcceptGoogleSdkLicense
.\scripts\Test-Project.ps1
Invoke-Pester .\tests
# After explicit LAN-session authorization, enter the TV address locally:
.\scripts\Request-LANTVTarget.ps1
# Alternative: save it in ignored .local/tv-address.txt, then:
.\scripts\Import-LANTVTarget.ps1
# Read-only inventory; accept the TV's RSA prompt:
.\scripts\Invoke-TVAudit.ps1 -LanSessionFile .local/lan-session.json
```

Private target/session files expire quickly and are never published. The connection path checks only the explicitly confirmed private TV endpoint on legacy ADB port 5555, verifies TV identity and secure ADB configuration, and enables no service. This legacy transport is not TLS; use only the authorized trusted LAN session. Standard Android TV wireless-pairing support is not assumed.

PowerShell keeps the workflow inspectable; official Google ADB supplies the debugging bridge; Pester checks safety gates; Git versions source only. Tool downloads are checked against Google's published size/SHA-1 and recorded with a local SHA-256. That integrity check is not an independent publisher signature.

## Controlled operations

- `Invoke-TVAudit.ps1`: fixed read-only query allowlist; private technical report, aggregate summary and package inventory.
- `Inspect-TVUpdate.ps1`: verifies a system updater handler; opens its native page and optionally selects only a freshly observed Check for updates control. It never selects Install/Restart.
- `Inspect-TVPower.ps1`: bounded power/standby/CEC queries, with no sleep, reboot or settings writes.
- `Start-TVWorkSession.ps1`: requires approval for the exact temporary 5-to-60-minute screen timeout, verifies it, and restores the original value at local closeout or within 20 minutes. No network command listener is added.
- `Inspect-TVPrivacy.ps1`: native read-only navigation within an active work session; no consent control is activated.
- `Invoke-ApprovedGamesChange.ps1`: one-use, target-bound approval for Google Play Games only; verifies pre-state and retained-app routes, applies user-0 disable, and runs only the approved rollback on verification failure.
- `New-ChangeProposal.ps1`: non-executable local review output. Unknown packages remain REVIEW and unchanged.

These controls do not authorize arbitrary package removal, root, firmware flashing, bootloader changes, factory reset, DRM bypass, or unrestricted remote management. No Daybreak.

## Private data

Default audit output is `%TEMP%\Philips-TV-Cleanup`; for durable collection, pass `-OutputRoot` pointing to a private, non-synced directory outside the checkout. Audit collection rejects repository descendants and known sync/share paths. Session controls keep their ignored state in the checkout's `.local` directory, so use a non-synced checkout for TV work. Ignore rules do not prevent cloud synchronization. TEMP is not durable backup storage. No complete partition or private-app-data backup is claimed.

Actual IP addresses, serials, package inventories, technical dumps, approval/rollback records, captured UI, and local archives stay outside Git. `Test-PrivatePublication.ps1` compares a locally stored TV address against staged content and reachable Git blobs without printing the address. The path allowlist and `.gitignore` provide additional checks; inspect staged source before publishing.

## License and development

This toolkit's source is [MIT licensed](LICENSE). Third-party applications, Google tools, firmware and educational resources retain their own terms; see [third-party notices](THIRD-PARTY-NOTICES.md). Projectivy remains a separately installed third-party launcher. See [contributing](CONTRIBUTING.md), [security reporting](SECURITY.md), and the [whole-project audit](docs/project-audit.md) for supported scope and remaining limitations.

## Documentation

1. [Status](docs/status.md), [authorized connections](docs/connection.md), and [remote sessions](docs/remote-session.md).
2. [Audit method](docs/audit-method.md), [package review](docs/package-review.md), [privacy](docs/privacy.md), and [performance](docs/performance.md).
3. [Remote-wake investigation](docs/power-wake.md), [official updates](docs/tv-updates.md), and [launcher research](launcher-research/comparison.md).
4. [Children's material for parent review](kids-learning/PARENT-REVIEW.md), [institutional review packet](kids-learning/INSTITUTIONAL-REVIEW.md), [approval policy](kids-learning/APPROVAL.md), and [implementation plan](kids-learning/IMPLEMENTATION.md).
5. [Verification](docs/verification.md), [recovery](docs/recovery.md), and [publication](docs/publication.md).

## Closeout

Run `Close-TVWorkSession.ps1` to close an active bounded session and verify timeout restoration. Stop the host ADB server with `Stop-TVSession.ps1`. On the TV, disable debugging and revoke this PC's authorization after work. Preserve ordinary TV operation and label unverified playback, wake behavior and child containment honestly.
