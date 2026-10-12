import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../userland/zion_bootstrap.dart';

class ProotInstallResult {
  const ProotInstallResult({
    required this.success,
    required this.message,
    this.path,
  });

  final bool success;
  final String message;
  final String? path;
}

class ProotInstaller {
  static const _owner = 'proot-me';
  static const _repo = 'proot-rs';
  static const _version = 'v0.1.0';
  static const _requestTimeout = Duration(seconds: 15);
  static const _downloadTimeout = Duration(seconds: 90);

  // GitHub's API does not expose digests for this legacy upstream release.
  // Pin the published asset sizes and still prefer SHA-256 whenever supplied.
  static const Map<String, int> _assetSizes = <String, int>{
    'proot-rs-v0.1.0-aarch64-linux-android.tar.gz': 633839,
    'proot-rs-v0.1.0-arm-linux-androideabi.tar.gz': 642504,
    'proot-rs-v0.1.0-x86_64-linux-android.tar.gz': 737732,
    'proot-rs-v0.1.0-i686-linux-android.tar.gz': 768156,
  };

  Future<Directory> _prefix() async {
    final prefix = Directory(ZionBootstrap.prefix);
    await Directory(prefix.path + '/bin').create(recursive: true);
    return prefix;
  }

  String _assetName() {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) {
      return 'proot-rs-v0.1.0-aarch64-linux-android.tar.gz';
    }
    if (abi == Abi.androidArm) {
      return 'proot-rs-v0.1.0-arm-linux-androideabi.tar.gz';
    }
    if (abi == Abi.androidX64) {
      return 'proot-rs-v0.1.0-x86_64-linux-android.tar.gz';
    }
    if (abi == Abi.androidIA32) {
      return 'proot-rs-v0.1.0-i686-linux-android.tar.gz';
    }
    throw UnsupportedError('Android ABI غير مدعوم: ' + abi.toString());
  }

  Map<String, String> _runtimeEnvironment() => <String, String>{
        ...Platform.environment,
        'HOME': ZionBootstrap.home,
        'PREFIX': ZionBootstrap.prefix,
        'PATH': ZionBootstrap.prefix +
            '/bin:' +
            ZionBootstrap.prefix +
            '/sbin:/system/bin:/system/xbin',
        'LD_LIBRARY_PATH': ZionBootstrap.prefix +
            '/lib:' +
            ZionBootstrap.prefix +
            '/lib64',
      };

  Future<String?> _releaseDigest(String assetName) async {
    final expectedSize = _assetSizes[assetName];
    if (expectedSize == null) return null;
    final uri = Uri.parse(
      'https://api.github.com/repos/$_owner/$_repo/releases/tags/$_version',
    );
    final response = await http.get(uri, headers: <String, String>{
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'Zion-OS',
    }).timeout(_requestTimeout);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    for (final raw in (json['assets'] as List<dynamic>? ?? const <dynamic>[])) {
      final asset = raw as Map<String, dynamic>;
      if (asset['name'] != assetName) continue;
      if (asset['size'] != expectedSize) return null;
      final digest = asset['digest'] as String?;
      if (digest == null || digest.isEmpty) {
        // This upstream release predates GitHub's asset digest metadata.
        // The fixed version URL, pinned asset size, TLS and post-extraction
        // executable probe provide a fail-closed fallback until upstream
        // publishes a SHA-256 digest.
        return 'size:$expectedSize';
      }
      if (!digest.startsWith('sha256:')) return null;
      final value = digest.substring(7).toLowerCase();
      return RegExp(r'^[a-f0-9]{64}$').hasMatch(value) ? value : null;
    }
    return null;
  }

  Future<bool> _isRunnable(File executable) async {
    try {
      final stat = await executable.stat();
      if (stat.type != FileSystemEntityType.file || (stat.mode & 0x49) == 0) {
        return false;
      }
      final result = await Process.run(
        executable.path,
        const <String>['--version'],
        runInShell: false,
        environment: _runtimeEnvironment(),
      ).timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<ProotInstallResult> install({bool force = false}) async {
    Directory? temp;
    final prefix = await _prefix();
    final target = File(prefix.path + '/bin/proot');
    final backup = File(prefix.path + '/bin/.proot.previous');
    try {
      if (await target.exists() && !force && await _isRunnable(target)) {
        return ProotInstallResult(
          success: true,
          message: 'PRoot موجود وتم التحقق من تشغيله.',
          path: target.path,
        );
      }

      final assetName = _assetName();
      final digest = await _releaseDigest(assetName);
      if (digest == null) {
        return const ProotInstallResult(
          success: false,
          message: 'تعذر الحصول على SHA-256 موثوق من GitHub Release؛ لم يتم استبدال PRoot.',
        );
      }

      temp = Directory(
        prefix.path +
            '/.proot-install-' +
            DateTime.now().microsecondsSinceEpoch.toString(),
      );
      await temp.create(recursive: true);
      final response = await http.get(
        Uri.parse(
          'https://github.com/$_owner/$_repo/releases/download/$_version/$assetName',
        ),
        headers: <String, String>{
          'Accept': 'application/octet-stream',
          'User-Agent': 'Zion-OS',
        },
      ).timeout(_downloadTimeout);
      if (response.statusCode != 200) {
        return ProotInstallResult(
          success: false,
          message: 'فشل تنزيل PRoot: HTTP ${response.statusCode}؛ لم يتم استبدال النسخة الحالية.',
        );
      }

      final archiveFile = File(temp.path + '/' + assetName);
      await archiveFile.writeAsBytes(response.bodyBytes, flush: true);
      final archiveBytes = await archiveFile.readAsBytes();
      if (digest.startsWith('size:')) {
        final expectedSize = int.tryParse(digest.substring(5));
        if (expectedSize == null || archiveBytes.length != expectedSize) {
          return const ProotInstallResult(
            success: false,
            message: 'حجم ملف PRoot لا يطابق الحجم المثبت للإصدار؛ لم يتم استبدال النسخة الحالية.',
          );
        }
      } else {
        final actual = sha256.convert(archiveBytes).toString();
        if (actual != digest) {
          return const ProotInstallResult(
            success: false,
            message: 'فشل تحقق SHA-256 لـ PRoot؛ لم يتم استبدال النسخة الحالية.',
          );
        }
      }

      final extractDir = Directory(temp.path + '/extract');
      await extractFileToDisk(archiveFile.path, extractDir.path);
      File? binary;
      await for (final entity
          in extractDir.list(recursive: true, followLinks: false)) {
        if (entity is File &&
            (entity.uri.pathSegments.last == 'proot' ||
                entity.uri.pathSegments.last == 'proot-rs')) {
          binary = entity;
          break;
        }
      }
      if (binary == null) {
        return const ProotInstallResult(
          success: false,
          message: 'لم يُعثر على executable proot داخل الإصدار.',
        );
      }

      final staged = File(prefix.path + '/bin/.proot.new');
      if (await staged.exists()) await staged.delete();
      await binary.copy(staged.path);
      final chmod = await Process.run(
        '/system/bin/chmod',
        <String>['700', staged.path],
        runInShell: false,
      );
      if (chmod.exitCode != 0 || !await _isRunnable(staged)) {
        try {
          await staged.delete();
        } catch (_) {}
        return ProotInstallResult(
          success: false,
          message: 'فشل اختبار تشغيل PRoot بعد التنزيل: ${chmod.stderr}',
        );
      }

      var movedPrevious = false;
      if (await backup.exists()) await backup.delete();
      if (await target.exists()) {
        await target.rename(backup.path);
        movedPrevious = true;
      }
      try {
        await staged.rename(target.path);
        if (!await _isRunnable(target)) {
          throw StateError('اختبار --version فشل بعد تفعيل PRoot.');
        }
      } catch (error) {
        try {
          if (await target.exists()) await target.delete();
        } catch (_) {}
        if (movedPrevious && await backup.exists()) {
          try {
            await backup.rename(target.path);
          } catch (_) {}
        }
        return ProotInstallResult(
          success: false,
          message: 'تعذر تفعيل PRoot؛ تمت محاولة استعادة النسخة السابقة: $error',
        );
      }

      if (movedPrevious && await backup.exists()) {
        try {
          await backup.delete();
        } catch (_) {}
      }
      return ProotInstallResult(
        success: true,
        message: 'تم تثبيت PRoot والتحقق من تشغيله.',
        path: target.path,
      );
    } catch (error) {
      return ProotInstallResult(
        success: false,
        message: 'تعذر تثبيت PRoot: $error',
      );
    } finally {
      if (temp != null) {
        try {
          if (await temp.exists()) await temp.delete(recursive: true);
        } catch (_) {}
      }
    }
  }
}
