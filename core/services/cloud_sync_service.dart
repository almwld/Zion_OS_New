import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Real, endpoint-driven cloud synchronization.
///
/// The service never invents a successful sync. A configured HTTPS endpoint is
/// required and every upload returns the HTTP result plus a SHA-256 digest.
class CloudSyncResult {
  const CloudSyncResult({required this.ok, required this.status, this.digest, this.error});
  final bool ok;
  final int status;
  final String? digest;
  final String? error;
}

class CloudSyncService {
  Uri? _endpoint;
  String? _bearerToken;

  bool get isConfigured => _endpoint != null && _endpoint!.scheme == 'https';

  void configure({required Uri endpoint, String? bearerToken}) {
    if (endpoint.scheme != 'https') {
      throw ArgumentError('Cloud sync requires HTTPS.');
    }
    _endpoint = endpoint;
    _bearerToken = bearerToken;
  }

  Future<CloudSyncResult> uploadJson({required String collection, required Map<String, dynamic> data}) async {
    final endpoint = _endpoint;
    if (endpoint == null) {
      return const CloudSyncResult(ok: false, status: 0, error: 'UNAVAILABLE: cloud endpoint is not configured');
    }
    final body = utf8.encode(jsonEncode({'collection': collection, 'data': data}));
    final digest = sha256.convert(body).toString();
    final request = await HttpClient().postUrl(endpoint.resolve('./$collection'));
    request.headers.contentType = ContentType.json;
    request.headers.set('x-zion-content-sha256', digest);
    final token = _bearerToken;
    if (token != null && token.isNotEmpty) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.add(body);
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    return CloudSyncResult(ok: ok, status: response.statusCode, digest: digest, error: ok ? null : responseBody);
  }
}
