# Whole-project audit — 2026-11-05

Scope: all current project scripts, configuration, tests, documentation and planning files; independent static security/architecture review; local publication-history review; and a separate supervised TV launcher trial. This is an engineering review, not institutional certification. Vendor firmware and the proprietary launcher implementation are outside source scope.

## Findings and changes

| Priority | Blind spot | Resolution / limit |
| --- | --- | --- |
| High | Launcher installation/default selection was mistaken for effective Home handling | Test the actual Home key from another app, separately from native resolver output. Native selection reported success but still resolved to stock on the trial firmware. Preserve stock; treat an approved Accessibility override as a distinct mechanism. See launcher research and status. |
| High | Timeout approval was not bound to a target or one use | Exact endpoint/action, boolean unused state and bounded expiry are now required; consume before writing. |
| High | An attempted but unverified timeout write could escape the outstanding-restore guard | Any RestoreRequired ledger blocks another session, regardless of Applied. Persist intent before writing; report failure as unresolved recovery. A host crash/power loss can still prevent finally from running. |
| Medium | Custom session-file parents diverged from fixed consumers | Bounded work sessions now require the canonical project .local parent. Separate one-device checkouts remain the isolation unit. |
| Medium | Readers could see partial session JSON, stale Active=true, or concurrent owners | Same-directory atomic state replacement, exclusive owner lock, deadline checks and transport lease. Standalone workflows refuse to interrupt an active owner or unresolved restoration. |
| High | Publication check could skip actual-address comparison silently | Release uses -RequireActualTarget, which fails if no private target is available. Exact comparison now includes reachable commit/tag text as well as blobs. This does not replace secret/personal-data review. |
| Medium | Documentation claimed no launcher install and no confirmed Anoki path | Update claims to observed state, installed store version and remaining acceptance gaps. |
| High | No project license or dependency distribution boundary | MIT license for project-owned source; third-party terms remain separate. No launcher APK, Google tools, firmware or lesson assets redistributed. |
| Medium | README recommended an audit path rejected by the collector | Document durable OutputRoot outside the checkout. Use a non-synced checkout for private session files; gitignore is not sync isolation. |
| Medium | Portability and scaling could be inferred from a generic model | Windows/PowerShell 7, single selected TV, explicit per-device evidence. No fleet support or blanket Philips compatibility claim. |

No attacker-reachable vulnerability or embedded credential was established in the initial independent 53-file static pass. Reliability and privacy-release gaps still require fixes. That pass predates these fixes; run project/regression checks and review the final diff as well. Absence of a finding is not proof of security.

## Reliability and performance

Use static launcher content, disable unused channels through supported settings, avoid broad special permissions, keep unknown dependencies enabled and avoid persistent agents/polling. Do not equate free RAM or fewer visible apps with measured speed. Establish comparable repeated timings before claiming improvements; docs/performance.md defines the protocol.

The original wake problem, licensed streaming playback, physical-remote checks and reboot persistence need actual device evidence. A launcher override can change Home navigation without fixing standby or firmware behavior. The native updater offered no firmware update in the previous check.

## Scalability

Keep one active bounded owner per non-synced device checkout. A custom shared state folder and concurrent sessions are unsupported. The same target must be revalidated at each session; a saved address can change through DHCP. No address/port scanning or automatic target substitution is supported.

Before extending to another TV, confirm identity/firmware/transport, map required apps using publisher evidence, test the supported Home mechanism and preserve recovery. Device-specific measurements remain private. Source extensions require rejection/recovery tests; executor commands stay fixed and proposals remain non-executable. Avoid bulk debloat lists or unsupported firmware images.

## Release gate

Run host checks, review exact staged source and reachable history, compare the real private target locally, verify licensing and dependency notices, and inspect GitHub branches/tags, issues/PRs, workflow logs/artifacts, releases and wiki/discussions where enabled. Unverified surfaces must be disclosed. Change public visibility only after the release review. No raw device records or the private checkpoint belong in the public tree.

The family-content gate remains separate: no child app/library, no exact-item institutional approval and no verified containment. The public toolkit can ship with the blocked implementation plan; it must not advertise an approved child experience.

The pre-release GitHub surface audit found one branch, no tags/issues/PRs/workflow runs/artifacts/releases/forks, and wiki/discussions/Pages disabled. All 60 reachable original blobs were checked locally for the actual target; no match was found. Credential/personal-Windows-path patterns also produced no match. Historical author metadata contained a non-noreply email, so the owner directed that the repository remain private until it is removed. Do not equate a clean current tree with safe historical metadata or publish the original history unchanged.
