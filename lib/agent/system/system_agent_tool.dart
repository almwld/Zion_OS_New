import 'dart:io';
import '../core/agent_models.dart';
import '../tools/tool.dart';

class SystemAgentTool extends AgentTool {
  @override String get name => 'system_info';
  @override String get description => 'معلومات تشخيصية محلية عن النظام والذاكرة والمعالج والتخزين والشبكة.';
  @override Map<String, dynamic> get parameters => const {'action': 'summary | memory | cpu | storage | network'};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async {
    final action = params['action']?.toString() ?? 'summary';
    try {
      switch (action) {
        case 'summary':
          return StepResult.success('اكتمل تشخيص النظام.', data: {
            'platform': Platform.operatingSystem,
            'version': Platform.operatingSystemVersion,
            'memory': await _memory(),
            'cpu': await _cpu(),
            'storage': await _storage(),
          });
        case 'memory': return StepResult.success('تم فحص الذاكرة.', data: await _memory());
        case 'cpu': return StepResult.success('تم فحص المعالج.', data: await _cpu());
        case 'storage': return StepResult.success('تم فحص مساحة التطبيق.', data: await _storage());
        case 'network': return StepResult.success('تم فحص واجهات الشبكة المحلية.', data: await _network());
        default: return StepResult.failure('إجراء system_info غير معروف.');
      }
    } catch (e) {
      return StepResult.failure('فشل تشخيص النظام: $e');
    }
  }

  Future<Map<String, dynamic>> _memory() async {
    final file = File('/proc/meminfo');
    if (!await file.exists()) return const {'available': false};
    final text = await file.readAsString();
    final values = <String, int>{};
    for (final line in text.split('\n')) {
      final m = RegExp(r'^(MemTotal|MemAvailable|SwapTotal|SwapFree):\s+(\d+)').firstMatch(line);
      if (m != null) values[m.group(1)!] = int.parse(m.group(2)!);
    }
    return {'available': true, 'kb': values};
  }

  Future<Map<String, dynamic>> _cpu() async {
    final file = File('/proc/stat');
    if (!await file.exists()) return {'available': false, 'processors': Platform.numberOfProcessors};
    final first = (await file.readAsString()).split('\n').firstWhere((x) => x.startsWith('cpu '), orElse: () => '');
    return {'available': first.isNotEmpty, 'processors': Platform.numberOfProcessors, 'raw': first};
  }

  Future<Map<String, dynamic>> _storage() async {
    final dir = await Directory.systemTemp.createTemp('zion-agent-check-');
    try {
      final stat = await dir.stat();
      return {'available': true, 'tempPath': dir.path, 'modified': stat.modified.toIso8601String()};
    } finally {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }

  Future<List<Map<String, dynamic>>> _network() async {
    final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.any);
    return interfaces.map((i) => {
      'name': i.name,
      'addresses': i.addresses.map((a) => a.address).toList(),
    }).toList();
  }
}
