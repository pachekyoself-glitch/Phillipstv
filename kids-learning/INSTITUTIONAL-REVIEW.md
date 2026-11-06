# Formal institutional review packet

**Status: preparation checklist; no request has been sent, no reviewer is engaged, and no approval has been received.** The owner requires formal approval of the exact lessons and their TV presentation. This requirement was explicitly confirmed on 2026-11-04.

## Required submission artifacts

1. Identity of the reviewing accredited institution, current accreditation evidence, authorized reviewer and scope of authority. A developer or parent cannot sign for the institution.
2. Final proposed content manifest, with exact item IDs, titles, objectives, age modes, publisher/author, complete text/narration/assets, rights evidence and SHA-256 hashes.
3. Final review build, source revision, APK SHA-256, merged manifest/permission report, and dependency inventory. A plan alone does not define the exact TV presentation.
4. Screenshots or recordings of every final child-facing screen and answer/feedback state, D-pad focus map, parent entry/exit, empty-library/error cases and accessibility behavior. Use synthetic content/account data in captures; no private device identifiers.
5. A repeatable review script for ages three and six, with prerequisites, expected learning outcomes, adult involvement and known limitations.
6. Actual device containment findings, including every bypass test in `docs/verification.md`. Mark untested checks untested. Educational approval does not establish device security or permit an unsupervised-safety claim.
7. Itemized decision form recording approve/reject/revise, age/format/use scope, reviewer authority, institution, date, conditions, expiration if any, and exact approved content/build hashes. Keep signed evidence private.

## Draft request text — not sent

> We request formal educational review of the attached, versioned offline Android TV lessons for children aged three and six, including their exact on-screen presentation and remote-control interactions. Please confirm whether your institution can provide this review and who is authorized to issue an institutional decision. We are requesting an itemized written decision tied to the supplied content and build hashes, rather than a general endorsement based on citations. Please identify required revisions, permitted age groups and uses, review conditions, and any limitations. Any permissions to reproduce or adapt your materials must be documented separately. We will not claim approval before receiving and verifying your written decision.

Do not send this draft until the artifact list is complete and the owner explicitly authorizes the recipient and submission. Do not send device inventories, serial numbers, network endpoints, private logs, child identities, or account information. Do not suggest institutional affiliation or endorsement without evidence.

## Release decision

Keep educational approval, copyright/use rights, parent review, technical validation, and device containment as independent gates. An institutional decision for one lesson or build does not approve the whole library or later revisions. The app must fail closed on missing, changed, rejected or out-of-scope items.
