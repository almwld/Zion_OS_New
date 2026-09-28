import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../security/core/security_core.dart';
import 'zion_repository.dart';

enum PackageStatus { installed, available, system, notInstalled }

class PackageInfo {
  const PackageInfo({required this.name, required this.version, required this.installedAt, required this.source, this.sha256 = '', this.path = '', this.architecture = 'arm64'});
  final String name, version, source, sha256, path, architecture;
  final DateTime installedAt;
  factory PackageInfo.fromJson(Map<String, dynamic> j) => PackageInfo(
    name: j['name'] as String, version: j['version'] as String,
    installedAt: j['installedAt'] == null ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true) : DateTime.parse(j['installedAt'] as String),
    source: (j['source'] ?? 'repository') as String, sha256: (j['sha256'] ?? '') as String,
    path: (j['path'] ?? '') as String, architecture: (j['architecture'] ?? 'arm64') as String,
  );
  Map<String, Object?> toJson() => {'name': name, 'version': version, 'installedAt': installedAt.toIso8601String(), 'source': source, 'sha256': sha256, 'path': path, 'architecture': architecture};
}

class PkgResult {
  const PkgResult._({required this.success, this.message, this.error});
  const PkgResult.success(String m) : this._(success: true, message: m);
  const PkgResult.failure(String e) : this._(success: false, error: e);
  final bool success;
  final String? message, error;
}

class ZionPkg {
  static const prefix = '/data/data/com.zion.os/files/usr';
  static const home = '/data/data/com.zion.os/files/home';
  static const dbPath = prefix + '/var/lib/zion-pkg/installed.json';
  static const cacheDir = prefix + '/var/cache/zion-pkg';

  const ZionPkg({SecurityCore? securityCore, ZionRepository? repository}) : _securityCore = securityCore, _repository = repository;
  final SecurityCore? _securityCore;
  final ZionRepository? _repository;

  Future<List<PackageInfo>> getInstalledPackages() async {
    try {
      final f = File(dbPath);
      if (!await f.exists()) return [];
      final v = jsonDecode(await f.readAsString());
      if (v is! List) return [];
      return v.whereType<Map>().map((e) => PackageInfo.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
    } catch (_) { return []; }
  }

  Future<PackageInfo?> findPackage(String n) async {
    for (final p in await getInstalledPackages()) { if (p.name == n) return p; }
    return null;
  }

  Future<PackageStatus> getStatus(String n) async {
    if (await findPackage(n) != null) return PackageStatus.installed;
    if (await File(prefix + '/bin/' + n).exists()) return PackageStatus.available;
    final w = await _which(n);
    return w == null ? PackageStatus.notInstalled : PackageStatus.system;
  }

  Future<PkgResult> installByName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || clean.contains('/') || clean.contains('..')) return _fail('اسم الحزمة غير صالح.');
    try {
      final repo = _repository ?? ZionRepository();
      final info = await repo.search(clean);
      if (info == null) return _fail('الحزمة غير موجودة في Zion Repository: ' + clean);
      final deb = await repo.download(info);
      final result = await installFromFile(deb.path, expectedSha256: info.sha256);
      if (!result.success && await deb.exists()) await deb.delete();
      return result;
    } catch (e) { return _fail('فشل تنزيل الحزمة من Zion Repository: ' + e.toString()); }
  }

  Future<PkgResult> installFromFile(String path, {String? expectedSha256}) async {
    final f = File(path);
    if (!await f.exists()) return _fail('ملف الحزمة غير موجود.');
    if (!path.toLowerCase().endsWith('.deb')) return _fail('zion-pkg يدعم ملفات .deb فقط.');
    final shaExpected = expectedSha256 ?? await _readShaSidecar(path);
    if (shaExpected != null && shaExpected.isNotEmpty) {
      final actual = await _sha256(f);
      if (actual.toLowerCase() != shaExpected.toLowerCase()) {
        _audit('userland.pkg.install', 'sha_mismatch', {'file': path, 'expected': shaExpected, 'actual': actual});
        return const PkgResult.failure('SHA-256 mismatch');
      }
    }
    final dpkg = prefix + '/bin/dpkg';
    final deb = prefix + '/bin/dpkg-deb';
    if (!await _file(dpkg) || !await _file(deb)) return _notConfigured('dpkg/dpkg-deb غير مثبتين داخل Zion Userland. لن يتم استخدام dpkg النظام.');
    final meta = await Process.run(deb, ['-f', path, 'Package', 'Version', 'Architecture'], runInShell: false, environment: _env());
    if (meta.exitCode != 0) return _fail('ملف .deb غير صالح أو تعذر قراءة بياناته.');
    final parts = meta.stdout.toString().trim().split(RegExp(r'\s+'));
    if (parts.length < 3) return _fail('بيانات Package/Version/Architecture غير مكتملة.');
    if (parts[2] != 'all' && parts[2] != 'arm64') return _fail('معمارية الحزمة غير مدعومة: ' + parts[2]);
    final r = await Process.run(dpkg, ['--root=' + prefix, '-i', path], runInShell: false, environment: _env());
    if (r.exitCode != 0) return _fail('فشل تثبيت الحزمة: ' + r.stderr.toString().trim());
    await _record(PackageInfo(name: parts[0], version: parts[1], architecture: parts[2], installedAt: DateTime.now().toUtc(), source: path, sha256: await _sha256(f)));
    _audit('userland.pkg.install', 'success', {'package': parts[0], 'version': parts[1], 'source': 'REAL_DPKG'});
    return const PkgResult.success('تم تثبيت الحزمة عبر dpkg الخاص بـ Zion Userland.');
  }

  Future<PkgResult> remove(String n) async {
    if (n.trim().isEmpty || n.contains('/') || n.contains('..')) return _fail('اسم الحزمة غير صالح.');
    final dpkg = prefix + '/bin/dpkg';
    if (!await _file(dpkg)) return _notConfigured('dpkg غير مثبت داخل Zion Userland.');
    final r = await Process.run(dpkg, ['--root=' + prefix, '-r', n], runInShell: false, environment: _env());
    if (r.exitCode != 0) return _fail('فشل حذف الحزمة: ' + r.stderr.toString().trim());
    await _remove(n);
    _audit('userland.pkg.remove', 'success', {'package': n, 'source': 'REAL_DPKG'});
    return const PkgResult.success('تم حذف الحزمة.');
  }

  Future<PkgResult> update() => _apt(['update'], 'userland.pkg.update');
  Future<PkgResult> upgrade() => _apt(['upgrade', '-y'], 'userland.pkg.upgrade');

  Future<Map<String, PackageStatus>> checkTools() async {
    final out = <String, PackageStatus>{};
    for (final n in ['bash', 'apt', 'dpkg', 'dpkg-deb', 'proot', 'ssh', 'curl', 'wget', 'git', 'python3']) out[n] = await getStatus(n);
    return out;
  }

  Future<PkgResult> _apt(List<String> a, String action) async {
    final apt = prefix + '/bin/apt';
    if (!await _file(apt)) return _notConfigured('apt غير مثبت داخل Zion Userland.');
    await Directory(cacheDir).create(recursive: true);
    final r = await Process.run(apt, a, runInShell: false, environment: _env());
    if (r.exitCode == 0) {
      _audit(action, 'success', {'source': 'REAL_APT'});
      return const PkgResult.success('اكتملت العملية عبر apt الخاص بـ Zion Userland.');
    }
    return _fail('فشلت عملية apt: ' + r.stderr.toString().trim());
  }

  Future<String?> _readShaSidecar(String path) async {
    final sidecar = File(path + '.sha256');
    if (!await sidecar.exists()) return null;
    final value = (await sidecar.readAsString()).trim().split(RegExp(r'\s+')).first;
    return RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value) ? value : null;
  }

  Future<String> _sha256(File file) async => (await sha256.bind(file.openRead()).first).toString();

  Future<String?> _which(String n) async {
    try {
      final safe = n.replaceAll(RegExp(r'[^A-Za-z0-9_.+-]'), '');
      if (safe.isEmpty) return null;
      final r = await Process.run('/system/bin/sh', ['-c', 'command -v ' + safe], runInShell: false);
      if (r.exitCode != 0) return null;
      final v = r.stdout.toString().trim();
      return v.isEmpty ? null : v;
    } catch (_) { return null; }
  }

  Future<bool> _file(String p) async {
    try { return (await File(p).stat()).type == FileSystemEntityType.file; } catch (_) { return false; }
  }

  Map<String, String> _env() => {
    'PREFIX': prefix,
    'HOME': home,
    'PATH': prefix + '/bin:/system/bin:/system/xbin',
    'TMPDIR': prefix + '/tmp',
  };

  Future<void> _record(PackageInfo i) async {
    final p = (await getInstalledPackages()).toList()..removeWhere((x) => x.name == i.name)..add(i);
    final f = File(dbPath);
    await f.parent.create(recursive: true);
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(p.map((x) => x.toJson()).toList()));
  }

  Future<void> _remove(String n) async {
    final p = (await getInstalledPackages()).where((x) => x.name != n).toList();
    final f = File(dbPath);
    await f.parent.create(recursive: true);
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(p.map((x) => x.toJson()).toList()));
  }

  PkgResult _notConfigured(String m) {
    _audit('userland.pkg.operation', 'not-configured', {'reason': m});
    return PkgResult.failure('NOT_CONFIGURED: ' + m);
  }

  PkgResult _fail(String m) {
    _audit('userland.pkg.operation', 'failed', {'error': m});
    return PkgResult.failure(m);
  }

  void _audit(String a, String o, Map<String, Object?> m) {
    _securityCore?.auditLogger.log(action: a, actor: 'zion-pkg', outcome: o, target: 'local-userland', metadata: m);
  }
}
