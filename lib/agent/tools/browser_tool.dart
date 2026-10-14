import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/agent_models.dart';
import 'tool.dart';

class BrowserTool extends AgentTool {
  static const int _maxBodyBytes = 120000;
  static const int _maxRedirects = 5;
  static const Duration _requestTimeout = Duration(seconds: 15);

  @override
  String get name => 'browser';

  @override
  Set<AgentPermission> get permissions => const {AgentPermission.network};

  @override
  bool get supportsReadOnlyWebRetrieval => true;

  @override
  String get description =>
      'جلب صفحات ويب والبحث النصي عبر HTTP؛ لا ينفذ JavaScript أو يسجل دخولاً تلقائياً.';

  @override
  Map<String, dynamic> get parameters =>
      const {'action': 'fetch | search', 'url': 'string', 'query': 'string'};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async {
    final action = params['action']?.toString() ?? 'fetch';
    if (action != 'fetch' && action != 'search') {
      return StepResult.failure('إجراء المتصفح غير مدعوم.');
    }
    final target = action == 'search'
        ? 'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(params['query']?.toString() ?? '')}'
        : params['url']?.toString() ?? '';
    final parsedUri = Uri.tryParse(target);
    if (parsedUri == null ||
        (parsedUri.scheme != 'http' && parsedUri.scheme != 'https') ||
        parsedUri.host.isEmpty ||
        parsedUri.userInfo.isNotEmpty) {
      return StepResult.failure('رابط غير صالح أو محظور لأسباب أمنية.');
    }
    if (_isPrivateOrLocalHost(parsedUri.host)) {
      return StepResult.failure('تم رفض عنوان محلي أو خاص لحماية بيانات الجهاز.');
    }
    var uri = parsedUri;

    final client = http.Client();
    try {
      for (var redirects = 0; redirects <= _maxRedirects; redirects++) {
        final safe = await _validateDestination(uri);
        if (!safe) {
          return StepResult.failure(
            'تم رفض عنوان محلي أو خاص لحماية بيانات الجهاز.',
          );
        }

        final request = http.Request('GET', uri)
          ..followRedirects = false
          ..headers['User-Agent'] = 'Zion-Agent/1.0'
          ..headers['Accept'] = 'text/html,text/plain,application/xhtml+xml';

        final response = await client.send(request).timeout(_requestTimeout);
        if (_isRedirect(response.statusCode)) {
          final location = response.headers['location'];
          await response.stream.listen((_) {}).cancel();
          if (location == null || redirects == _maxRedirects) {
            return StepResult.failure('تعذر إكمال إعادة توجيه الصفحة بأمان.');
          }
          final next = Uri.tryParse(location);
          if (next == null) {
            return StepResult.failure('رابط إعادة التوجيه غير صالح.');
          }
          uri = uri.resolveUri(next);
          if (!_isAllowedUri(uri)) {
            return StepResult.failure('تم رفض إعادة توجيه إلى عنوان غير آمن.');
          }
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 400) {
          await response.stream.listen((_) {}).cancel();
          return StepResult.failure('HTTP ${response.statusCode}');
        }

        final bytes = await _readLimited(response.stream)
            .timeout(_requestTimeout);
        final content = utf8.decode(bytes, allowMalformed: true);
        return StepResult.success(
          'تم جلب ${bytes.length} بايت من الصفحة.',
          data: {
            'url': uri.toString(),
            'status': response.statusCode,
            'content': content,
            'truncated': bytes.length >= _maxBodyBytes,
          },
        );
      }
      return StepResult.failure('تم تجاوز الحد المسموح لإعادة التوجيه.');
    } on TimeoutException {
      return StepResult.failure('انتهت مهلة الاتصال بالصفحة بعد 15 ثانية.');
    } catch (error) {
      return StepResult.failure('فشل جلب الصفحة: $error');
    } finally {
      client.close();
    }
  }

  bool _isRedirect(int status) =>
      status == 301 || status == 302 || status == 303 ||
      status == 307 || status == 308;

  bool _isAllowedUri(Uri uri) =>
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !_isPrivateOrLocalHost(uri.host);

  Future<bool> _validateDestination(Uri uri) async {
    if (!_isAllowedUri(uri)) return false;
    final literal = InternetAddress.tryParse(uri.host);
    if (literal != null) return !_isPrivateAddress(literal);

    // Check DNS answers before connecting. This blocks common hostname-based
    // SSRF attempts, including private destinations hidden behind DNS names.
    try {
      final addresses = await InternetAddress.lookup(uri.host)
          .timeout(const Duration(seconds: 3));
      return addresses.isNotEmpty && addresses.every(_isPublicAddress);
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  bool _isPublicAddress(InternetAddress address) =>
      !_isPrivateAddress(address);

  bool _isPrivateOrLocalHost(String rawHost) {
    var host = rawHost.toLowerCase().endsWith('.')
        ? rawHost.toLowerCase().substring(0, rawHost.length - 1)
        : rawHost.toLowerCase();
    if (host.startsWith('[') && host.endsWith(']')) {
      host = host.substring(1, host.length - 1);
    }
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host == 'metadata.google.internal' ||
        host.endsWith('.internal')) {
      return true;
    }
    final address = InternetAddress.tryParse(host);
    if (address != null) return _isPrivateAddress(address);

    final parts = host.split('.');
    if (parts.length == 4) {
      final octets = parts.map(int.tryParse).toList();
      if (octets.every((value) => value != null && value >= 0 && value <= 255)) {
        final a = octets[0]!;
        final b = octets[1]!;
        return a == 0 || a == 10 || a == 127 ||
            (a == 169 && b == 254) ||
            (a == 172 && b >= 16 && b <= 31) ||
            (a == 192 && b == 168) ||
            (a == 100 && b >= 64 && b <= 127) ||
            (a == 192 && b == 0) ||
            (a == 198 && (b == 18 || b == 19)) ||
            a >= 224;
      }
    }
    return false;
  }

  bool _isPrivateAddress(InternetAddress address) {
    final bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv4) {
      final a = bytes[0];
      final b = bytes[1];
      return a == 0 || a == 10 || a == 127 ||
          (a == 169 && b == 254) ||
          (a == 172 && b >= 16 && b <= 31) ||
          (a == 192 && b == 168) ||
          (a == 100 && b >= 64 && b <= 127) ||
          (a == 192 && b == 0) ||
          (a == 198 && (b == 18 || b == 19)) ||
          a >= 224;
    }
    if (address.type == InternetAddressType.IPv6) {
      final allZero = bytes.every((byte) => byte == 0);
      final loopback = bytes.take(15).every((byte) => byte == 0) && bytes.last == 1;
      final first = bytes.first;
      final linkLocal = first == 0xfe && (bytes[1] & 0xc0) == 0x80;
      final uniqueLocal = (first & 0xfe) == 0xfc;
      final multicast = first == 0xff;
      final mappedIpv4 = bytes.take(10).every((byte) => byte == 0) &&
          bytes[10] == 0xff && bytes[11] == 0xff;
      final compatibleIpv4 = bytes.take(12).every((byte) => byte == 0);
      if (mappedIpv4 || compatibleIpv4) {
        final mapped = InternetAddress.fromRawAddress(bytes.sublist(12));
        return _isPrivateAddress(mapped);
      }
      return allZero || loopback || linkLocal || uniqueLocal || multicast;
    }
    return true;
  }

  Future<List<int>> _readLimited(Stream<List<int>> stream) async {
    final iterator = StreamIterator<List<int>>(stream);
    final output = BytesBuilder(copy: false);
    var length = 0;
    try {
      while (length < _maxBodyBytes && await iterator.moveNext()) {
        final chunk = iterator.current;
        final take = (_maxBodyBytes - length).clamp(0, chunk.length).toInt();
        if (take > 0) {
          output.add(take == chunk.length ? chunk : chunk.sublist(0, take));
          length += take;
        }
      }
    } finally {
      await iterator.cancel();
    }
    return output.takeBytes();
  }
}
