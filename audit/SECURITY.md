# Security Audit

SEC-01: PARTIAL / CORRECTED. MainActivity.onNewIntent forwards ZION_API intents to ZionApiChannel, which requires the per-install token through TrustVerifier. MainActivity is the exported launcher entry point and must not require a custom signature-level activity permission, or Android launchers may be unable to start the app. The token is generated/retained in app-private storage and mirrored only for the in-app Userland dispatcher. If signature-level gating is needed in addition, move the API entry point to a dedicated exported component rather than protecting MainActivity.

SEC-02: AndroidManifest declares a broad permission surface including SMS, phone, contacts, location, camera, microphone, write-settings, boot, wake-lock, Wi-Fi and notifications. Each permission needs feature justification and least-privilege review.

Positive controls:
- usesCleartextTraffic is false.
- PTY shell selection uses an explicit allow-list.
- package external commands use a token check.
- key creation uses AndroidKeyStore.

No raw credential or API secret was identified in the directly inspected security-critical files.

No dynamic penetration test was run; the external-intent issue is source-confirmed, not a claim of exploitation.