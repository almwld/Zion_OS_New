import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../userland/zion_proot.dart';

enum ZionRootfsDistro { ubuntu, debian, alpine, kali }

class RootfsInstallResult {
  const RootfsInstallResult({required this.success, required this.message, this.path});
  final bool success;
  final String message;
  final String? path;
}

class RootfsDownloader {
  static const ubuntuBase = 'https://cloud-images.ubuntu.com/buildd/releases/noble/release/';
  static const debianBase = 'https://cloud.debian.org/images/cloud/bookworm/latest/';
  static const alpineBase = 'https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/aarch64/';
  static const kaliBase = 'https://old.kali.org/nethunter-images/kali-2025.3/rootfs/';

  Future<Directory> _rootfsDir() async {
    // Keep installation and interactive login on the same canonical Zion path.
    final dir = Directory(ZionProot.distroRoot);
    await dir.create(recursive: true);
    return dir;
  }

  String _arch() => 'arm64';

  (String, String) _source(ZionRootfsDistro distro) {
    final arch = _arch();
    switch (distro) {
      case ZionRootfsDistro.ubuntu:
        final suffix = arch == 'armhf' ? 'armhf' : 'arm64';
        final file = 'noble-server-cloudimg-' + suffix + '-root.tar.gz';
        return (ubuntuBase + file, ubuntuBase + 'SHA256SUMS');
      case ZionRootfsDistro.debian:
        if (arch != 'arm64') throw UnsupportedError('Debian rootfs الحالي مثبت كـ arm64 فقط.');
        const file = 'debian-12-generic-arm64.tar.xz';
        return (debianBase + file, debianBase + 'SHA512SUMS');
      case ZionRootfsDistro.alpine:
        if (arch != 'arm64') throw UnsupportedError('Alpine rootfs الحالي مثبت كـ aarch64 فقط.');
        const file = 'alpine-minirootfs-3.24.2-aarch64.tar.gz';
        return (alpineBase + file, alpineBase + file + '.sha256');
      case ZionRootfsDistro.kali:
        final suffix = arch == 'armhf' ? 'armhf' : 'arm64';
        final file = 'kali-nethunter-rootfs-minimal-' + suffix + '.tar.xz';
        return (kaliBase + file, kaliBase + 'SHA256SUMS');
    }
  }

  Future<(String algorithm, String digest)?> _expectedChecksum(
    Uri checksumUri,
    String fileName,
  ) async {
    final response = await http.get(checksumUri);
    if (response.statusCode != 200) return null;
    final text = utf8.decode(response.bodyBytes);
    final line = text
        .split(RegExp(r'\r?\n'))
        .firstWhere((line) => line.contains(fileName), orElse: () => '');
    return parseChecksumLine(line, fileName);
  }

  static (String algorithm, String digest)? parseChecksumLine(
    String line,
    String fileName,
  ) {
    if (!line.contains(fileName)) return null;
    // Match SHA-512 first: otherwise the 64-character alternative consumes
    // the prefix of a 128-character digest and misclassifies it as SHA-256.
    final match = RegExp(r'([a-fA-F0-9]{128}|[a-fA-F0-9]{64})').firstMatch(line);
    if (match == null) return null;
    final digest = match.group(1)!.toLowerCase();
    return digest.length == 128 ? ('sha512', digest) : ('sha256', digest);
  }

  Future<String> _hashFile(File file, String algorithm) async {
    final stream = file.openRead();
    final digest = algorithm == 'sha512'
        ? await sha512.bind(stream).first
        : await sha256.bind(stream).first;
    return digest.toString();
  }

  Future<bool> _downloadToFile(Uri uri, File destination) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'application/octet-stream';
      final response = await client.send(request);
      if (response.statusCode != 200) return false;
      final sink = destination.openWrite();
      try {
        await response.stream.pipe(sink);
      } catch (_) {
        await sink.close();
        rethrow;
      }
      return true;
    } finally {
      client.close();
    }
  }

  Future<RootfsInstallResult> install(
    ZionRootfsDistro distro, {
    bool force = false,
  }) async {
    if (Abi.current() != Abi.androidArm64) {
      return const RootfsInstallResult(
        success: false,
        message: 'تثبيت توزيعات Linux في Zion Userland متاح حاليًا لأجهزة ARM64 فقط.',
      );
    }
    final rootfs = await _rootfsDir();
    final target = Directory(rootfs.path + '/' + distro.name);
    final installedRoot = Directory(target.path + '/rootfs');
    if (await installedRoot.exists() && !force &&
        await File(target.path + '/.zion-rootfs.json').exists()) {
      return RootfsInstallResult(success: true, message: distro.name + ' موجودة فعلاً.', path: installedRoot.path);
    }

    final source = _source(distro);
    final uri = Uri.parse(source.$1);
    final fileName = uri.pathSegments.last;
    final checksum = await _expectedChecksum(Uri.parse(source.$2), fileName);
    if (checksum == null) {
      return RootfsInstallResult(
        success: false,
        message: 'تعذر الحصول على checksum الرسمي لـ ' + fileName + '؛ لم يتم التثبيت.',
      );
    }

    final support = await getApplicationSupportDirectory();
    final temp = Directory(support.path + '/.rootfs-' + distro.name + '-' + DateTime.now().microsecondsSinceEpoch.toString());
    await temp.create(recursive: true);
    try {
      final archiveFile = File(temp.path + '/' + fileName);
      if (!await _downloadToFile(uri, archiveFile)) {
        return RootfsInstallResult(success: false, message: 'فشل تنزيل ' + fileName + '.');
      }
      final actual = await _hashFile(archiveFile, checksum.$1);
      if (actual != checksum.$2) {
        return const RootfsInstallResult(success: false, message: 'فشل تحقق checksum الرسمي للـ rootfs.');
      }

      final staging = Directory(temp.path + '/staging');
      await staging.create(recursive: true);
      await extractFileToDisk(archiveFile.path, staging.path);
      final entries = staging.listSync(followLinks: false);
      final sourceDir = entries.length == 1 && entries.first is Directory ? entries.first as Directory : staging;
      if (!await File(sourceDir.path + '/bin/sh').exists()) {
        return RootfsInstallResult(
          success: false,
          message: 'الأرشيف الذي تم التحقق منه لا يحتوي على /bin/sh؛ تم الحفاظ على النظام المثبت سابقاً.',
        );
      }

      final backup = Directory(
        rootfs.path + '/.' + distro.name + '.backup-' +
            DateTime.now().microsecondsSinceEpoch.toString(),
      );
      var movedPrevious = false;
      var newTargetCreated = false;
      final rootfsTarget = Directory(target.path + '/rootfs');
      try {
        if (await target.exists()) {
          await target.rename(backup.path);
          movedPrevious = true;
        }
        newTargetCreated = true;
        await target.create(recursive: true);
        await sourceDir.rename(rootfsTarget.path);
        await File(target.path + '/.zion-rootfs.json').writeAsString(
          jsonEncode({'distro': distro.name, 'archive': fileName, checksum.$1: checksum.$2}),
          flush: true,
        );
      } catch (error) {
        if (newTargetCreated && await target.exists()) {
          try { await target.delete(recursive: true); } catch (_) {}
        }
        if (movedPrevious && await backup.exists()) {
          try { await backup.rename(target.path); } catch (_) {}
        }
        return RootfsInstallResult(
          success: false,
          message: 'تعذر تفعيل rootfs الجديد؛ تمت محاولة استعادة النسخة السابقة: ' + error.toString(),
        );
      }
      if (movedPrevious && await backup.exists()) {
        try { await backup.delete(recursive: true); } catch (_) {}
      }
      return RootfsInstallResult(success: true, message: 'تم تنزيل واستخراج ' + distro.name + ' والتحقق منه.', path: rootfsTarget.path);
    } finally {
      try { await temp.delete(recursive: true); } catch (_) {}
    }
  }
}
