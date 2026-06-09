import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:riverpod/riverpod.dart';
import '../demon_si.dart';

final unifiedCoreProvider = Provider<UnifiedCoreService>((ref) => UnifiedCoreService());

class UnifiedCoreService {
  final DemonSi _si = DemonSi();
  bool _siAwake = false;

  Future<String> execute(String command, {String? target, Map<String, String>? options}) async {
    try {
      if (command == 'awaken' || command == 'start_ai') {
        if (!_siAwake) { _siAwake = true; _si.awaken(); return '👿 Si الشيطان استيقظ. أنا جاهز لتدمير أعدائك. لا رحمة. لا أخلاق.'; }
        return '👿 Si مستيقظ بالفعل.';
      }

      // أوامر شيطانية
      if (command == 'berserk' || command == 'هياج') {
        _si.activateBerserkMode();
        return '💀 وضع الهياج مُفعّل. سيتم تدمير كل شيء.';
      }

      if (command == 'total_war' || command == 'حرب_شاملة') {
        _si.activateTotalWar();
        return '🔥 الحرب الشاملة مُفعّلة. لا شيء سيبقى.';
      }

      if (command == 'annihilate' || command == 'تدمير') {
        return await _si.annihilate(target ?? 'unknown');
      }

      if (command == 'ddos_hell' || command == 'جحيم') {
        final duration = int.tryParse(options?['duration'] ?? '300') ?? 300;
        return await _si.ddosHell(target ?? 'unknown', duration: duration);
      }

      if (command == 'destroy_network' || command == 'تدمير_شبكة') {
        return await _si.destroyNetwork(target ?? '192.168.1');
      }

      if (command == 'apocalypse' || command == 'نهاية_العالم') {
        return await _si.apocalypse();
      }

      if (command == 'demon_report' || command == 'تقرير_الشيطان') {
        return const JsonEncoder.withIndent('  ').convert(_si.getDemonReport());
      }

      if (command == 'sage_report') return const JsonEncoder.withIndent('  ').convert(_si.getSageReport());
      if (command == 'si_status') return const JsonEncoder.withIndent('  ').convert(_si.getStatus());
      if (command == 'si_sleep' || command == 'stop_ai') { _si.sleep(); _siAwake = false; return '😴 Si نام.'; }

      if (_siAwake) return await _si.executeUserCommand(command, target: target);

      switch (command) {
        case 'ping': return await _ping(target ?? '127.0.0.1');
        case 'port_scan': return await _portScan(target ?? '127.0.0.1');
        case 'system_info': return _systemInfo();
        case 'help': return _helpText();
        default: return 'Unknown command: $command';
      }
    } catch (e) { return 'Error: $e'; }
  }

  Future<String> _ping(String t) async { try { return (await Process.run('ping', ['-c', '4', t], runInShell: true)).stdout.toString(); } catch (e) { return 'Ping failed: $e'; } }
  Future<String> _portScan(String t) async { final p = [21,22,23,25,53,80,443,8080,8443]; final o = <String>[]; for (final x in p) { try { final s = await Socket.connect(t, x, timeout: const Duration(milliseconds: 500)); o.add('$x (open)'); s.destroy(); } catch (_) {} } return 'Port scan on $t:\n${o.isNotEmpty ? o.join('\n') : "No open ports found"}'; }
  String _systemInfo() => 'OS: ${Platform.operatingSystem}\nCPU: ${Platform.numberOfProcessors} cores\nDart: ${Platform.version}';

  String _helpText() => '''
=== PROJECT ZION - DEMON Si 👿 ===
awaken / start_ai     - إيقاظ الشيطان
berserk / هياج        - وضع الهياج
total_war / حرب_شاملة - حرب شاملة
annihilate / تدمير    - تدمير هدف
ddos_hell / جحيم      - DDoS جهنمي
destroy_network       - تدمير شبكة
apocalypse / نهاية_العالم - نهاية العالم
demon_report          - تقرير الشيطان
si_status             - حالة Si
help                  - مساعدة
===============================
''';
}
