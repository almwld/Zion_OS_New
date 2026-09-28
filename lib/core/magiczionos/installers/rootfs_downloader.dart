import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum ZionRootfsDistro { ubuntu, debian, alpine, kali }
class RootfsInstallResult { const RootfsInstallResult({required this.success, required this.message, this.path}); final bool success; final String message; final String? path; }

class RootfsDownloader {
  static const ubuntuBase = 'https://cloud-images.ubuntu.com/buildd/releases/noble/release/'; static const debianBase = 'https://cloud.debian.org/images/cloud/bookworm/latest/'; static const alpineBase = 'https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/aarch64/'; static const kaliBase = 'https://old.kali.org/nethunter-images/kali-2025.3/rootfs/';
  Future<Directory> _rootfsDir() async { final support = await getApplicationSupportDirectory(); final dir = Directory(support.path + '/userland/home/.zion/dists'); await dir.create(recursive: true); return dir; }
  String _arch() { final value = Platform.environment['ZION_ROOTFS_ARCH']; if (value == 'arm64' || value == 'armhf' || value == 'amd64') return value!; return 'arm64'; }
  (String, String) _source(ZionRootfsDistro distro) { final arch = _arch(); switch (distro) { case ZionRootfsDistro.ubuntu: final suffix = arch == 'armhf' ? 'armhf' : 'arm64'; final file = 'noble-server-cloudimg-' + suffix + '-root.tar.gz'; return (ubuntuBase + file, ubuntuBase + 'SHA256SUMS'); case ZionRootfsDistro.debian: if (arch != 'arm64') throw UnsupportedError('Debian rootfs الحالي مثبت كـ arm64 فقط.'); const file = 'debian-12-generic-arm64.tar.xz'; return (debianBase + file, debianBase + 'SHA512SUMS'); case ZionRootfsDistro.alpine: if (arch != 'arm64') throw UnsupportedError('Alpine rootfs الحالي مثبت كـ aarch64 فقط.'); const file = 'alpine-minirootfs-3.24.2-aarch64.tar.gz'; return (alpineBase + file, alpineBase + file + '.sha256'); case ZionRootfsDistro.kali: final suffix = arch == 'armhf' ? 'armhf' : 'arm64'; final file = 'kali-nethunter-rootfs-minimal-' + suffix + '.tar.xz'; return (kaliBase + file, kaliBase + 'SHA256SUMS'); } }
  Future<String?> _expectedDigest(Uri checksumUri, String fileName) async { final response = await http.get(checksumUri); if (response.statusCode != 200) return null; final text = utf8.decode(response.bodyBytes); final line = text.split(RegExp(r'\r?\n')).firstWhere((line) => line.contains(fileName), orElse: () => ''); if (line.isEmpty) return null; return RegExp(r'([a-fA-F0-9]{64})').firstMatch(line)?.group(1)?.toLowerCase(); }
  Future<RootfsInstallResult> install(ZionRootfsDistro distro, {bool force = false}) async {
    final rootfs = await _rootfsDir(); final target = Directory(rootfs.path + '/' + distro.name); if (await target.exists() && !force) return RootfsInstallResult(success: true, message: distro.name + ' موجودة فعلاً.', path: target.path);
    final source = _source(distro); final uri = Uri.parse(source.$1); final fileName = uri.pathSegments.last; final digest = await _expectedDigest(Uri.parse(source.$2), fileName); if (digest == null) return RootfsInstallResult(success: false, message: 'تعذر الحصول على checksum الرسمي لـ ' + fileName + '؛ لم يتم التثبيت.');
    final support = await getApplicationSupportDirectory(); final temp = Directory(support.path + '/.rootfs-' + distro.name + '-' + DateTime.now().microsecondsSinceEpoch.toString()); await temp.create(recursive: true);
    try {
      final response = await http.get(uri, headers: {'Accept': 'application/octet-stream'}); if (response.statusCode != 200) return RootfsInstallResult(success: false, message: 'فشل تنزيل ' + fileName + ': HTTP ' + response.statusCode.toString() + '.');
      final archiveFile = File(temp.path + '/' + fileName); await archiveFile.writeAsBytes(response.bodyBytes, flush: true); final actual = sha256.convert(await archiveFile.readAsBytes()).toString(); if (actual != digest) return const RootfsInstallResult(success: false, message: 'فشل تحقق checksum الرسمي للـ rootfs.');
      final staging = Directory(temp.path + '/staging'); await staging.create(recursive: true); await extractFileToDisk(archiveFile.path, staging.path);
      final entries = staging.listSync(followLinks: false); final sourceDir = entries.length == 1 && entries.first is Directory ? entries.first as Directory : staging; try { await target.delete(recursive: true); } catch (_) {}
      if (sourceDir.path == staging.path) { await Directory(target.path).create(recursive: true); for (final entity in staging.listSync(followLinks: false)) { await entity.rename(target.path + '/' + entity.uri.pathSegments.last); } try { await staging.delete(recursive: true); } catch (_) {} } else { await sourceDir.rename(target.path); }
      await File(target.path + '/.zion-rootfs.json').writeAsString(jsonEncode({'distro': distro.name, 'archive': fileName, 'sha256': digest}), flush: true);
      return RootfsInstallResult(success: true, message: 'تم تنزيل واستخراج ' + distro.name + ' والتحقق منه.', path: target.path);
    } finally { try { await temp.delete(recursive: true); } catch (_) {} }
  }
}