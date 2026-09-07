import 'dart:io';
import 'package:flutter/foundation.dart';
import 'kali_loader_service.dart';
import 'post_quantum_service.dart';

/// Single source of truth for runtime capability claims.
enum V45Status { real, unavailable, blocked, runtimeDependent }

class V45Capability {
  const V45Capability(this.id, this.status, this.reason);
  final String id;
  final V45Status status;
  final String reason;
}

class V45CapabilityRegistry {
  static Future<List<V45Capability>> probe() async {
    final results = <V45Capability>[];
    final proot = await KaliLoaderService.getStatus();
    results.add(V45Capability('proot-manager', proot['proot_available'] == true ? V45Status.real : V45Status.unavailable, proot['proot_available'] == true ? 'PRoot binary passed its real --version check.' : 'No working PRoot adapter is available on this runtime.'));
    final pqc = PostQuantumService.selfTest();
    results.add(V45Capability('post-quantum-crypto', pqc.ok ? V45Status.real : V45Status.unavailable, pqc.ok ? 'ML-KEM-768 and ML-DSA-65 round-trips passed.' : 'PQC self-test failed; no success is claimed.'));
    results.add(const V45Capability('security-crypto', V45Status.real, 'AES-256-GCM, SHA-512, RSA-2048+ key generation and P-256 ECDSA providers are implemented.'));
    results.add(const V45Capability('network-engine', V45Status.real, 'Real TCP probing and defensive host discovery are implemented.'));
    results.add(const V45Capability('dns-resolver', V45Status.real, 'Uses the platform DNS resolver through InternetAddress.lookup.'));
    results.add(const V45Capability('packet-inspector', V45Status.real, 'IPv4/IPv6 packet header inspection is executable for supplied bytes.'));
    results.add(const V45Capability('live-packet-capture', V45Status.unavailable, 'Unrestricted raw packet capture requires a supported VPN/native/root capture path.'));
    results.add(const V45Capability('p2p-lan', V45Status.real, 'UDP discovery + TCP peer transport is implemented; reachability depends on the local network.'));
    results.add(const V45Capability('cloud-sync', V45Status.runtimeDependent, 'Requires a configured HTTPS backend; success requires HTTP 2xx.'));
    results.add(const V45Capability('llm-integration', V45Status.runtimeDependent, 'Requires a configured HTTP(S) model endpoint and credentials where applicable.'));
    results.add(const V45Capability('websocket', V45Status.real, 'Real WebSocket client transport is implemented.'));
    results.add(V45Capability('holographic-3d', V45Status.real, 'Flutter perspective transform is rendered locally at runtime.'));
    results.add(V45Capability('ios-windows', (Platform.isIOS || Platform.isWindows) ? V45Status.real : V45Status.runtimeDependent, kIsWeb ? 'Web runtime detected; native build must be validated by CI.' : 'Native platform build requires platform-specific CI/device validation.'));
    results.add(const V45Capability('metasploit', V45Status.blocked, 'Offensive exploitation framework execution is intentionally blocked.'));
    results.add(const V45Capability('hydra', V45Status.blocked, 'Credential/password attack execution is intentionally blocked.'));
    results.add(const V45Capability('nmap-defensive-discovery', V45Status.runtimeDependent, 'Available only when a real Nmap binary is present inside the runtime.'));
    return results;
  }
}
