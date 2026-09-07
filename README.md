# Zion OS

Zion OS is a Flutter-based Android platform for **defensive cybersecurity diagnostics, system observability, local terminal access, security assessment and incident-response workflows**.

## Release status

Current version: **4.5.0**

The repository is hardened for production-oriented verification. CI must pass analysis, tests and release APK compilation before a build is considered releasable.

## Included capabilities

- Local Android terminal with native PTY when the device runtime supports it.
- Security Core with authorization policy and audit logging.
- Runtime Integrity checks at application startup.
- Defensive network diagnostics: DNS, ping, TLS and HTTPS header inspection.
- Local network discovery with explicit runtime limitations.
- Cryptographic primitives and post-quantum primitives supplied by the project's vetted dependencies.
- Arabic and English localization.

## Safety boundary

The production application does **not** expose autonomous propagation, credential attacks, password cracking, exploitation, persistence, evasion, botnet control, rogue-AP capture or other offensive execution paths.

Security research that requires an isolated laboratory should use dedicated test infrastructure and never be enabled by the production command registry.

## Build

Requirements:

- Flutter stable compatible with the repository's CI workflow.
- Java 17.
- Android SDK/API 36.
- Android NDK version supplied by Flutter.

Commands:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

## Android

Application ID: `com.zion.os`  
Minimum SDK: 21  
Target SDK: 36  
Compile SDK: 36

The release build must be signed with a real release key before distribution. Debug credentials must never be used for a published build.

## Verification philosophy

A capability is reported as `REAL` only after its implementation succeeds at runtime. Unsupported capabilities are reported as `UNAVAILABLE`, `BLOCKED` or `RUNTIME_DEPENDENT` with a reason.

## Repository hygiene

Generated IDE state, Flutter build state, shell histories, signing keys and local environment files are intentionally excluded from source control.

## Security

See [SECURITY.md](SECURITY.md) for the security boundary and vulnerability-reporting process.
