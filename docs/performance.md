# Performance baseline and comparison protocol

Do not claim speed improvements from a smaller app list. The read-only audit captures resource snapshots; all active benchmarks remain NOT MEASURED until explicitly authorized and observed.

Use the same TV, firmware, selected picture mode, resolution/refresh, network, remote, account/profile, content title, app version and approximate room temperature. Record these conditions locally; exclude credentials. Note background updates and network variability. Establish five repetitions per interactive scenario if practical, record each measurement, report median plus min/max (or interquartile range), and disclose exclusions with a reason.

| Metric | Procedure after approval | Limitations |
| --- | --- | --- |
| Cold startup | Owner-approved power-cycle; time from power action to usable Home | Different standby/quick-start modes are distinct tests; no scripted reboot in audit |
| Warm startup | Resume from consistent standby after fixed idle interval | Not a cold boot |
| Home/remote latency | Same D-pad navigation sequence, locally timed video if approved | Human timing and camera frame rate add uncertainty |
| Netflix/Plex/Disney+/YouTube/Crunchyroll | Time deliberate launch to usable app and separately first playable content | Launch/cache/account/network state dominate; no force-stop or data clearing without approval |
| Storage/memory/processes | Repeat audit snapshots after fixed idle intervals | Free RAM alone is not performance; Android caches legitimately |
| Playback/frame drops | Same title, duration and licensed mode; app-native diagnostics where available | UI frame timing is not decoded video frame-drop proof; avoid DRM capture/bypass |
| HDR/refresh/hardware decode | Native app/TV signal info plus reported display/codec data | Advertised capability does not establish active rendering or physical panel refresh |
| Thermal | Available thermal sensor readings before/after same load interval | Missing sensors mean unavailable, not cool or safe |

Template per repetition: scenario, run number, cold/warm state, app/version, start/end definition, seconds, conditions, unavailable fields, observations. Store raw records locally. Comparison: after median minus before median and percent change relative to before; include sample count and spread. A single run is anecdotal.

Safe candidates for investigation: supported hide/recommendation options, genuinely independent optional apps, free-space recovery through supported controls, launcher trial, and vendor-supported updates. Benefits remain hypotheses until measured. Never indiscriminately disable animations, force GPU flags, change display/picture settings, governors, or clock rates. Panel refresh cannot be increased by debloating.
