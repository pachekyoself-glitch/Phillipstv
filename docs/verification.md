# Verification checklist

All device checks begin NOT TESTED. Record actual observations and time locally. A script test is not a TV acceptance test.

## Before changes

- Authorized USB or explicitly authorized temporary LAN transport and physical device identity confirmed; no exact retail model inferred from generic properties.
- Owner confirms model/region from label or supported About screen; no identifying photograph is published.
- Full local audit completed; unavailable queries documented; no raw identifiers exported.
- Map and launch-test all six required applications through owner interaction; confirm Play Store and official publishers.
- Preserve current launcher, enabled/default package states, key settings and approved recovery actions locally. This is not a complete data backup.
- Collect comparable baseline trials only when separately authorized.

## After each approved change

- D-pad/Back/Home/volume/power, Bluetooth remote and HDMI/CEC work.
- Stock/default Home and supported Settings remain reachable.
- Netflix, YouTube, Plex, Disney+, Crunchyroll and Play Store work; representative licensed playback, audio, HDR behavior and account access match baseline.
- Wi-Fi/Ethernet, Bluetooth, casting if normally used, input switching, package installation/update mechanisms and firmware update UI remain operational.
- No new crash/reboot, unexpected background load, storage loss or thermal problem observed during a defined trial.
- On failure, stop further changes, record symptoms locally, and use only approved recovery.

## Child containment — separate release gate

Test both age modes from every child screen: Home, Back, long press, app shortcut buttons, voice search, notifications, app switching, external intents, casting, HDMI inputs, wake, reboot, Settings, developer options, app installation, adult apps, PIN lockout and parent recovery. Test USB removed/unapproved/corrupt content; reject symlinks/path traversal and oversized bundles.

If any adult app/settings/general web/install route is reachable, record FAIL and do not deploy for unsupervised use. An app PIN does not control TV Home or HDMI. Every required containment check must be performed on the actual firmware; unknown equals not approved.

## Completion

Compare repeated benchmarks and variability; retain exact change/rollback ledger locally. Stop loopback ADB server. Manually turn off USB debugging and revoke authorizations on the TV. Inspect supported network-debugging state and accessible listening services; mark unavailable checks honestly. Confirm normal TV operation after closing the audit connection.
