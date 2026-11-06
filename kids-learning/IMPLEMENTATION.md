# Offline learning environment — implementation-ready plan

No app is deployed. A complete safe implementation is not yet feasible without exact-item educational approval, rights and firmware containment testing; this detailed plan is the master task's permitted alternative. A supervised educational app may be viable even when unsupervised containment fails, but must be labeled accordingly and separately approved.

## Product and content scope

Two parent-selected modes for ages 3 and 6. Age 3 categories: letters, numbers, colors, shapes, animals and basic vocabulary. Age 6: reading, phonics, mathematics, science, nature, geography and simple educational activities. Every category begins empty until qualifying items exist. Do not generate lessons as a substitute for external approval.

Child entry shows large age-appropriate tiles with clear icons and optional approved local narration. D-pad moves predictably in a grid; focus outline and size/contrast changes are visible at TV distance. Center selects; Back returns within the app; a visible exit follows the tested parent path. Avoid time pressure, streaks, autoplay and attention traps. A parent controls session duration and supervised breaks. Test text scale, color contrast, hearing/visual needs and actual viewing distance with the family.

Local search is optional and only indexes approved item titles/tags for the selected age mode. Prefer categories and simple letters rather than forcing young children through a keyboard. No general search, browser, WebView, hyperlinks, feeds, social, chat, AI answers, advertising, purchase, analytics or cloud account.

## Native Android TV implementation

Use Kotlin and a single-purpose Android app compatible with API 30, following Google's [TV app manifest/launch guidance](https://developer.android.com/training/tv/get-started/create). Set a Leanback launcher entry, require leanback where appropriate and mark touchscreen optional. Choose the current supported target SDK at build time; Android TV 11 compatibility is a minimum-runtime question, not a reason to target an obsolete SDK.

Use native focusable views or supported Compose for TV components after measuring on the actual hardware. Avoid an embedded website. Explicitly specify next-focus behavior for grid edges and dialog controls; test every screen with D-pad only. Add accessible labels and no focus traps. Use platform media APIs with a tightly bounded local asset set; no third-party advertising/analytics SDKs.

Manifest: no INTERNET, microphone, location, contacts, camera, overlay, accessibility service, notification listener, device-admin or install-packages permissions. Internal activities/services/providers are non-exported. Only the launcher activity is exported as required; it ignores untrusted incoming data and does not open generic VIEW intents. Disable backup for sensitive settings and exclude content approvals/keys from backup. Inspect merged manifest and dependencies before each release. No dynamic code, WebView, external URLs or implicit browser intents.

## Suggested modules and interfaces

| Module | Responsibilities | Security boundary |
| --- | --- | --- |
| `ui-child` | Age-mode grid, approved player, local-only search | Receives read-only approved content view; cannot import, alter approvals or launch external intents |
| `content-domain` | Item schema, age/objective policy, approval state machine | Any missing approval/hash/version fails closed |
| `content-storage` | App-private catalog and files, atomic activation | Child UID reads active library; no arbitrary file paths exposed |
| `import-parent` | Parent-authorized Storage Access Framework USB selection | Validate quarantine before activation; no broad external-storage permission |
| `parent-settings` | Session settings, review status, revoke/delete, PIN and recovery | Explicit reauthentication; never infer system-level containment |
| `verification` | Manifest/dependency checks, content validator, device acceptance matrix | Reports unknown/fail accurately; cannot approve its own content |

Content state machine: QUARANTINED → SOURCE_APPROVED → RIGHTS_CLEARED → PARENT_APPROVED → VALIDATED → ACTIVE. Any byte/version/age/rights change returns to quarantine. Revocation removes an item from search and playback immediately; never silently keep a stale cached lesson active.

Implement `ApprovedCatalog.list(ageMode)`, `ApprovedCatalog.search(ageMode, query)`, `ImportValidator.validate(bundle)`, `ApprovalVerifier.verify(manifest, parentKey)` and `ContentPlayer.open(approvedItemId)` as small interfaces. The player accepts an internal opaque ID, not a filesystem path/URL or external Intent URI. Repository interfaces must enforce approval independently of UI visibility.

## Parent-controlled USB import

Perform source review and complete `content-item.template.json` on the parent PC. Obtain exact-item institutional approval and usage rights first. Generate a signed manifest for the final bytes using a parent-controlled private key kept off the TV. Enroll the public key through a supervised parent setup step; a signature from a newly supplied bundle must never enroll its own key.

The app's parent-authenticated USB picker grants access only to the selected bundle using the Storage Access Framework. Reject HTML, scripts, APKs, archives-within-archives, external URI references, symlinks, absolute/traversal paths, duplicate filenames/IDs and unknown media types. Bound item count, total bytes, individual bytes, decoded pixel dimensions and media duration according to measured device resources. Stream validation to avoid memory exhaustion; do not trust filename extensions.

Verify signature, hashes, age band, approval evidence fields and rights state before copying to app-private quarantine. Parent previews the exact imported files, then activates an atomic approved catalog. Corrupt/missing/unapproved items show no child tile. Removing USB does not invalidate already approved internal copies; imports are opt-in and no USB autorun exists. Provide parent-only revoke/delete and storage usage.

## Parent PIN and recovery

A local app PIN protects parent UI only. Use salted slow hashing suitable for the measured device, rate limiting/backoff persisted across process restart, no plaintext logging, no hardcoded/default bypass, and no child-readable recovery secret. Define a parent-only recovery code generated on setup and stored by the parent off-TV. Test interrupted recovery and persistence. Do not claim encrypted preferences alone prevent privileged system access.

Do not override or pretend to block Home using ordinary app code. Android's [lock task documentation](https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode) distinguishes managed allowlisting from escapable screen pinning. Device-owner/profile/lock-task behavior on this firmware remains unknown. Do not provision a DPC, factory reset, elevate privileges or intercept Home with an accessibility workaround. Verify native restricted-profile options via supported Settings first, with separate approval for creating/changing profiles.

## Test plan and release gates

Host tests: reject missing/false educational/rights/parent approvals, source mismatch, age mismatch, altered hash/signature, unknown source key, unsigned bundle, duplicate/traversal filenames, decompression bombs, oversized images/media and arbitrary external intents. Verify empty/partial catalogs never expose drafts. Search tests must prove absence of any non-approved IDs, including after revocation and age switching.

Emulator tests: every focus route and Back behavior, accessibility labels, no network permission/dependency, activity recreation, crash during import, low-memory recovery, PIN rate limit across restart, corrupted storage and revoked items during playback.

Device tests: follow every containment check in `docs/verification.md`: Home/Back, shortcut buttons, voice, notification/app switch, external intents, casting, HDMI, wake/reboot, Settings/developer options, installations, adult apps and parent recovery. Confirm supported profile/management behavior without inventing phone feature compatibility. Measure startup, idle RAM, playback response, storage and thermal state on actual hardware.

Gate 1: source/rights/parent approvals for final bytes. Gate 2: build/manifest and host/emulator checks pass. Gate 3: owner approves APK origin/permissions, exact install command and supported uninstall/recovery. Gate 4: supervised device acceptance. Gate 5: all required containment tests pass before any unsupervised-use claim; if adult/system access remains, mark FAIL and retain supervised-only status. No child should be used as the containment tester.

Rollout starts with a tiny reviewed library and a supervised trial. Add subjects incrementally only with separate item approvals. Updates preserve the strict allowlist, carry migration tests, and are parent-triggered from a verified publisher/build. No self-updater or persistent management listener.
