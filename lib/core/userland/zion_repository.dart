import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'zion_pkg.dart';

class ZionRepository {
  ZionRepository({
    this.repoUrl = 'https://repo.zion.os/',
    this.assetRoot = 'assets/repository/',
    http.Client Function()? clientFactory,
    Future<String> Function(String path)? assetLoader,
    Future<List<int>> Function(String path)? packageLoader,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _assetLoader = assetLoader ?? rootBundle.loadString,
       _packageLoader = packageLoader ?? _loadAssetBytes;

  final String repoUrl;
  final String assetRoot;
  final http.Client Function() _clientFactory;
  final Future<String> Function(String path) _assetLoader;
  final Future<List<int>> Function(String path) _packageLoader;

  String getRepoUrl() => repoUrl;

  Future<List<PackageInfo>> listAll() async {
    final json = await _readIndex();
    final packages = json['packages'];
    if (packages is! List) throw const FormatException('Invalid Zion repository Packages.json');
    return packages.whereType<Map>().map((e) => PackageInfo.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
  }

  Future<PackageInfo?> search(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || clean.contains('/') || clean.contains('..')) return null;
    for (final package in await listAll()) {
      if (package.name == clean) return package;
    }
    return null;
  }

  Future<File> download(PackageInfo info) async {
    if (info.sha256.isEmpty) throw const FormatException('Repository package is missing SHA-256.');
    final relative = info.path.isNotEmpty ? info.path : info.name + '/' + info.name + '_' + info.version + '_arm64.deb';
    if (relative.startsWith('/') || relative.contains('..')) throw const FormatException('Unsafe repository package path.');
    final bytes = await _readPackage(relative);
    final actual = sha256.convert(bytes).toString();
    if (actual.toLowerCase() != info.sha256.toLowerCase()) throw const FormatException('Repository package SHA-256 verification failed.');
    final cache = Directory('/data/data/com.zion.os/files/usr/var/cache/zion-pkg');
    await cache.create(recursive: true);
    final file = File(cache.path + '/' + info.name + '_' + info.version + '.deb');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Map<String, dynamic>> _readIndex() async {
    try {
      final raw = await _assetLoader(assetRoot + 'Packages.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Invalid Zion repository index.');
    } on FlutterError {
      final local = File(assetRoot + 'Packages.json');
      if (await local.exists()) {
        final decoded = jsonDecode(await local.readAsString());
        if (decoded is Map<String, dynamic>) return decoded;
      }
      final client = _clientFactory();
      try {
        final response = await client.get(Uri.parse(repoUrl + 'Packages.json'));
        if (response.statusCode != 200) throw HttpException('Repository index HTTP ' + response.statusCode.toString());
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) throw const FormatException('Invalid Zion repository index.');
        return Map<String, dynamic>.from(decoded);
      } finally {
        client.close();
      }
    }
  Future<List<int>> _readPackage(String relative) async {
    try {
      return await _packageLoader(assetRoot + relative);
    } on FlutterError {
      final local = File(assetRoot + relative);
      if (await local.exists()) return local.readAsBytes();
      final client = _clientFactory();
      try {
        final response = await client.get(Uri.parse(repoUrl + relative));
        if (response.statusCode != 200) throw HttpException('Repository package HTTP ' + response.statusCode.toString());
        return response.bodyBytes;
      } finally {
        client.close();
      }
    }
}
