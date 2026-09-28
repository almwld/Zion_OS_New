import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'zion_pkg.dart';

class ZionRepositoryPackage {
  const ZionRepositoryPackage({required this.name, required this.version, required this.url, required this.sha256});
  final String name, version, url, sha256;
  factory ZionRepositoryPackage.fromJson(Map<String, dynamic> json) => ZionRepositoryPackage(name: json['name'] as String, version: json['version'] as String, url: json['url'] as String, sha256: (json['sha256'] as String).toLowerCase());
}

class ZionPackageRepository {
  const ZionPackageRepository({required this.baseUri, this.clientFactory = http.Client.new});
  final Uri baseUri;
  final http.Client Function() clientFactory;

  Future<List<ZionRepositoryPackage>> index() async {
    _validateUri(baseUri);
    final client = clientFactory();
    try {
      final response = await client.get(baseUri.resolve('index.json'));
      if (response.statusCode != 200) throw HttpException('Repository index HTTP ${response.statusCode}');
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['packages'] is! List) throw const FormatException('Invalid Zion repository index');
      return (decoded['packages'] as List).whereType<Map>().map((e) => ZionRepositoryPackage.fromJson(Map<String,dynamic>.from(e))).toList(growable:false);
    } finally { client.close(); }
  }

  Future<PkgResult> install(ZionPkg pkg, String name) async {
    final packages = await index();
    final matches = packages.where((p) => p.name == name).toList();
    if (matches.length != 1) return PkgResult.failure('Package not found uniquely: $name');
    final entry = matches.single;
    _validateUri(Uri.parse(entry.url));
    final client = clientFactory();
    try {
      final response = await client.get(Uri.parse(entry.url));
      if (response.statusCode != 200) return PkgResult.failure('Repository download HTTP ${response.statusCode}');
      final actual = sha256.convert(response.bodyBytes).toString();
      if (actual != entry.sha256) return const PkgResult.failure('Repository package SHA-256 verification failed.');
      final dir = Directory(pkgCachePath); await dir.create(recursive:true);
      final file = File('$pkgCachePath/${entry.name}_${entry.version}.deb');
      await file.writeAsBytes(response.bodyBytes, flush:true);
      return pkg.installFromFile(file.path);
    } finally { client.close(); }
  }

  static void _validateUri(Uri uri) {
    if (uri.scheme != 'https') throw ArgumentError('Zion repositories must use HTTPS.');
  }

  static const pkgCachePath = '/data/data/com.zion.os/files/usr/var/cache/zion-pkg';
}