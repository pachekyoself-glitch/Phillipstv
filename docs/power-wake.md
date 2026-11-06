# Remote wake failure investigation

Power/wake reliability takes priority over debloating and launcher changes. The owner reports daily unplug/reconnect as a workaround, has already tried reset procedures, says the TV's physical power button works during the failure, and reports normal remote navigation/volume/power-off after the TV is on. The standby LED observation is uncertain.

That pattern narrows investigation toward remote wake signaling and standby handling. It does not prove which component is defective, identify the remote's IR/Bluetooth behavior, or rule out a firmware/receiver fault. Use the working physical power button as the interim alternative to daily mains cycling; do not repeat factory resets.

## Read-only evidence

`Inspect-TVPower.ps1` reads a bounded set of power-service fields, boot reasons, uptime and standard CEC/power/timeout settings. Full service output remains in the ignored local folder. Missing/null settings are unavailable, not disabled. The script never sends power/sleep/reboot key events, clears logs, changes a setting, resets pairings, or disables a remote/input service.

A snapshot while the TV is working is not a record of the failed wake. It cannot prove a repair or diagnose a board/receiver fault. No standby reproduction or overnight test has been performed by the toolkit.

## Next tests, in order

1. The owner confirms the original Philips remote, a short Power press, and unsuccessful fresh-battery/direct close-range checks. Do not repeat those basic questions or prescribe another factory reset. Identify the remote model only if a specific supported procedure or part depends on it.
2. If the power function uses IR, perform the manufacturer's IR-emission test with a camera known to see IR. A visible flash shows emission, not correct coding or receiver operation; an invisible flash is inconclusive with an IR-filtering camera. A functioning Bluetooth navigation path does not by itself establish the remote's standby-wake path.
3. After approval, perform one controlled, short standby/wake comparison with the physical TV button available. Record remote result, physical-button result, delay and LED behavior. Do not promise that an immediate successful cycle reproduces or resolves an overnight failure.
4. Accessory isolation is a later controlled test only if evidence supports it. The collected CEC enable/automatic-off/automatic-wake settings are already zero; do not propose disabling them as an untested fix.
5. Inspect supported native Quick Start/low-power standby/HDMI-CEC controls. Propose a reversible change only after seeing the actual option, preserving its previous value and explaining energy/behavior tradeoffs. Never write guessed vendor settings or keep the CPU permanently awake as a workaround.

If IR emission/receiver response and a supported software path cannot explain or resolve the failure, use manufacturer support with the observed model/build and symptom history. Do not diagnose a power-supply replacement from this evidence or recommend buying an unverified replacement remote.

## Update status

The verified system updater was opened, its enabled Check for updates control was selected, and a fresh UI read continued to display an up-to-date message. No update-available or automatic-download message was observed, no Install/Restart control was selected, and no firmware installation started. This is the observed provider UI result, not proof of current security support. Exact-model official release research remains limited by the generic model property.

## Primary guidance

- [Philips US: TV will not turn on](https://www.usa.philips.com/c-t/XC000011336/what-should-i-do-if-my-philips-tv-does-not-turn-on) distinguishes physical-button operation from remote failure and discusses batteries, pointing and light interference.
- [Philips: infrared remote troubleshooting](https://www.philips.co.uk/c-f/XC000014135/what-to-do-when-the-tv-does-not-respond-to-the-infrared-remote-control) describes the physical-button check and camera test. Model/remote applicability must be confirmed; do not repeat its reset step when already exhausted.
- [Philips remote instructions](https://www.philips.com/c-dam/b2c/support-home-generic/remote-control-instructions-2020.pdf) document multiple remote families, including mixed Bluetooth/IR designs. This does not identify the owner's remote.

Sources checked 2026-11-04. The wake problem remains unresolved until a controlled verification demonstrates otherwise.
