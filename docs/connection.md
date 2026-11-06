# Authorized device connections

Use official Google Platform Tools. The installer validates archive integrity and records provenance locally. Inspect the actual device and obtain authorization before collecting data; no connection method implies permission to modify the TV.

## Temporary LAN workflow

1. Obtain explicit authorization for this TV and this local-network session. Keep the actual address out of chat, source, reports intended for sharing and GitHub searches.
2. Enter the private IPv4 address locally with `Request-LANTVTarget.ps1`, or save exactly one address in ignored `.local/tv-address.txt` and run `Import-LANTVTarget.ps1`. Confirm it identifies the TV, not another host.
3. The target file grants a short lease for the exact endpoint. The legacy connection checks port 5555 on that TV only; it never scans a subnet/port range, changes router/firewall settings, or enables a TV service.
4. Accept the trusted PC's RSA prompt on the TV. A session-only authorization may need to be accepted again after disconnect. An approved bounded work session can retain one active connection through its limited work period.
5. Verify Philips-compatible manufacturer/brand, Android TV features and secure ADB configuration before audit. A generic model string is not a retail-model identification. Standard phone wireless-pairing instructions must not be assumed to apply to Android TV 11.
6. Use `Invoke-TVAudit.ps1 -LanSessionFile .local/lan-session.json`; its command allowlist remains read-only. Private endpoint and technical data stay local. Legacy TCP ADB is not TLS; use only the authorized trusted LAN.

The host uses `-L tcp:localhost:5037` and disables mDNS auto-connect for a newly started daemon. No all-interface host listener or persistent management agent is added. If an existing ADB daemon has unknown configuration, stop it before beginning this workflow.

## Optional documented USB workflow

Only use a manufacturer-documented data/debugging connection. USB debugging enabled in Settings does not establish hardware transport support. Do not join two host ports with a passive USB-A-to-USB-A cable.

`Invoke-TVConnection.ps1` enumerates devices locally, requires explicit serial selection when more than one exists, checks `get-devpath` for USB transport, and reads limited TV identity fields. Do not share device serials. If authorization is pending, accept the trusted PC's RSA prompt on the TV; if no device is found, inspect the documented port, data-capable cable and official OEM driver support. Do not infer or force a fallback transport.

## Session closure

Close the active bounded work session through its private close-request file. Verify the original screen timeout was restored, then stop the host ADB server. Disable the relevant TV debugging control and revoke authorization when work is finished. Record unavailable exposure checks honestly; never claim complete network or child containment from one query.

Primary sources: [Google ADB guidance](https://developer.android.com/tools/adb), [official ADB manual](https://android.googlesource.com/platform/packages/modules/adb/+/HEAD/docs/user/adb.1.md), [hardware-device setup](https://developer.android.com/studio/run/device), and [OEM driver guidance](https://developer.android.com/studio/run/oem-usb).
