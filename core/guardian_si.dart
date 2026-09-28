import 'si_core.dart';

class GuardianSI extends SiCore {
  static final GuardianSI _instance = GuardianSI._internal();
  factory GuardianSI() => _instance;
  GuardianSI._internal();

  bool _isActive = false;
  final List<String> _blockedIPs = [];
  final List<String> _allowedCommands = [];

  Future<void> activate() async {
    _isActive = true;
    await super.activate();
    print('🛡️ Guardian SI activated');
  }

  Future<void> deactivate() async {
    _isActive = false;
    print('🛡️ Guardian SI deactivated');
  }

  Future<bool> isCommandAllowed(String command) async {
    if (!_isActive) return true;
    return _allowedCommands.any((c) => command.contains(c));
  }

  Future<void> blockIP(String ip) async {
    if (!_blockedIPs.contains(ip)) {
      _blockedIPs.add(ip);
      print('🚫 Blocked IP: $ip');
    }
  }

  Future<void> unblockIP(String ip) async {
    _blockedIPs.remove(ip);
    print('✅ Unblocked IP: $ip');
  }

  List<String> getBlockedIPs() => List.from(_blockedIPs);
  bool isActive() => _isActive;
}
