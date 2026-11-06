# Project status — 2026-11-05

## Implemented and observed

- Authorized temporary LAN ADB access is working, with explicit target selection, TV identity checks and secure ADB configuration verification.
- The full read-only inventory was collected privately. Required apps are retained; unknown packages remain unchanged. Raw findings, addresses and device-specific reports are excluded from Git.
- The official system updater was verified, opened and checked. The refreshed screen reports up to date; no update was offered, downloaded or installed.
- The approved Google Play Games user-0 disable was applied and verified. All six retained app activities launched successfully. APK/data were preserved; licensed playback is not yet verified.
- The approved temporary 5-to-60-minute screen timeout was applied for a bounded work session. The original 5-minute value was restored and verified at closeout.
- Power/standby and supported vendor privacy pages were inspected. No power, CEC or vendor consent setting was changed.
- Projectivy 4.72 was installed from Google Play and launched. Native default-Home selection reported success but still resolved/opened stock Home on the trial firmware. The separately approved Accessibility service and existing checked Home override now handle Home: all six retained activities launched and Home returned to Projectivy from each. Stock Home remains installed. This is an Accessibility-based override, not a verified replacement of the firmware's native Home role.
- Projectivy anonymous usage reporting, anonymous crash reporting and content channels were switched off through supported controls and their unchecked states verified. No complete traffic-free claim is made.
- Final TV closeout verified the five-minute timeout and stopped the host ADB server. No further TV access is needed for source publication.
- Whole-project review added target-bound one-use timeout approvals, atomic state writes, exclusive owner locking, overlap protection, stricter release checks, an MIT license and third-party/contributor guidance. Host tests pass; actual performance gains are not established by those tests.

## Open acceptance gates

| Area | Current state | Required evidence |
| --- | --- | --- |
| Remote wake | Unresolved; physical TV button and awake remote operation work | A controlled later wake verification and supported remote/firmware diagnosis |
| Streaming | Required app activity launches passed | Actual licensed playback, audio/input and normal remote-use verification |
| Firmware | Native check reports up to date | No release-specific installation is available to approve; do not infer a manual firmware image from a generic model |
| Privacy | Native Anoki page inspected; its visible checkbox was unchecked | Supported-setting semantics and further privacy review; no tracking-free claim |
| Launcher | Projectivy installed; approved Accessibility Home override passed from all six retained activities | Physical remote, reboot/wake persistence and recovery acceptance; static wallpaper/six-app layout personalization remain separate |
| Child learning | Implementation/review plan only; no deployment | Formal institutional approval of exact lessons and presentation, rights, parent review and tested containment |
| Performance | Resource snapshot and launch observations collected | Comparable repeated trials before claiming measured speed improvement |

## Delivery and data handling

Source includes guarded audit/inspection workflows, narrowly scoped approvals, rollback procedures, private-publication checks, documentation and tests. Device-specific evidence and the superseded setup notes are retained locally. The public project describes the maintained workflow and current acceptance state.

The TV reports generic model fields. No exact retail model, complete backup, wake repair, measured speedup, current security support, or unsupervised child safety is inferred.
