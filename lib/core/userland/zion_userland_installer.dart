import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'zion_bootstrap.dart';

class ZionUserlandInstallResult {
  const ZionUserlandInstallResult({required this.success, required this.message, this.releaseTag});
  final bool success;
  final String message;
  final String? releaseTag;
}

class ZionUserlandInstaller {
  static const _repo = 'almwld/Zion_OS_New';
  static const _assetName = 'bootstrap-aarch64.zip';
  static const _maxBytes = 80 * 1024 * 1024;

  const ZionUserlandInstaller();

  Future<ZionUserlandInstallResult> installLatest({void Function(String message)? onProgress}) async {
    if (await ZionBootstrap.isInstalled()) {
      return const ZionUserlandInstallResult(success: true, message: 'Zion Userland موجود بالفعل.');
    }
    if (Abi.current() != Abi.androidArm64) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'إصدار Zion Userland الحالي متوفر لـ arm64 فقط؛ ABI الحالي: ' + Abi.current().toString(),
      );
    }

    final client = http.Client();
    final tempDir = Directory(
      ZionBootstrap.base + '/.userland-download-' + DateTime.now().microsecondsSinceEpoch.toString(),
    );
    try {
      onProgress?.call('البحث عن أحدث Zion Userland...');
      final releaseResponse = await client.get(
        Uri.parse('https://api.github.com/repos/' + _repo + '/releases/latest'),
        headers: const {'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2026-03-10'},
      );
      if (releaseResponse.statusCode != 200) {
        return ZionUserlandInstallResult(success: false, message: 'تعذر الوصول إلى إصدار Zion Userland: HTTP ' + releaseResponse.statusCode.toString() + '.');
      }

      final release = jsonDecode(releaseResponse.body);
      if (release is! Map) return const ZionUserlandInstallResult(success: false, message: 'استجابة إصدار Zion Userland غير صالحة.');
      final tag = release['tag_name']?.toString();
      final assets = release['assets'];
      if (assets is! List) return const ZionUserlandInstallResult(success: false, message: 'إصدار Zion Userland لا يحتوي على قائمة ملفات صالحة.');

      Map<String, dynamic>? asset;
      for (final raw in assets) {
        if (raw is Map && raw['name']?.toString() == _assetName) {
          asset = Map<String, dynamic>.from(raw);
          break;
        }
      }
      if (asset == null) {
        return const ZionUserlandInstallResult(
          success: false,
          message: 'لم يتم نشر bootstrap-aarch64.zip بعد. يلزم إكمال بناء Zion Userland أولاً.',
        );
      }

      final downloadUrl = asset['browser_download_url']?.toString();
      final digest = asset['digest']?.toString();
      final size = int.tryParse(asset['size']?.toString() ?? '');
      if (downloadUrl == null || downloadUrl.isEmpty) return const ZionUserlandInstallResult(success: false, message: 'رابط Zion Userland غير صالح.');
      if (size != null && size > _maxBytes) return const ZionUserlandInstallResult(success: false, message: 'حجم Zion Userland يتجاوز الحد المسموح.');
      if (digest == null || !digest.startsWith('sha256:')) return const ZionUserlandInstallResult(success: false, message: 'إصدار Zion Userland لا يحتوي SHA-256 موثوقاً.');

      await tempDir.create(recursive: true);
      final archiveFile = File(tempDir.path + '/' + _assetName);
      onProgress?.call('تنزيل Zion Userland ' + (tag ?? '') + '...');
      final response = await client.send(http.Request('GET', Uri.parse(downloadUrl)));
      if (response.statusCode != 200) return ZionUserlandInstallResult(success: false, message: 'فشل تنزيل Zion Userland: HTTP ' + response.statusCode.toString() + '.');

      final sink = archiveFile.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          if (received > _maxBytes) {
            await sink.close();
            return const ZionUserlandInstallResult(success: false, message: 'ملف Zion Userland تجاوز الحد المسموح أثناء التنزيل.');
          }
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }

      onProgress?.call('التحقق من SHA-256...');
      final actual = (await sha256.bind(archiveFile.openRead()).first).toString();
      final expected = digest.substring('sha256:'.length);
      if (actual.toLowerCase() != expected.toLowerCase()) return const ZionUserlandInstallResult(success: false, message: 'فشل تحقق SHA-256 لـ Zion Userland.');

      onProgress?.call('استخراج Zion Userland...');
      final archive = ZipDecoder().decodeBytes(await archiveFile.readAsBytes(), verify: true);
      final staging = Directory(tempDir.path + '/staging');
      final prefix = Directory(staging.path + '/usr');
      await prefix.create(recursive: true);

      final symlinks = <String, String>{};
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        var name = entry.name.replaceAll('\\\\', '/');
        while (name.startsWith('./')) name = name.substring(2);
        if (name.isEmpty) continue;
        if (name == 'SYMLINKS.txt') {
          final lines = utf8.decode(List<int>.from(entry.content as List<int>), allowMalformed: false).split(RegExp(r'\r?\n'));
          for (final line in lines) {
            final separator = line.indexOf('←');
            if (separator > 0 && separator < line.length - 1) {
              symlinks[line.substring(separator + 1)] = line.substring(0, separator);
            }
          }
          continue;
        }
        if (name.startsWith('/') || name.split('/').any((part) => part.isEmpty || part == '.' || part == '..')) {
          throw const FormatException('مسار غير آمن داخل bootstrap.');
        }
        final target = File(prefix.path + '/' + name);
        await target.parent.create(recursive: true);
        await target.writeAsBytes(List<int>.from(entry.content as List<int>), flush: true);
      }

      for (final entry in symlinks.entries) {
        final linkName = entry.key;
        final targetName = entry.value;
        if (linkName.startsWith('/') || targetName.startsWith('/') ||
            linkName.split('/').any((part) => part.isEmpty || part == '.' || part == '..') ||
            targetName.split('/').any((part) => part.isEmpty || part == '.' || part == '..')) {
          throw const FormatException('Symlink غير آمن داخل bootstrap.');
        }
        final link = Link(prefix.path + '/' + linkName);
        await link.parent.create(recursive: true);
        if (await File(link.path).exists() || await Directory(link.path).exists()) continue;
        await link.create(targetName, recursive: false);
      }

      final releaseFile = File(prefix.path + '/etc/zion-release.json');
      await releaseFile.parent.create(recursive: true);
      await releaseFile.writeAsString(
        jsonEncode({
          'format': 'zion-userland-v1',
          'release': tag ?? 'unknown',
          'source': 'TERMUX_PACKAGE_BUILD_SYSTEM',
          'installedAt': DateTime.now().toUtc().toIso8601String(),
          'bootstrapSha256': actual,
        }),
        flush: true,
      );

      final current = Directory(ZionBootstrap.prefix);
      final backup = Directory(ZionBootstrap.base + '/.usr-previous-' + DateTime.now().microsecondsSinceEpoch.toString());
      if (await current.exists()) await current.rename(backup.path);
      try {
        await prefix.rename(current.path);
        if (await backup.exists()) await backup.delete(recursive: true);
      } catch (_) {
        if (!await current.exists() && await backup.exists()) await backup.rename(current.path);
        rethrow;
      }

      if (!await File(ZionBootstrap.prefix + '/etc/zion-release.json').exists()) {
        throw const FileSystemException('Zion Userland marker was not created.');
      }
      return ZionUserlandInstallResult(success: true, message: 'تم تثبيت Zion Userland بنجاح.', releaseTag: tag);
    } catch (e) {
      return ZionUserlandInstallResult(success: false, message: 'فشل تثبيت Zion Userland: ' + e.toString());
    } finally {
      client.close();
      try {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }
}
