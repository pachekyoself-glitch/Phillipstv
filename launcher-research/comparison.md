# Launcher research — reviewed 2026-11-04

This shortlist includes a supervised Projectivy trial. Projectivy was installed from its official TV Play Store listing (publisher Spocky, installer com.android.vending), served version 4.72. The separately inspected upstream 4.73 APK was not sideloaded. Store installation is provenance evidence, not independent source/security certification. Resource cost remains unmeasured.

| Candidate | Confirmed from primary source | Unresolved / trial requirements |
| --- | --- | --- |
| [Projectivy](https://github.com/spocky/miproja1) | Upstream [4.73](https://github.com/spocky/miproja1/releases/tag/4.73), published 2026-10-31, was reviewed; Play Store served 4.72 in the actual trial | Installed and launched. Native Home selection reported success but still resolved/opened stock Home. Owner separately approved Projectivy's Accessibility service and Home override; verify actual Home handling and record rollback. Avoid assuming open-source availability from the release repository. |
| [FLauncher](https://gitlab.com/flauncher/flauncher) | The [upstream README](https://gitlab.com/flauncher/flauncher/-/raw/master/README.md) describes Flutter, no ads, and limited device testing. The [license](https://gitlab.com/flauncher/flauncher/-/raw/master/LICENSE) is GPLv3 | Current release maintenance remains unverified. Upstream includes stock-launcher-disabling instructions for Chromecast; do not apply these to Philips or bypass our stock-Home recovery gate. Permissions/telemetry and real-device cost require review |
| [aLauncher](https://github.com/4v3ngR/aLauncher) | Upstream identifies a simplified FLauncher fork. Its latest-release API returned [0.0.4](https://github.com/4v3ngR/aLauncher/releases/tag/0.0.4), published 2023-01-21 | No recent release evidence from that endpoint; do not classify as currently maintained. Source commits, license, publisher, permissions and signature require independent review |

No candidate has measured RAM/startup cost or verified Philips firmware compatibility. All must support D-pad, Back/Home, remote shortcuts, HDMI/input access, retained adult apps, parent controls and recovery. Verify store provenance and known issues through publisher releases/security advisories; absence of a known advisory is not evidence of safety.

Prefer a supported native Home choice over accessibility-based Home interception. Accessibility can receive broad UI events and introduces a separate security/reliability tradeoff; request explicit approval if indispensable. Avoid overlay, notification access, device admin or other unnecessary privileges. Do not install a launcher manager or security workaround to force compatibility.

## Proposed visual direction

One dark screen with a clear six-app adult row, strong typography, generous D-pad focus outlines, static local wallpaper, visible Inputs and supervised Learning entry. Clock is optional. Put storage/network details in adult Settings; use static text refreshed on entry. No advertising, network wallpaper, continuous widgets or excessive motion. A screensaver/photo slideshow remains optional and parent configured.

Open the replacement as an ordinary app first, then test remote and input access. Preserve the stock launcher. After approval, trial native default selection and an explicitly approved reboot/recovery test. Never disable stock Home before replacement/recovery acceptance. A launcher layout or PIN does not enforce child containment.

## Additional options, ranked provisionally

| Rank | Option | Usefulness | Expected performance cost | Privacy | Compatibility / maintenance |
| --- | --- | --- | --- | --- | --- |
| 1 | Supported privacy settings review | High | Low | Can reduce selected collection | Firmware-specific; recheck after updates |
| 2 | Static six-app Home and input shortcuts | High | Low, unmeasured | Prefer offline assets | Launcher trial and remote tests required |
| 3 | Offline parent-reviewed learning plan | High | Bounded assets, unmeasured | No network/analytics by design | Highest review/containment burden; not ready for unsupervised deployment |
| 4 | Local photo screensaver | Optional | Decode/storage overhead | Personal photos remain private | Rights/privacy review, native option preferred |
| 5 | Adult-only snapshot dashboard/comparison reports | Moderate | On-demand only | Reports local | Reuses audit; no persistent agent |

All estimates are planning judgments, not benchmarks. Candidate rows do not authorize installation on another device.

## Trial permissions and privacy

The inspected upstream 4.73 manifest requested network/state, media/storage, boot, package install/delete requests, TV listings/EPG, billing, wake lock, referrer/ad identifiers/ad-services and foreground-service capabilities. The installed 4.72 package requested no additional permissions beyond that reviewed set; an exact requested list is not a granted-permission list. Do not grant storage/media, unknown-app installation, overlays or other special access just to create a Home layout. Accessibility is a separate UI-event permission, used only after explicit approval when native Home selection fails.

The [publisher privacy policy](https://spocky.github.io/apps-privacy-policy/) describes Firebase usage/crash reporting and a settings opt-out. Verify the actual opt-out state; ad-free does not mean telemetry-free. No Projectivy binaries, assets or source are redistributed by this MIT-licensed toolkit.

The supervised 4.72 trial verified anonymous usage/crash reporting and content channels unchecked after disabling them. Projectivy's approved Accessibility service was enabled through the TV's native Device Preferences → Accessibility → service entry and consent dialog; other prior enabled services were preserved. Its Home override was already checked. Home returned to Projectivy after launching each of the six retained applications. Reboot persistence, physical-remote acceptance and a full recovery exercise remain untested. To roll back the interception, turn off the Projectivy Home override and then its Accessibility service using native controls; keep the stock launcher intact throughout.
