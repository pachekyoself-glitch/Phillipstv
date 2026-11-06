# Privacy review

Inspect supported TV Settings with the owner; exact names and paths vary by retail model, firmware and region. Preserve before/after choices locally and request approval before changing any toggle or permission.

- ACR/viewing information: the supervised trial reached About → Legal information → Anoki Viewing Information Service. One visible checkbox was unchecked; no consent control was changed. Anoki's [own privacy policy](https://anoki.ai/privacy-terms/en/privacy-policy), reviewed 2026-11-04, describes the path and collection limitations. The meaning of the observed checkbox and complete traffic behavior remain unverified; no collection-free claim follows.
- Advertising ID/personalization: inspect supported advertising settings, independently of ACR. Do not read or record the actual advertising identifier.
- Usage/diagnostics, content recommendations, personalized services and optional voice assistant: review each supported toggle and its stated effect. A missing `upload_diag_enable` key supplies no conclusion.
- Microphone/location/casting: review app permissions and exposure using native controls; preserve voice remote, discovery and ordinary playback until a specific change is approved.
- Account synchronization and third-party telemetry: inspect categories with the owner without dumping account databases, addresses, authentication tokens or browsing histories.

Record each result as (1) collection disabled using a supported setting, (2) requests blocked by filtering, or (3) not verified/eliminated. DNS filtering cannot decrypt traffic or establish that collection stopped; cached addresses, encrypted DNS, shared endpoints and offline buffering limit it.

Optional DNS research: [Pi-hole](https://docs.pi-hole.net/) offers a network-level filtering approach; [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) documents a local DNS filtering server. These add a maintained device/service and can break shared streaming/update domains. No router/DNS/firewall change is proposed without a separate tested plan and approval. Never block unknown domains blindly.

No tracking-free guarantee is made. A 2024 security patch reported by the owner warrants exact-model vendor update investigation; cleanup and DNS cannot replace security patches. Do not infer support expiry or firmware compatibility from a generic build name.
