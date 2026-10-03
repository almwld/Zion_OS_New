# Diagnostic Repair Plan — status refreshed 2026-10-03

COMPLETED
1. External Zion API caller authentication.
2. Obsolete Process-backed terminal fallback state.
3. Idle PTY polling mitigation.
4. Notes JSON persistence.
5. Cosmic Terminal compatibility surfaces now route to the canonical PTY terminal.
6. Legacy notification and biometric facades are deprecated and routed to canonical services.

REMAINING
7. Complete terminal UI ownership trace for the remaining legacy terminal surfaces.
8. Run physical-device Userland/PTY/Wi-Fi integration tests.
9. Review OTA once a trusted signed update source is available.
10. Continue AI call-graph and security-layer verification without deleting code on naming alone.

IMPORTANT
- CI must remain green on the latest HEAD before the release-quality gate is considered complete.
- Device-only capabilities are not marked passed from source inspection alone.
