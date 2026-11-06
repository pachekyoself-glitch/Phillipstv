# Security reporting and scope

Report a suspected vulnerability through the repository's private reporting facility if enabled. If unavailable, ask the maintainer for a private channel without posting exploit details, credentials or device evidence publicly.

This is a local operator toolkit. It does not isolate code from the Windows account running it or turn a launcher into a child-security boundary. Legacy LAN ADB requires a trusted, explicitly authorized network session and is not TLS. No internet-exposed management is supported.

Review command parsing, target selection, approval/action binding, session expiry, rollback, private-data handling and publication paths. Distinguish a real attacker boundary from an operator modifying files/code they already control. Device availability, truthful acceptance reporting and privacy failures still warrant fixes even when they are not exploitable vulnerabilities.

Do not use real device identifiers or credentials in a public report. Do not connect to someone else's TV, bypass authentication, root, flash, reset, or exploit the device to demonstrate a finding. This repository does not claim universal model support or an independently certified security assessment.
