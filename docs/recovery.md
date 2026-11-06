# Recovery procedures (approval required for device mutations)

Stop the change sequence on any critical failure. Keep the physical remote and a documented supported Settings/input route available before launcher trials. Preserve original package enabled/default state and exact reversal command before approving a change. No approved recovery exists merely because this document lists an example.

| Symptom | Read-only diagnosis / owner observation | Recovery proposal to approve beforehand |
| --- | --- | --- |
| Broken launcher | Does Home respond? Does Settings open through the remote? Is original HOME package present/enabled? | Restore original package state and supported default Home selection; do not disable stock Home during trials |
| Missing app | Check user-0 installed/disabled lists and exact label mapping | Restore exact prior state for a previously disabled app; official store reinstall needs separate approval and does not restore private data |
| Remote not responding | Check batteries/pairing/physical controls per exact model manual; pause ADB writes | Supported re-pairing or restoring only the approved changed dependency; no random Bluetooth service toggles |
| Streaming failure | Try other retained apps, supported network status, HDMI/audio; note DRM error locally | Revert last approved change; no DRM reset, app data clear, or account removal by default |
| Network lost | Inspect physical Ethernet, native network status and pre-state | Restore approved changed setting/service only; no router, DNS or firewall mutation by guesswork |
| Unexpected reboot | Record time and preceding action; avoid unrestricted logs | Stop changes, use exact approved rollback if accessible; vendor support if persistent |
| ADB disconnect | Revalidate the explicitly authorized transport, identity and lease; USB additionally requires get-devpath | Reconnect only the authorized device/transport. No automatic LAN fallback, scan or enabling a service. Keep timeout restoration outstanding until verified. |
| Parent PIN lost | Observe actual platform recovery route during supervised test | Parent-only supported recovery defined and tested before release; no child-reachable bypass or automatic data wipe |

If Settings/USB are inaccessible, follow exact-model manufacturer recovery/support instructions. A factory reset is a separate destructive request requiring separate approval; do not present it as the next automatic step. No root, flash, bootloader, system partition or security-control workaround is allowed.
