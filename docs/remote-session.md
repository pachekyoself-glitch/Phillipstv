# Remote access session plan

The owner explicitly authorized **temporary LAN ADB access, read-only audit first**, on 2026-11-04. This authorizes the transport for this session; it is not blanket permission to modify packages, settings, launchers, install apps, or reset the TV. A separate LAN connection path now validates one locally confirmed private IPv4 endpoint, a short lease, device identity and secure ADB configuration. It does not pretend LAN is USB.

## Prerequisites

- Verify that the actual Philips Android TV 11 firmware exposes a supported network-debugging option or already authorized ADB interface. Do not infer phone features from the Android version. Google's [ADB guidance](https://developer.android.com/tools/adb) lists standard wireless pairing for TVs at Android 13 and later; Android TV 11 compatibility is not established.
- The owner performs initial supported on-TV setup/authorization. Automated operations begin only after the intended TV connection is authorized.
- Establish the TV endpoint locally on the PC, keep it out of the chat and Git, and verify it is the intended TV on the trusted local network. Do not scan arbitrary hosts, open router ports, expose services to the internet, or install a remote-management workaround.
- Prefer supported authenticated pairing if actually available. Legacy TCP ADB has different security properties; do not assume encrypted/authenticated transport. If the only supported path would create an unrestricted listener, stop and present the limitation.

## Scoped single-endpoint test

Host tools use the localhost ADB server. The owner-authorized connectivity test uses `adb -L tcp:localhost:5037 connect <locally confirmed TV address>:5555`, checking the conventional legacy ADB port once on that TV only. An absent network-debugging toggle or mDNS advertisement does not establish whether an existing service is reachable. No address guess, port-range/subnet scan, service enabling, `adb tcpip`, or firewall/router change is performed. A failed connection is reported as unavailable.

Run `Request-LANTVTarget.ps1` locally to enter the TV's private IPv4 address and confirm its identity. Alternatively, save it in ignored `.local/tv-address.txt` and run `Import-LANTVTarget.ps1`. The ignored `.local/lan-session.json` expires after 20 minutes. `Invoke-LANTVConnection.ps1` checks that exact endpoint; `Invoke-TVAudit.ps1 -LanSessionFile .local/lan-session.json` uses the same read-only queries and enforces session liveness. Endpoints stay local. Legacy TCP ADB is not TLS: only use the trusted local network for this brief authorized session.

With separate approval for the exact temporary screen-timeout action, `Start-TVWorkSession.ps1` retains one authorized connection for at most 20 minutes and restores the original setting at closeout. `Close-TVWorkSession.ps1` requests closure and verifies restoration; there is no command-accepting network listener. Package changes require their own exact approval and do not inherit authorization from this timeout workflow.

Timeout approval JSON must contain approved=true, the exact action TEMP_SCREEN_TIMEOUT_300000_TO_3600000_WITH_RESTORE, the selected private endpoint, consumed=false, approvedAtUtc and an expiresUtc no more than 30 minutes ahead. Keep it local. The owner consumes approval before attempting the write and holds an exclusive local owner lock. All work-session state must be beside the default .local session file. Do not run standalone connection/audit/update/power/stop workflows while an owner is active: their cleanup would interrupt restoration, so they now refuse that overlap.

Automatic restoration requires the worker, PC, network and TV to remain available. A crash can leave an outstanding ledger. Reconnect only the same explicitly authorized TV, read its current timeout, and perform only the already-approved restoration from 3600000 to 300000. Verify the readback before marking the private ledger closed. If another value is observed, stop and reconcile the owner change; never overwrite it by guesswork. A stale Active flag or unresolved restoration must not be cleared merely to bypass the start guard.

Select exactly the authorized endpoint, confirm its authorization state and Philips/Android TV identity using read-only properties, and fail if another device or changed endpoint is encountered. Record connection evidence privately; keep every audit command on the reviewed read-only allowlist. USB-only transport assertions must not be bypassed by pretending LAN is USB.

If supported access is unavailable, report that limit. The user authorization does not make an unsupported firmware capability available.

## Closure and further approvals

Disconnect the exact endpoint, stop the local ADB server used for this task, have the owner turn off the TV's supported network-debugging toggle, and revoke the relevant authorization/pairing. Verify accessible network-debugging state and record unavailable checks honestly. No persistent remote-management agent or listener is allowed.

Package/settings changes require a separate concrete review: exact action/command, pre-state, impact, reversal, test plan and explicit approval. Child content additionally requires formal institutional approval of the exact lessons and TV presentation. Publishing source does not establish device completion.
