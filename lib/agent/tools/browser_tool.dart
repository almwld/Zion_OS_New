import 'package:http/http.dart' as http;
import '../core/agent_models.dart';
import 'tool.dart';

class BrowserTool extends AgentTool {
  @override
  String get name => 'browser';

  @override
  Set<AgentPermission> get permissions => const {AgentPermission.network};

  @override
  String get description =>
      'جلب صفحات ويب والبحث النصي عبر HTTP؛ لا ينفذ JavaScript أو يسجل دخولاً تلقائياً.';

  @override
  Map<String, dynamic> get parameters =>
      const {'action': 'fetch | search', 'url': 'string', 'query': 'string'};

  @override
  Future<StepResult> execute(Map<String, dynamic> p) async {
    final action = p['action']?.toString() ?? 'fetch';
    final target = action == 'search'
        ? 'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(p['query']?.toString() ?? '')}'
        : p['url']?.toString() ?? '';
    final uri = Uri.tryParse(target);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
      return StepResult.failure('رابط غير صالح.');
    }
    if (uri.userInfo.isNotEmpty || _isPrivateOrLocalHost(uri.host)) {
      return StepResult.failure('تم رفض عنوان محلي أو خاص لحماية بيانات الجهاز.');
    }

    try {
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'Zion-Agent/1.0'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return StepResult.failure('HTTP ${response.statusCode}');
      }
      final body = response.body;
      final content = body.length > 120000 ? body.substring(0, 120000) : body;
      return StepResult.success(
        'تم جلب ${content.length} حرف.',
        data: {'url': uri.toString(), 'status': response.statusCode, 'content': content},
      );
    } catch (error) {
      return StepResult.failure('فشل جلب الصفحة: $error');
    }
  }

  bool _isPrivateOrLocalHost(String rawHost) {
    final host = rawHost.toLowerCase().replaceFirst(RegExp(r'\\.$'), '');
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host == '::1' ||
        host == '[::1]') {
      return true;
    }

    final parts = host.split('.');
    if (parts.length == 4) {
      final octets = parts.map(int.tryParse).toList();
      if (octets.every((value) => value != null && value >= 0 && value <= 255)) {
        final a = octets[0]!;
        final b = octets[1]!;
        return a == 0 ||
            a == 10 ||
            a == 127 ||
            (a == 169 && b == 254) ||
            (a == 172 && b >= 16 && b <= 31) ||
            (a == 192 && b == 168) ||
            a >= 224;
      }
    }
    return false;
  }
}
