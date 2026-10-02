# Diagnostic Repair Plan

This document does not apply fixes.

CRITICAL
1. Resolve the external Zion API caller-authentication gap.
2. Harden PTY lifecycle and remove or implement the unused Process fallback.

HIGH
3. Replace idle PTY polling with a blocking or event-driven read path.
4. Establish one authoritative terminal UI/service ownership path.
5. Repair notes JSON persistence.

MEDIUM
6. Consolidate biometric service contracts and verify whether device credential fallback is intended.
7. Keep OTA visibly unavailable until a real signed update source exists.
8. Review native API ownership between MainActivity and ZionApiChannel.

LOW
9. Remove or redirect static terminal placeholder surfaces.
10. Review compatibility export layers and profile large desktop/terminal surfaces.

Important: this plan is based only on confirmed findings from the inspected subset. It is not a claim that the remaining uninspected files are defect-free.