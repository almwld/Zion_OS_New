# Zion OS — Integrated Architecture Status

This document records what is implemented as executable code and what remains runtime-dependent. A UI is never treated as proof of capability.

## Core
- `lib/core/core_runtime.dart`: persistent multi-session manager, command event pipeline and runtime statistics.
- Existing native PTY remains the real local terminal path where the Android native layer is available.
- Window management already exists in `lib/core/wm/window_manager.dart`; floating-window UI exists separately. Full OS-level windowing remains an application-level Flutter window manager, not a replacement for Android's window manager.

## Network
- `RealNetworkEngine`: real TCP probes and defensive host discovery.
- `DnsResolver`: OS DNS resolution through `InternetAddress.lookup`.
- `PacketInspector`: real IPv4/IPv6 header parsing for supplied packet bytes.
- `LivePacketCapture`: explicitly `UNAVAILABLE` because unrestricted raw capture on Android requires a supported VPN/native/root capture path.
- P2P LAN transport is implemented separately in `p2p_lan_service.dart` and is LAN discovery/data transport, not a global Internet DHT.

## Security
- AES-256-GCM, SHA-512, RSA key generation and P-256 ECDSA primitives are provided by vetted Dart crypto libraries.
- Existing authorization gateway remains the policy boundary.
- "Military crypto" is not treated as a technical algorithm name; the implementation uses standardized cryptographic primitives instead.
- PQC is provided by ML-KEM-768 and ML-DSA-65 through `pqcrypto`; this is not a claim of FIPS/CMVP validation.

## AI Agent
- Local MLP inference and online gradient updates are executable.
- Q-learning is executable.
- Oracle forecasting is statistical regression, not clairvoyance.
- Guardian is a defensive rule layer.
- Empathic analysis is lexical classification, not human-level emotional understanding.
- No claim is made that this is a foundation model or autonomous AGI.

## Integration
- HTTP(S), WebSocket, generic LLM endpoint and cloud synchronization are real network clients.
- External services remain `RUNTIME_DEPENDENT` until an endpoint/configuration is supplied and successfully exercised.

## External systems
- Termux/Kali/Ubuntu/Debian/Alpine/Arch are detected by runtime probes/markers.
- Detection does not install a distribution or claim availability where the runtime lacks its filesystem/binaries.
- PRoot/Kali support remains subject to packaged binary/assets and device ABI/runtime conditions.

## Arsenal
`ArsenalLayerGateway` is the composition boundary for defensive modules. It routes network inspection, packet analysis and SI analysis while preserving the authorization policy. Offensive execution, credential theft, password cracking, deauthentication, rogue-AP capture, SQL exploitation/data extraction, Metasploit execution and Hydra execution remain blocked.

## Verification rule
A capability is only reported as `REAL` after its implementation succeeds. Otherwise the system reports `UNAVAILABLE`, `BLOCKED`, or `RUNTIME_DEPENDENT` with a reason.
