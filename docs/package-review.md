# Package review and change approval

Every observed package begins REVIEW. A package name alone is never a safe-removal finding.

| Classification | Rule |
| --- | --- |
| PROTECTED | Confirmed dependency of firmware updates, security, DRM, media, remote, inputs, networking, system UI/settings/installer, or essential vendor/Google operation |
| KEEP | Exact on-device package mapping confirmed for Netflix, YouTube, Plex, Disney+, Crunchyroll, or Play Store |
| OPTIONAL | Purpose and independence established, but retained pending an owner choice |
| REVIEW | Purpose/dependencies uncertain; leave enabled |
| CANDIDATE FOR DISABLING | Evidence supports reversible disable with bounded risk, exact rollback, and a test plan; still requires approval |

Use local TV Settings labels, official publisher listings, package metadata, exported components/shared libraries, installer source, service usage, and model-specific vendor documentation to establish purpose. Dependencies can include shared UIDs, privileged services, account/DRM integration and firmware hooks not visible in the manifest. If uncertainty remains, retain the package.

Investigate unused games/Play Games, Freeplay, promotion/recommendation components, demos, optional analytics and vendor apps. None is a predefined removal target. Favor native hide controls, then supported native uninstall for genuinely optional user apps, then reversible disable where justified. Uninstall is never covered by a disable approval.

`New-ChangeProposal.ps1` creates a local non-executable review file. Complete `config/change-template.json` separately for each candidate: exact package, pre-state, purpose, dependency evidence, privacy benefit, measured or unmeasured speed benefit, risk, exact command, reversal and verification. Rank low-risk independent user apps before system/vendor components; unresolved dependencies are high/unknown risk and remain REVIEW.

For discussion only, an eventual disable might use `adb -s <locally selected serial> shell pm disable-user --user 0 <verified package>`. Do not execute this placeholder. Reversal must restore the **actual previous enabled state**: e.g. `pm enable --user 0` for previously explicitly enabled, or `pm default-state --user 0` for a previously default state. Confirm these commands against `pm help` on the actual firmware and preserve exact metadata first. No blanket `pm enable` recovery list.

Present one small change at a time for explicit approval. Store the approval, exact command and hash of the reviewed plan, scope, time, pre-state, result and reversal locally outside Git. A future executor must refuse a changed plan, wrong device, missing/reused approval, KEEP/PROTECTED/REVIEW package, or absent state/rollback evidence. None is implemented or implicitly authorized by this project.

After each approved change, test remote, Home, Settings, all six apps with representative licensed playback, audio, HDMI/CEC, inputs, network and stability. Stop immediately on failure. Execute only an already-approved recovery; otherwise obtain approval for the exact recovery command. Do not compound failures with more debloating.
