import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ContainerInfo {
  final String name;
  final DateTime created;
  final String version;
  final int size;
  final int filesCount;

  const ContainerInfo({required this.name, required this.created, required this.version, required this.size, required this.filesCount});

  factory ContainerInfo.fromJson(Map<String, dynamic> json) => ContainerInfo(
        name: json['name'] as String,
        created: DateTime.parse(json['created'] as String),
        version: json['version'] as String,
        size: (json['size'] as num).toInt(),
        filesCount: (json['files_count'] as num).toInt(),
      );
}

/// App-private snapshot manager. Android application sandboxes cannot be
/// copied from /data/data by an ordinary Flutter application, so this service
/// snapshots only the app-private documents directory.
class ContainerManager {
  static const _directoryName = 'zion_containers';

  Future<Directory> _root() async {
    final base = await getApplicationDocumentsDirectory();
    final root = Directory('${base.path}/$_directoryName');
    await root.create(recursive: true);
    return root;
  }

  Future<ContainerInfo> createContainer(String name) async {
    final safeName = _safeName(name);
    final root = await _root();
    final source = await getApplicationDocumentsDirectory();
    final target = Directory('${root.path}/$safeName');
    await target.create(recursive: true);

    var files = 0;
    var size = 0;
    await for (final entity in source.list(recursive: true, followLinks: false)) {
      if (entity.path.startsWith('${root.path}/')) continue;
      if (entity is File) {
        final relative = entity.path.substring(source.path.length + 1);
        if (relative.startsWith('$_directoryName/')) continue;
        final out = File('${target.path}/$relative');
        await out.parent.create(recursive: true);
        await entity.copy(out.path);
        files++;
        size += await entity.length();
      }
    }

    final manifest = {
      'name': safeName,
      'created': DateTime.now().toIso8601String(),
      'version': '4.5.0',
      'size': size,
      'files_count': files,
    };
    await File('${target.path}/manifest.json').writeAsString(jsonEncode(manifest));
    return ContainerInfo.fromJson(manifest);
  }

  Future<List<ContainerInfo>> listContainers() async {
    final root = await _root();
    final result = <ContainerInfo>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final manifest = File('${entity.path}/manifest.json');
      if (!await manifest.exists()) continue;
      try {
        result.add(ContainerInfo.fromJson(jsonDecode(await manifest.readAsString()) as Map<String, dynamic>));
      } catch (_) {
        // Ignore an incomplete/corrupt snapshot instead of failing the list.
      }
    }
    return result;
  }

  String _safeName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (cleaned.isEmpty) throw ArgumentError('Container name is empty');
    return cleaned.substring(0, cleaned.length > 64 ? 64 : cleaned.length);
  }
}
