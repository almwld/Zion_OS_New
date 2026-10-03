# Zion OS Verification — 2026-10-03

## Security
- External `com.zion.os.ZION_API` is now protected at two layers:
  1. Android signature-level component permission.
  2. Per-install 32-byte token verified in `TrustVerifier`.
- The token is canonical in app-private SharedPreferences and mirrored to the app-private Userland token file so the in-app CLI can authenticate without exposing a credential to other apps.
- `zion-api-dispatch` now supplies the token; unauthenticated intents are rejected before API dispatch.
- Five native unit tests cover valid, wrong, missing, malformed-request-id, and malformed-method credentials.
- No AgentPolicy or secrets were changed.

## Terminal
- `TerminalService.startInteractive` uses the native PTY path only.
- The obsolete `_interactiveProcess` state is absent from the current service.
- Obsolete `MainActivity.terminalProcesses` process-backed state was removed.
- Legacy Cosmic Terminal surfaces now delegate to the canonical `TerminalScreen`.
- Idle PTY reader polling now backs off from 8ms to 500ms and resets immediately when data arrives.
- Runtime probing no longer invokes `/system/bin/sh`; Arsenal resolution is restricted to Zion Userland binaries.

## Notes
- Removed the local broken JSON codec that converted every persisted value to a string and decoded every value to `[]`.
- Notes now use `dart:convert` JSON decoding with shape validation.
- Added a widget test that restores a persisted note from SharedPreferences.

## OTA
- OTA remains explicitly unavailable until a trusted signed update source exists.
- No fake update/download/install success paths were introduced.

## AI call graph
- Native local AI: `MainActivity -> LlamaBridge -> llama_jni.cpp`.
- Dart defensive AI: `ArsenalBuiltinExecutor -> ZionAiService`.
- Neural analysis is consumed by `ProfessionalRuntimeController` and `RuntimeIntelligence`.
- Existing AI tests cover defensive analysis and guardian behavior.
- The ARM64 native engine is real; the non-ARM64 JNI stub explicitly reports unsupported status.

## Userland
- Runtime Userland is device-local; no repository bootstrap artifact is required by the current installer path.
- Local backups are fingerprinted and deduplicated.
- Only two backups are retained.
- Restore copies the known-good backup instead of consuming it, preserving a second rollback point.
- PRoot is represented by `ZionProot` and the PRoot strategy; Chroot is explicitly root-dependent.
- Package capability checks cover bash, apt, dpkg, dpkg-deb, proot, ssh, curl, wget, git and python3.
- Actual package/PRoot execution still requires a real Userland runtime on the Android device; source inspection alone is not treated as a runtime pass.

## Wi-Fi
- The active UI entry point is `ZionWifiPanel -> ZionWiFiRealPanel`.
- Android implementation is `MainActivity.scanWifiAsync -> WifiManager.startScan/scanResults`.
- Terminal Wi-Fi commands use the same `wifiScan` MethodChannel.
- Permission, Location-disabled, throttling and empty-result states are reported explicitly rather than mocked.

## Verification limits
- GitHub Actions is the authoritative build/test gate for the current repository state.
- A physical-device runtime test cannot be executed from this repository connector; therefore Userland shell, PTY, Wi-Fi hardware and APK install remain pending device validation.
