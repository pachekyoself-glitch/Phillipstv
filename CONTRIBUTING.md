# Contributing

Use Windows and PowerShell 7. Work on source in a separate checkout; keep device records in a non-synced private location. Read AGENTS.md and docs/connection.md before any TV work. A source contribution does not authorize access to a device.

Run `./scripts/Test-Project.ps1` and `Invoke-Pester ./tests -PassThru` using Pester 3.4.0. Check the returned FailedCount; do not assume PowerShell exits nonzero for a failed Pester test. Tests mock device execution and require no TV. The suite currently uses Pester 3 syntax; Pester 5 compatibility is not claimed.

Changes to mutation/recovery gates need tests for rejection, exact action/target binding and failure recovery. Keep proposals non-executable, required services protected and unknown packages unchanged. Do not generalize a device-specific executor into a bulk removal tool. Prefer on-demand collection and static launcher content over persistent agents/polling.

Document supported OS, firmware, transport and acceptance evidence without posting identifiers or raw records. A generic Philips model string is insufficient to advertise support for every Philips TV. Test a new model independently and preserve a working recovery path.

Before a release, stage only intended source, inspect the exact diff, run `Test-Project.ps1 -CheckGit`, then run `Test-PrivatePublication.ps1 -RequireActualTarget -RequirePublicMetadata` locally. Use a GitHub noreply author/committer identity. Never upload private reports to an issue or CI job. The actual-target release check requires a locally stored target and never prints it. Inspect history and all GitHub publication surfaces before changing visibility; see docs/publication.md.
