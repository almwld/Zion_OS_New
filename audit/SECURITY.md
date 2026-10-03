# Security Audit

SEC-01: RESOLVED. MainActivity.onNewIntent forwards ZION_API intents to ZionApiChannel, which now requires the per-install token through TrustVerifier. MainActivity is also protected by a signature-level ZION_API permission. The token is generated/retained in app-private storage and mirrored only for the in-app Userland dispatcher.

SEC-02: AndroidManifest declares a broad permission surface including SMS, phone, contacts, location, camera, microphone, write-settings, boot, wake-lock, Wi-Fi and notifications. Each permission needs feature justification and least-privilege review.

Positive controls:
- usesCleartextTraffic is false.
- PTY shell selection uses an explicit allow-list.
- package external commands use a token check.
- key creation uses AndroidKeyStore.

No raw credential or API secret was identified in the directly inspected security-critical files.

No dynamic penetration test was run; the external-intent issue is source-confirmed, not a claim of exploitation.