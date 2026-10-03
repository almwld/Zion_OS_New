# Confirmed Gaps — status refreshed 2026-10-03

G-01 High — **RESOLVED:** ZION_API now has a signature-level Android permission plus a per-install token checked by ZionApiChannel/TrustVerifier. Userland dispatch supplies the token.

G-02 High — **RESOLVED:** the current TerminalService uses the native PTY path only; obsolete _interactiveProcess state is absent. MainActivity process-backed terminal state was also removed.

G-03 Medium — **RESOLVED (polling mitigation):** PTY EAGAIN handling now uses exponential backoff from 8ms to 500ms and resets immediately on data. A blocking/event-driven read remains a future optimization.

G-04 Medium — **PARTIAL:** TerminalScreen is canonical. Both Cosmic Terminal compatibility surfaces delegate to it, but other legacy terminal surfaces remain and require trace before any further deprecation/removal.

G-05 Medium — **PARTIAL/CONTROLLED:** the lock screen uses core/services/biometric_service.dart. The duplicate legacy service is now a deprecated facade over the canonical service.

G-06 Medium — **INTENTIONAL / NOT A DEFECT:** OTA remains explicitly unavailable until a trusted signed update source exists. No false update/install success path is exposed.

G-07 Medium — **RESOLVED:** notes now use dart:convert JSON decoding with validation; the unconditional [] decoder was removed and a restore test was added.

G-08 — **NON-ISSUE:** the requested features/lock directory is absent; the real lock screen is screens/lock_screen.dart and is the active implementation.

These are confirmed findings from the inspected scope; they are not a claim that the remaining repository is defect-free.
