# Security Audit

SEC-01: MainActivity.onNewIntent calls handleZionApiIntent. That method checks the action and forwards the intent to ZionApiChannel.handleExternalIntent. The inspected path does not perform the token verification used by the separate package bridge. The API channel exposes operations including messaging, calls, contacts, camera, storage, notifications and keystore access. This is a critical review item.

SEC-02: AndroidManifest declares a broad permission surface including SMS, phone, contacts, location, camera, microphone, write-settings, boot, wake-lock, Wi-Fi and notifications. Each permission needs feature justification and least-privilege review.

Positive controls:
- usesCleartextTraffic is false.
- PTY shell selection uses an explicit allow-list.
- package external commands use a token check.
- key creation uses AndroidKeyStore.

No raw credential or API secret was identified in the directly inspected security-critical files.

No dynamic penetration test was run; the external-intent issue is source-confirmed, not a claim of exploitation.