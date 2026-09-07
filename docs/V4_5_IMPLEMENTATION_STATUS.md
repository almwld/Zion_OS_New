# Zion OS v4.5 implementation status

This document is intentionally evidence-based. A capability is never marked REAL merely because code exists.

## Implemented in this pass

- **PRoot Manager:** real binary extraction, `--version` verification, runtime detection, Kali filesystem install path, and defensive command gate. High-risk offensive wrappers are blocked.
- **P2P Network:** real UDP LAN discovery plus TCP peer transport. Internet-wide decentralisation is not claimed.
- **Post-quantum cryptography:** real ML-KEM-768 (Kyber) and ML-DSA-65 (Dilithium) using `pqcrypto`. A startup self-test verifies encapsulation/decapsulation and sign/verify.
- **Holographic 3D:** real Flutter perspective transform with a live animation controller.
- **Cloud sync:** real HTTPS upload primitive with SHA-256 integrity header. It is runtime-dependent until a real backend endpoint is configured.
- **iOS/Windows:** native build validation workflow added. Device/runtime support is not claimed until the workflow passes.
- **Tooling policy:** Nmap is retained only as a defensive discovery capability. Metasploit and Hydra are explicitly BLOCKED; no credential attack or exploitation path is exposed.

## Not claimed yet

- A successful iOS/Windows build until GitHub Actions reports PASS.
- A successful cloud sync until a real HTTPS backend returns 2xx.
- PRoot/Kali availability until the target device contains a working PRoot binary and a valid Kali filesystem.
- Internet-scale P2P/NAT traversal; current transport is LAN scoped.
- FIPS/CMVP certification for the PQC library. The integrated primitive is post-quantum cryptography, not a certification claim.

## Release gate

The repository must pass the v4.5 platform workflow and runtime capability probes before the release can honestly be called fully production-ready.
