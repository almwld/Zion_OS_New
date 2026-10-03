import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'local_kali_config.dart';

enum ZionKaliInstallState {
  notFound,
  found,
  copying,
  verifying,
  decompressing,
  extracting,
  fixing,
  ready,
  error,
}

class ZionKaliProgress {
  const ZionKaliProgress(this.state, this.percent, this.message);
  final ZionKaliInstallState state;
  final int percent;
  final String message;
}

class ZionLocalKaliBootstrap {
  const ZionLocalKaliBootstrap();

  static const _storage = MethodChannel('zion.os/storage');
  static const _localKali = MethodChannel('zion.os/local-kali');

  Future<Directory> _filesDir() => getApplicationSupportDirectory();

  Future<File?> findLocalPackage() async {
    for (final path in ZionLocalKaliConfig.searchPaths) {
      final file = File('$path/${ZionLocalKaliConfig.expectedFilename}');
      try {
        if (await file.exists()) return file;
      } catch (_) {}
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> discoverPackages() async {
    try {
      final result = await _localKali.invokeMethod<List<dynamic>>(
        'discoverKaliPackage',
        <String, Object>{'filename': ZionLocalKaliConfig.expectedFilename},
      );
      return (result ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<ZionKaliInstallState> state() async {
    final filesDir = await _filesDir();
    final file = ZionLocalKaliConfig.stateFile(filesDir);
    if (!await file.exists()) return ZionKaliInstallState.notFound;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (json['state'] == 'READY' &&
          json['sha256'] == ZionLocalKaliConfig.expectedSha256 &&
          await ZionLocalKaliConfig.rootfs(filesDir).exists()) {
        return ZionKaliInstallState.ready;
      }
    } catch (_) {}
    return ZionKaliInstallState.error;
  }

  Future<Result<Directory>> install({
    void Function(ZionKaliProgress progress)? onProgress,
  }) async {
    final filesDir = await _filesDir();
    final downloads = ZionLocalKaliConfig.downloads(filesDir);
    final userland = ZionLocalKaliConfig.userland(filesDir);
    await downloads.create(recursive: true);
    await userland.create(recursive: true);
    await ZionLocalKaliConfig.logs(filesDir).create(recursive: true);

    void progress(ZionKaliInstallState state, int percent, String message) {
      onProgress?.call(ZionKaliProgress(state, percent.clamp(0, 100), message));
    }

    try {
      final direct = await findLocalPackage();
      final discovered = direct == null ? await discoverPackages() : const <Map<String, dynamic>>[];
      if (direct == null && discovered.isEmpty) {
        progress(ZionKaliInstallState.notFound, 0,
            'لم يتم العثور على حزمة Kali المحلية.');
        await _saveState(filesDir, 'NOT_FOUND');
        return Result.failure(StateError(
          'Missing ${ZionLocalKaliConfig.expectedFilename}',
        ));
      }

      final internal = File(
        '${downloads.path}/${ZionLocalKaliConfig.expectedFilename}',
      );
      progress(ZionKaliInstallState.copying, 0,
          'نسخ حزمة Kali إلى مساحة Zion الخاصة...');
      if (direct != null) {
        await _copyFileWithProgress(direct, internal, (p) {
          progress(ZionKaliInstallState.copying, p, 'نسخ الحزمة...');
        });
      } else {
        await _storage.invokeMethod<void>('copyDocumentToPrivate', <String, Object>{
          'uri': discovered.first['uri'] as String,
          'destination': internal.path,
        });
        progress(ZionKaliInstallState.copying, 100, 'تم نسخ الحزمة.');
      }

      final size = await internal.length();
      if (size != ZionLocalKaliConfig.expectedSize) {
        throw StateError(
          'حجم Kali غير صحيح: $size، المتوقع ${ZionLocalKaliConfig.expectedSize}.',
        );
      }

      progress(ZionKaliInstallState.verifying, 0, 'التحقق من SHA-256...');
      final digest = await _sha256(internal);
      if (digest != ZionLocalKaliConfig.expectedSha256) {
        throw SecurityException('SHA-256 mismatch: $digest');
      }
      progress(ZionKaliInstallState.verifying, 100, 'SHA-256 صحيح.');

      final rootfs = ZionLocalKaliConfig.rootfs(filesDir);
      if (await rootfs.exists()) await rootfs.delete(recursive: true);
      await rootfs.create(recursive: true);

      progress(ZionKaliInstallState.decompressing, 10, 'فك ضغط tar.xz...');
      final tarPath = '${downloads.path}/kali-arm64.tar';
      final input = InputFileStream(internal.path);
      final output = OutputFileStream(tarPath);
      try {
        XZDecoder().decodeStream(input, output, verify: true, throwOnError: true);
      } finally {
        await input.close();
        await output.close();
      }
      progress(ZionKaliInstallState.decompressing, 100, 'تم فك ضغط xz.');

      progress(ZionKaliInstallState.extracting, 0, 'استخراج rootfs...');
      final tarInput = InputFileStream(tarPath);
      try {
        final archive = TarDecoder().decodeStream(
          tarInput,
          callback: (entry) {
            final name = entry.name;
            if (name.contains('..') || name.startsWith('/') || name.startsWith(r'\')) {
              throw SecurityException('Unsafe tar path: $name');
            }
          },
        );
        final prefix = '${ZionLocalKaliConfig.rootfsName}/';
        for (var i = 0; i < archive.length; i++) {
          final entry = archive[i];
          if (!entry.name.startsWith(prefix)) continue;
          final relative = entry.name.substring(prefix.length);
          if (relative.isEmpty) continue;
          final destination = File('${rootfs.path}/$relative');
          if (!destination.absolute.path.startsWith('${rootfs.absolute.path}/')) {
            throw SecurityException('Tar traversal: ${entry.name}');
          }
          if (entry.isDirectory) {
            await destination.create(recursive: true);
          } else if (entry.isSymbolicLink) {
            await destination.parent.create(recursive: true);
            try { await Link(destination.path).delete(); } catch (_) {}
            await Link(destination.path).create(entry.symbolicLink);
          } else if (entry.isFile) {
            if (relative == 'dev' || relative.startsWith('dev/')) continue;
            await destination.parent.create(recursive: true);
            await destination.writeAsBytes(entry.content, flush: false);
          }
          if (i % 250 == 0) {
            progress(
              ZionKaliInstallState.extracting,
              ((i + 1) * 100 / archive.length).round(),
              'استخراج $relative',
            );
          }
        }
      } finally {
        await tarInput.close();
      }

      progress(ZionKaliInstallState.fixing, 0, 'إصلاح rootfs...');
      await _fixupRootfs(rootfs);
      progress(ZionKaliInstallState.fixing, 100, 'تم إصلاح rootfs.');

      await _saveState(filesDir, 'READY', extra: <String, Object>{
        'sha256': ZionLocalKaliConfig.expectedSha256,
        'size_bytes': await _directorySize(rootfs),
        'rootfs_path': 'userland/${ZionLocalKaliConfig.rootfsName}',
      });
      try { await File(tarPath).delete(); } catch (_) {}
      try { await internal.delete(); } catch (_) {}
      progress(ZionKaliInstallState.ready, 100, 'Kali جاهز للتشغيل.');
      return Result.success(rootfs);
    } catch (e) {
      await _saveState(filesDir, 'ERROR', extra: <String, Object>{'error': e.toString()});
      return Result.failure(e);
    }
  }

  Future<void> _fixupRootfs(Directory rootfs) async {
    await Directory('${rootfs.path}/dev').create(recursive: true);

    Future<void> copyIfNeeded(String target, String link) async {
      final t = File('${rootfs.path}/$target');
      final l = File('${rootfs.path}/$link');
      if (await t.exists() && !await l.exists()) {
        await l.parent.create(recursive: true);
        await t.copy(l.path);
      }
    }

    await copyIfNeeded('usr/lib/klibc/bin/zcat', 'usr/lib/klibc/bin/gunzip');
    await copyIfNeeded('usr/lib/klibc/bin/zcat', 'usr/lib/klibc/bin/gzip');
    await copyIfNeeded('usr/lib/klibc/bin/reboot', 'usr/lib/klibc/bin/halt');
    await copyIfNeeded('usr/lib/klibc/bin/reboot', 'usr/lib/klibc/bin/poweroff');
    await copyIfNeeded('usr/bin/perl', 'usr/bin/perl5.40.1');
    await copyIfNeeded('usr/bin/perlbug', 'usr/bin/perlthanks');

    final apt = File('${rootfs.path}/etc/apt/apt.conf.d/99-proot-fix');
    await apt.parent.create(recursive: true);
    await apt.writeAsString(
      'APT::Sandbox::User "root";\n'
      'APT::Sandbox::Seccomp "false";\n'
      'Acquire::Retries "3";\n'
      'DPkg::Use-Pty "false";\n',
    );

    final resolv = File('${rootfs.path}/etc/resolv.conf');
    await resolv.parent.create(recursive: true);
    await resolv.writeAsString('nameserver 8.8.8.8\nnameserver 1.1.1.1\n');
    await File('${rootfs.path}/root/.hushlogin').create(recursive: true);
  }

  Future<void> _copyFileWithProgress(File source, File destination, void Function(int) onProgress) async {
    final total = await source.length();
    var copied = 0;
    await destination.parent.create(recursive: true);
    final sink = destination.openWrite();
    try {
      await for (final chunk in source.openRead()) {
        sink.add(chunk);
        copied += chunk.length;
        onProgress(total == 0 ? 100 : (copied * 100 / total).round());
      }
    } finally {
      await sink.close();
    }
  }

  Future<String> _sha256(File file) async => (await sha256.bind(file.openRead()).first).toString();

  Future<int> _directorySize(Directory dir) async {
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> _saveState(Directory filesDir, String state, {Map<String, Object> extra = const <String, Object>{}}) async {
    final file = ZionLocalKaliConfig.stateFile(filesDir);
    await file.parent.create(recursive: true);
    final data = <String, Object>{
      'version': '1.0.0',
      'sha256': ZionLocalKaliConfig.expectedSha256,
      'installed_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'state': state,
      ...extra,
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}

class SecurityException implements Exception {
  SecurityException(this.message);
  final String message;
  @override
  String toString() => message;
}
