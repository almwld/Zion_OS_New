import 'dart:convert';
import 'dart:io';
import 'dart:ffi';

import 'package:http/http.dart' as http;

class ZionBootstrapEndpoint {
  const ZionBootstrapEndpoint();

  /// Single public bootstrap endpoint. It returns the currently published
  /// archive metadata; the app never needs to know release asset paths.
  static const String url =
      'https://github.com/almwld/Zion_OS_New/releases/download/zion-userland-latest/bootstrap.json';

  Future<ZionBootstrapManifest> fetch({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await http.get(
      Uri.parse(url),
      headers: const {'Accept': 'application/json', 'User-Agent': 'Zion-OS'},
    ).timeout(timeout);
    if (response.statusCode != 200) {
      throw HttpException('Bootstrap endpoint HTTP ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Bootstrap endpoint returned invalid JSON.');
    }
    return ZionBootstrapManifest.fromJson(Map<String, dynamic>.from(decoded));
  }

  static String currentAbi() {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) return 'aarch64';
    if (abi == Abi.androidArm) return 'arm';
    if (abi == Abi.androidX64) return 'x86_64';
    return abi.toString();
  }
}

class ZionBootstrapManifest {
  final String format;
  final String release;
  final Map<String, ZionBootstrapAsset> assets;

  const ZionBootstrapManifest({
    required this.format,
    required this.release,
    required this.assets,
  });

  factory ZionBootstrapManifest.fromJson(Map<String, dynamic> json) {
    if (json['format'] != 'zion-bootstrap-endpoint-v1') {
      throw const FormatException('Unsupported Zion bootstrap endpoint format.');
    }
    final release = json['release']?.toString().trim() ?? '';
    if (release.isEmpty) {
      throw const FormatException('Bootstrap endpoint has no release.');
    }

    final raw = json['assets'];
    if (raw is! Map) {
      throw const FormatException('Bootstrap endpoint has no assets map.');
    }

    final assets = <String, ZionBootstrapAsset>{};
    for (final entry in raw.entries) {
      if (entry.value is! Map) continue;
      assets[entry.key.toString()] =
          ZionBootstrapAsset.fromJson(Map<String, dynamic>.from(entry.value as Map));
    }
    if (assets.isEmpty) {
      throw const FormatException('Bootstrap endpoint has no usable assets.');
    }

    return ZionBootstrapManifest(
      format: json['format'].toString(),
      release: release,
      assets: assets,
    );
  }
}

class ZionBootstrapAsset {
  final String url;
  final String sha256;
  final int size;

  const ZionBootstrapAsset({
    required this.url,
    required this.sha256,
    required this.size,
  });

  factory ZionBootstrapAsset.fromJson(Map<String, dynamic> json) {
    final url = json['url']?.toString().trim() ?? '';
    final sha256 = json['sha256']?.toString().trim().toLowerCase() ?? '';
    final size = (json['size'] as num?)?.toInt() ?? 0;
    if (!url.startsWith('https://') ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256) ||
        size <= 0) {
      throw const FormatException('Invalid bootstrap asset metadata.');
    }
    return ZionBootstrapAsset(url: url, sha256: sha256, size: size);
  }
}
