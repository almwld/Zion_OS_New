import '../ai/si_agent.dart';
import '../network/real_network_engine.dart';
import '../network/network_stack.dart';
import '../../security/core/security_core.dart';

class ArsenalLayerGateway {
  ArsenalLayerGateway({SecurityCore? security}) : security = security ?? SecurityCore();
  final SecurityCore security;
  final RealNetworkEngine network = RealNetworkEngine();
  final DnsResolver dns = DnsResolver();
  final PacketInspector packets = PacketInspector();
  final SiAgent ai = SiAgent();

  static const blocked = <String>{
    'wifi.wps.bruteforce',
    'wifi.deauth.emit',
    'wifi.evil_twin.capture',
    'wifi.credential_capture',
    'credential.theft',
    'password.cracking',
    'handshake.cracking',
    'pmkid.cracking',
    'sql.exploitation',
    'sql.data_extraction',
    'metasploit.execute',
    'hydra.execute',
  };

  bool isAllowed(String action) => !blocked.contains(action.trim().toLowerCase());

  Future<Map<String, dynamic>> dispatch(String module, String action, Future<Map<String, dynamic>> Function() operation) async {
    final normalized = action.trim().toLowerCase();
    if (!isAllowed(normalized)) return {'status': 'BLOCKED', 'module': module, 'action': normalized, 'reason': 'defensive security policy'};
    try {
      final result = await operation();
      return {'module': module, 'action': normalized, ...result};
    } catch (e) {
      return {'status': 'FAILED', 'module': module, 'action': normalized, 'error': '$e'};
    }
  }

  Future<Map<String, dynamic>> zionNetScan(String host, Iterable<int> ports) async {
    final results = await network.scanPorts(host, ports);
    return {'status': 'REAL', 'module': 'ZionNet', 'host': host, 'results': results.map((r) => {'port': r.port, 'open': r.open, 'latencyMs': r.latencyMs}).toList()};
  }

  Map<String, dynamic> zionWebInspect(List<int> packetBytes) => {'status': 'REAL', 'module': 'ZionWeb', 'packet': packets.inspect(packetBytes)};
  Future<List<String>> resolve(String host) => dns.resolve(host);
  Map<String, dynamic> zionWirelessDefensiveAnalysis(List<String> observations) => ai.guardian(observations);
  Map<String, dynamic> zionPostExploitSafetyAnalysis(List<String> indicators) => ai.guardian(indicators);
}
