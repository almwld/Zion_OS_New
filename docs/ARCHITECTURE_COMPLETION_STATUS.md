# Zion OS — Integrated Architecture Status

This document describes the production architecture. Code presence is not treated as proof of runtime capability.

## Application core

- `lib/main.dart` is the application entry point.
- `provider` is the single application state/dependency-injection framework.
- `SecurityCore` is created at startup and supplied through Provider.
- `RuntimeIntegrity` performs deterministic startup checks and records the result in the audit log.
- The application starts at the Lock Screen.

## Terminal

- `lib/features/terminal/terminal_service.dart` owns terminal history, authorization, audit events and process lifecycle.
- `NativePtyAdapter` is the Android PTY bridge.
- PTY availability is runtime-dependent. Unsupported devices report `UNAVAILABLE`; success is never simulated.
- PTY source uses the Android native layer and must be validated on a real Android device.

## Network

- Production network features are defensive diagnostics and local-network discovery.
- DNS uses OS resolution through `InternetAddress.lookup`.
- Ping is attempted only when the runtime provides the binary.
- HTTPS header inspection requires an `https://` URL.
- TLS validation uses `SecureSocket`.
- The network map no longer fabricates MAC addresses, hostnames or OS fingerprints.

## Security boundary

The production registry intentionally contains defensive modules only. Autonomous propagation, credential attacks, password cracking, exploitation, persistence, evasion, botnet control and similar offensive execution are excluded from the production registry and command surface.

## Cryptography

AES-256-GCM, SHA-512, RSA, P-256 and post-quantum primitives are exposed only through their dedicated defensive cryptographic services. Library integration is not a claim of FIPS/CMVP certification.

## External runtimes

Termux, Linux distributions, PRoot and other external runtimes are runtime-dependent. Detection must not be interpreted as installation or availability. Missing binaries/filesystems must result in an explicit capability state.

## CI and release verification

The CI pipeline is intentionally strict:

1. Install dependencies.
2. Verify required source assets exist in Git.
3. Run `flutter analyze`.
4. Run `flutter test --coverage`.
5. Build the release APK.

CI does not create placeholder translations, icons or source assets. Missing repository content therefore fails the build instead of being silently synthesized.

## Release gate

A build is not considered production-ready until CI passes and a real Android device validates the Lock Screen, terminal, native PTY lifecycle, security authorization and defensive network diagnostics.

Capability status values are `REAL`, `UNAVAILABLE`, `BLOCKED` or `RUNTIME_DEPENDENT`; no simulated success is permitted.
