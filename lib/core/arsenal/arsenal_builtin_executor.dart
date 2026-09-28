import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../security/core/authorization_policy.dart';
import '../../security/core/security_core.dart';
import '../ai/zion_ai_service.dart';
import '../../src/core/services/system_metrics.dart';

class ArsenalBuiltinExecutor {
  ArsenalBuiltinExecutor(this.securityCore);
  final SecurityCore securityCore;

  Future<ArsenalBuiltinResult?> execute({
    required String toolId,
    required List<String> arguments,
    required String actor,
    required AuthorizationScope scope,
  }) async {
    switch (toolId) {
      case 'forensics.hash':
      case 'crypto.hash':
        return _hash(toolId, arguments);
      case 'ai.analysis':
        return _ai(arguments);
      case 'defense.audit':
        return _audit();
      case 'analysis.logs':
        return _logs(arguments);
      case 'utility.system-info':
        return _systemInfo();
      case 'web.inspect':
        return _web(arguments);
      default:
        return null;
    }
  }

  Future<ArsenalBuiltinResult> _hash(String toolId, List<String> args) async {
    if (args.isEmpty) return ArsenalBuiltinResult.failure('INVALID_ARGUMENTS', 'Usage: ${toolId} <file> [sha256|sha512]');
    final file = File(args.first);
    if (!await file.exists()) return ArsenalBuiltinResult.failure('NOT_FOUND', 'File does not exist: ${args.first}');
    final algorithm = (args.length > 1 ? args[1] : 'sha256').toLowerCase();
    if (algorithm != 'sha256' && algorithm != 'sha512') return ArsenalBuiltinResult.failure('INVALID_ARGUMENTS', 'Supported algorithms: sha256, sha512');
    final digest = await (algorithm == 'sha512' ? sha512.bind(file.openRead()).first : sha256.bind(file.openRead()).first);
    return ArsenalBuiltinResult.success('${algorithm.toUpperCase()} ${digest.toString()}  ${file.path}');
  }

  Future<ArsenalBuiltinResult> _ai(List<String> args) async {
    final ai = ZionAiService(securityCore: securityCore);
    if (args.isEmpty || args.first == 'help') {
      return ArsenalBuiltinResult.success('Usage: ai.analysis security <openPorts> <anomalies> <authFailures> <encryptedTraffic> | forecast <v1> <v2> <v3> ... | guardian <indicator...>');
    }
    switch (args.first.toLowerCase()) {
      case 'security':
        if (args.length != 5) return ArsenalBuiltinResult.failure('INVALID_ARGUMENTS', 'security requires 4 numeric features.');
        final values = args.skip(1).map(double.tryParse).toList();
        if (values.any((v) => v == null)) return ArsenalBuiltinResult.failure('INVALID_ARGUMENTS', 'Security features must be numeric.');
        return ArsenalBuiltinResult.success(jsonEncode(ai.analyzeSecurity(openPorts: values[0]!, anomalies: values[1]!, authFailures: values[2]!, encryptedTraffic: values[3]!)));
      case 'forecast':
        return ArsenalBuiltinResult.success(jsonEncode(ai.forecast(args.skip(1).map(double.tryParse).whereType<double>().toList())));
      case 'guardian':
        return ArsenalBuiltinResult.success(jsonEncode(ai.guardian(args.skip(1).toList())));
      default:
        return ArsenalBuiltinResult.failure('INVALID_ARGUMENTS', 'Unknown AI operation: ${args.first}');
    }
  }

  ArsenalBuiltinResult _audit() {
    final records = securityCore.auditLogger.records;
    return ArsenalBuiltinResult.success(jsonEncode({'count': records.length, 'records': records.take(100).map((r) => r.toJson()).toList()}));
  }

  Future<ArsenalBuiltinResult> _logs(List<String> args) async {
    final path = args.isEmpty ? securityCore.auditLogger.filePath : args.first;
    final file = File(path);
    if (!await file.exists()) return ArsenalBuiltinResult.failure('NOT_FOUND', 'Audit log does not exist: ${path}');
    final lines = await file.readAsLines();
    final limit = args.length > 1 ? (int.tryParse(args[1]) ?? 50).clamp(1, 500).toInt() : 50;
    return ArsenalBuiltinResult.success(lines.reversed.take(limit).toList().reversed.join('\n'));
  }

  Future<ArsenalBuiltinResult> _systemInfo() async {
    final m = await SystemMetrics.read();
    return ArsenalBuiltinResult.success(jsonEncode({'cpuPercent': m.cpuPercent, 'memoryPercent': m.memoryPercent, 'memoryUsedBytes': m.memoryUsedBytes, 'memoryTotalBytes': m.memoryTotalBytes, 'storagePercent': m.storagePercent, 'uptimeSeconds': m.uptime.inSeconds}));
  }

  Future<ArsenalBuiltinResult> _web(List<String> args) async {
    if (args.isEmpty) return ArsenalBuiltinResult.failure('INVALID_ARGUMENTS', 'Usage: web.inspect <http(s)://url>');
    final uri = Uri.tryParse(args.first);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) return ArsenalBuiltinResult.failure('INVALID_ARGUMENTS', 'Only valid HTTP(S) URLs are supported.');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final response = await client.getUrl(uri).then((r) => r.close()).timeout(const Duration(seconds: 15));
      final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 15));
      return ArsenalBuiltinResult.success(jsonEncode({'status': response.statusCode, 'contentType': response.headers.contentType?.mimeType, 'contentLength': body.length, 'finalUri': response.redirects.isEmpty ? uri.toString() : response.redirects.last.location.toString(), 'preview': body.length > 4000 ? body.substring(0, 4000) : body}));
    } catch (e) {
      return ArsenalBuiltinResult.failure('FAILED', 'Web inspection failed: ${e}');
    } finally {
      client.close(force: true);
    }
  }
}

class ArsenalBuiltinResult {
  const ArsenalBuiltinResult(this.success, this.status, this.stdout, this.reason);
  factory ArsenalBuiltinResult.success(String stdout) => ArsenalBuiltinResult(true, 'SUCCESS', stdout, null);
  factory ArsenalBuiltinResult.failure(String status, String reason) => ArsenalBuiltinResult(false, status, '', reason);
  final bool success;
  final String status;
  final String stdout;
  final String? reason;
}
