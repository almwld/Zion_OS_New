import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ProotInstallResult {
  const ProotInstallResult({required this.success, required this.message, this.path});
  final bool success; final String message; final String? path;
}

class ProotInstaller {
  static const _owner = 'proot-me'; static const _repo = 'proot-rs'; static const _version = 'v0.1.0';
  Future<Directory> _prefix() async { final dir = await getApplicationSupportDirectory(); final prefix = Directory(dir.path + '/userland/usr'); await prefix.create(recursive: true); return prefix; }
  String _assetName() { final abi = Abi.current(); if (abi == Abi.androidArm64) return 'proot-rs-v0.1.0-aarch64-linux-android.tar.gz'; if (abi == Abi.androidArm) return 'proot-rs-v0.1.0-arm-linux-androideabi.tar.gz'; if (abi == Abi.androidX64) return 'proot-rs-v0.1.0-x86_64-linux-android.tar.gz'; if (abi == Abi.androidIA32) return 'proot-rs-v0.1.0-i686-linux-android.tar.gz'; throw UnsupportedError('Android ABI غير مدعوم: ' + abi.toString()); }
  Future<String?> _releaseDigest(String assetName) async { final uri = Uri.parse('https://api.github.com/repos/' + _owner + '/' + _repo + '/releases/tags/' + _version); final response = await http.get(uri, headers: {'Accept': 'application/vnd.github+json'}); if (response.statusCode != 200) return null; final json = jsonDecode(response.body) as Map<String, dynamic>; for (final raw in (json['assets'] as List<dynamic>? ?? const [])) { final asset = raw as Map<String, dynamic>; if (asset['name'] == assetName) { final digest = asset['digest'] as String?; if (digest == null || !digest.startsWith('sha256:')) return null; return digest.substring(7); } } return null; }
  Future<ProotInstallResult> install({bool force = false}) async {
    final prefix = await _prefix(); final target = File(prefix.path + '/bin/proot'); if (await target.exists() && !force) return ProotInstallResult(success: true, message: 'PRoot موجود فعلاً.', path: target.path);
    final assetName = _assetName(); final digest = await _releaseDigest(assetName); if (digest == null) return const ProotInstallResult(success: false, message: 'تعذر الحصول على SHA-256 من GitHub Release؛ لم يتم تثبيت أي ملف.');
    final temp = Directory(prefix.path + '/.proot-install-' + DateTime.now().microsecondsSinceEpoch.toString()); await temp.create(recursive: true);
    try {
      final response = await http.get(Uri.parse('https://github.com/' + _owner + '/' + _repo + '/releases/download/' + _version + '/' + assetName), headers: {'Accept': 'application/octet-stream'}); if (response.statusCode != 200) return ProotInstallResult(success: false, message: 'فشل تنزيل PRoot: HTTP ' + response.statusCode.toString() + '.');
      final archiveFile = File(temp.path + '/' + assetName); await archiveFile.writeAsBytes(response.bodyBytes, flush: true); final actual = sha256.convert(await archiveFile.readAsBytes()).toString(); if (actual != digest) return const ProotInstallResult(success: false, message: 'فشل تحقق SHA-256 لـ PRoot.');
      final extractDir = Directory(temp.path + '/extract'); await extractFileToDisk(archiveFile.path, extractDir.path); File? binary; await for (final entity in extractDir.list(recursive: true, followLinks: false)) { if (entity is File && entity.uri.pathSegments.last == 'proot') { binary = entity; break; } }
      if (binary == null) return const ProotInstallResult(success: false, message: 'لم يُعثر على executable proot داخل الإصدار.'); await Directory(prefix.path + '/bin').create(recursive: true); final staged = File(prefix.path + '/bin/.proot.new'); await binary.copy(staged.path); final chmod = await Process.run('chmod', ['700', staged.path]); if (chmod.exitCode != 0) return ProotInstallResult(success: false, message: 'تعذر جعل PRoot قابلاً للتنفيذ: ' + chmod.stderr.toString()); await staged.rename(target.path);
      final version = await Process.run(target.path, ['--version']); if (version.exitCode != 0) { try { await target.delete(); } catch (_) {} return ProotInstallResult(success: false, message: 'تم تنزيل PRoot لكن اختبار --version فشل: ' + version.stderr.toString()); }
      return ProotInstallResult(success: true, message: 'تم تثبيت PRoot والتحقق منه.', path: target.path);
    } finally { try { await temp.delete(recursive: true); } catch (_) {} }
  }
}