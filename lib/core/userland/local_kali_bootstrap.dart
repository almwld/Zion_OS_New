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
          await File('${ZionLocalKaliConfig.rootfs(filesDir).path}/bin/bash').exists() &&
          await File('${ZionLocalKaliConfig.rootfs(filesDir).path}/bin/sh').exists()) {
        return ZionKaliInstallState.ready;
      }
    } catch (_) {}
    return ZionKaliInstallState.error;
  }

  Future<ZionKaliInstallResult> install({
    void Function(ZionKaliProgress progress)? onProgress,
    bool manualImport = false,
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
      final direct = manualImport ? null : await findLocalPackage();
      var discovered = direct == null && !manualImport
          ? await discoverPackages()
          : const <Map<String, dynamic>>[];
      if (manualImport || (direct == null && discovered.isEmpty)) {
        try {
          final picked = await _storage.invokeMethod<Map<dynamic, dynamic>>('pickKaliPackage');
          final pickedMap = picked == null ? null : Map<String, dynamic>.from(picked);
          if (pickedMap?['available'] == true && pickedMap?['uri'] is String) {
            discovered = <Map<String, dynamic>>[
              <String, dynamic>{'uri': pickedMap!['uri'], 'name': pickedMap['name']?.toString() ?? 'kali-rootfs.archive'},
            ];
          }
        } catch (error) {
          if (manualImport) throw StateError('تعذر فتح منتقي أرشيف Kali: $error');
        }
      }
      if (direct == null && discovered.isEmpty) {
        progress(ZionKaliInstallState.notFound, 0,
            'لم يتم العثور على حزمة Kali المحلية.');
        await _saveState(filesDir, 'NOT_FOUND');
        return ZionKaliInstallResult.failure(StateError(
          'Missing ${ZionLocalKaliConfig.expectedFilename}',
        ));
      }

      final selectedName = discovered.isNotEmpty
          ? (discovered.first['name']?.toString() ?? 'kali-rootfs.archive')
          : ZionLocalKaliConfig.expectedFilename;
      final safeName = _safeArchiveFilename(selectedName);
      final internal = File(
        '${downloads.path}/import-${DateTime.now().microsecondsSinceEpoch}-$safeName',
      );
      progress(ZionKaliInstallState.copying, 0,
          'نسخ حزمة Kali إلى مساحة Zion الخاصة...');
      var copied = false;
      Object? directCopyError;
      if (direct != null) {
        try {
          await _copyFileWithProgress(direct, internal, (p) {
            progress(ZionKaliInstallState.copying, p, 'نسخ الحزمة...');
          });
          copied = true;
        } catch (error) {
          // File.exists() can succeed for a shared-storage path while Android
          // denies direct reads under scoped storage. Retry through ACTION_OPEN_DOCUMENT
          // and ContentResolver rather than failing the install immediately.
          directCopyError = error;
          progress(
            ZionKaliInstallState.copying,
            0,
            'تعذر الوصول المباشر إلى Download؛ طلب إذن قراءة آمن عبر منتقي الملفات...',
          );
        }
      } else if (discovered.isNotEmpty && discovered.first['uri'] is String) {
        final result = await _storage.invokeMethod<bool>(
          'copyDocumentToPrivate',
          <String, Object>{
            'uri': discovered.first['uri'] as String,
            'destination': internal.path,
          },
        );
        copied = result == true;
      }

      if (!copied) {
        Map<String, dynamic>? picked;
        try {
          final response = await _storage.invokeMethod<Map<dynamic, dynamic>>(
            'pickKaliPackage',
          );
          if (response != null) picked = Map<String, dynamic>.from(response);
        } catch (error) {
          if (directCopyError == null) directCopyError = error;
        }
        if (picked?['available'] == true && picked?['uri'] is String) {
          final result = await _storage.invokeMethod<bool>(
            'copyDocumentToPrivate',
            <String, Object>{
              'uri': picked!['uri'] as String,
              'destination': internal.path,
            },
          );
          copied = result == true;
        }
      }
      if (!copied) {
        throw StateError(
          'تعذر نسخ أرشيف Kali إلى مساحة Zion الخاصة. '
          'امنح التطبيق حق اختيار الملف عبر منتقي Android ثم أعد المحاولة.'
          '${directCopyError == null ? '' : ' تفاصيل الوصول المباشر: $directCopyError'}',
        );
      }
      progress(ZionKaliInstallState.copying, 100, 'تم نسخ الحزمة إلى مساحة Zion الخاصة.');

      final size = await internal.length();
      if (size <= 0) throw StateError('أرشيف Kali فارغ.');
      final digest = await _sha256(internal);
      if (selectedName == ZionLocalKaliConfig.expectedFilename) {
        if (size != ZionLocalKaliConfig.expectedSize) {
          throw StateError('حجم حزمة Kali الرسمية غير صحيح: $size.');
        }
        if (digest != ZionLocalKaliConfig.expectedSha256) {
          throw SecurityException('SHA-256 mismatch: $digest');
        }
      }
      progress(ZionKaliInstallState.verifying, 100, 'اكتمل التحقق من الأرشيف.');

      final targetRootfs = ZionLocalKaliConfig.rootfs(filesDir);
      await targetRootfs.parent.create(recursive: true);
      final rootfs = Directory(
        targetRootfs.path + '.staging-' +
            DateTime.now().microsecondsSinceEpoch.toString(),
      );
      await rootfs.create(recursive: true);

      progress(ZionKaliInstallState.decompressing, 10, 'التعرف على صيغة الأرشيف وفك الضغط...');
      final tarPath = '${downloads.path}/kali-import-${DateTime.now().microsecondsSinceEpoch}.tar';
      final isZip = await _prepareArchiveForExtraction(internal, File(tarPath));
      progress(ZionKaliInstallState.decompressing, 100, 'اكتمل تجهيز الأرشيف.');

      progress(ZionKaliInstallState.extracting, 0, 'اكتشاف جذر Kali واستخراج rootfs...');
      Archive archive;
      if (isZip) {
        final zipInput = InputFileStream(internal.path);
        try {
          archive = ZipDecoder().decodeStream(zipInput);
        } finally {
          await zipInput.close();
        }
      } else {
        final tarInput = InputFileStream(tarPath);
        try {
          archive = TarDecoder().decodeStream(
            tarInput,
            callback: (entry) {
              if (_normalizeArchivePath(entry.name) == null) {
                throw SecurityException('Unsafe archive path: ${entry.name}');
              }
            },
          );
        } finally {
          await tarInput.close();
        }
      }
      if (archive.length > 250000) {
        throw StateError('الأرشيف يتجاوز الحد الآمن لعدد عناصر rootfs.');
      }
      final prefix = _detectRootfsPrefix(archive);
      if (prefix == null) {
        throw StateError('لم يتم العثور على جذر Kali صالح يحتوي bin/bash وbin/sh داخل الأرشيف.');
      }
        final modes = <({String path, int mode})>[];        final modes = <({String path, int mode})>[];
        for (var i = 0; i < archive.length; i++) {
          final entry = archive[i];
          final normalizedName = _normalizeArchivePath(entry.name);
          if (normalizedName == null) {
            throw SecurityException('Unsafe archive path: ${entry.name}');
          }
          if (!normalizedName.startsWith(prefix)) continue;
          final relative = normalizedName.substring(prefix.length);
          if (relative.isEmpty) continue;
          final destination = File('${rootfs.path}/$relative');
          if (!destination.absolute.path.startsWith('${rootfs.absolute.path}/')) {
            throw SecurityException('Tar traversal: ${entry.name}');
          }
          if (entry.isDirectory) {
            // The archive entry is a directory: creating it through File.create
            // produces a regular file and makes subsequent child extraction fail.
            await Directory(destination.path).create(recursive: true);
            modes.add((path: destination.path, mode: entry.unixPermissions & 0x1ff));
          } else if (entry.isSymbolicLink) {
            final target = entry.symbolicLink ?? '';
            if (!_isSafeLinkTarget(relative, target)) {
              throw SecurityException('Unsafe symbolic link in Kali archive: $relative -> $target');
            }
            await destination.parent.create(recursive: true);
            try { await Link(destination.path).delete(); } catch (_) {}
            await Link(destination.path).create(target);
          } else if (entry.isFile) {
            if (relative == 'dev' || relative.startsWith('dev/')) continue;
            await destination.parent.create(recursive: true);
            await destination.writeAsBytes(entry.content, flush: false);
            modes.add((path: destination.path, mode: entry.unixPermissions & 0x1ff));
          }
          if (i % 250 == 0) {
            progress(
              ZionKaliInstallState.extracting,
              ((i + 1) * 100 / archive.length).round(),
              'استخراج $relative',
            );
          }
        }
        // Restore executable and directory modes from the verified tar archive.
        // Apply in reverse order so parent directories are chmodded only after
        // all child files have been written.
        for (final item in modes.reversed) {
          if (item.mode == 0) continue;
          final chmod = await Process.run(
            '/system/bin/chmod',
            <String>[item.mode.toRadixString(8), item.path],
            runInShell: false,
          );
          if (chmod.exitCode != 0 &&
              (item.path.endsWith('/bin/bash') || item.path.endsWith('/bin/sh'))) {
            throw StateError('تعذر ضبط صلاحيات صدفة Kali: ${item.path}: ${chmod.stderr}');
          }
        }
      } finally {
        await tarInput.close();
      }

      progress(ZionKaliInstallState.fixing, 0, 'إصلاح rootfs...');
      await _fixupRootfs(rootfs);
      await _validateKaliRootfs(rootfs);
      progress(ZionKaliInstallState.fixing, 100, 'تم التحقق من Kali ARM64 وإصلاح rootfs.');

      final oldRootfs = Directory(
        targetRootfs.path + '.old-' +
            DateTime.now().microsecondsSinceEpoch.toString(),
      );
      if (await targetRootfs.exists()) await targetRootfs.rename(oldRootfs.path);
      try {
        await rootfs.rename(targetRootfs.path);
        if (await oldRootfs.exists()) await oldRootfs.delete(recursive: true);
      } catch (_) {
        if (!await targetRootfs.exists() && await oldRootfs.exists()) {
          await oldRootfs.rename(targetRootfs.path);
        }
        rethrow;
      }

      await _saveState(filesDir, 'READY', extra: <String, Object>{
        'archive_sha256': digest,
        'archive_name': selectedName,
        'size_bytes': await _directorySize(targetRootfs),
        'rootfs_path': 'home/.zion/dists/kali/rootfs',
      });
      try { await File(tarPath).delete(); } catch (_) {}
      try { await internal.delete(); } catch (_) {}
      progress(ZionKaliInstallState.ready, 100, 'Kali جاهز للتشغيل.');
      return ZionKaliInstallResult.success(targetRootfs);
    } catch (e) {
      await _saveState(filesDir, 'ERROR', extra: <String, Object>{'error': e.toString()});
      return ZionKaliInstallResult.failure(e);
    }
  }

  Future<void> _validateKaliRootfs(Directory rootfs) async {
    final base = rootfs.path;
    final bash = File('$base/bin/bash');
    final shell = File('$base/bin/sh');
    final env = File('$base/usr/bin/env');
    final osRelease = File('$base/etc/os-release');
    if (!await bash.exists() ||
        !await shell.exists() ||
        !await env.exists() ||
        !await osRelease.exists() ||
        await bash.length() < 100000) {
      throw StateError('الأرشيف لا يحتوي على Kali rootfs كاملاً: يلزم bin/bash وbin/sh وusr/bin/env وetc/os-release.');
    }
    final releaseText = (await osRelease.readAsString()).toLowerCase();
    if (!releaseText.contains('kali')) {
      throw StateError('تم رفض الأرشيف: etc/os-release لا يعرّف نظام Kali. لن يتم استبدال rootfs الحالي ببيئة Termux أو Android.');
    }
    final header = await bash.openRead(0, 20).fold<List<int>>(
      <int>[],
      (bytes, part) => bytes..addAll(part),
    );
    if (header.length < 20 ||
        header[0] != 0x7f ||
        header[1] != 0x45 ||
        header[2] != 0x4c ||
        header[3] != 0x46 ||
        header[4] != 2 ||
        header[5] != 1 ||
        (header[18] | (header[19] << 8)) != 183) {
      throw StateError('تم رفض الأرشيف: bin/bash ليس ملف Linux ARM64 ELF صالحاً.');
    }
    final loaders = <String>[
      '$base/lib/ld-linux-aarch64.so.1',
      '$base/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1',
      '$base/usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1',
    ];
    var loaderFound = false;
    for (final loader in loaders) {
      if (await FileSystemEntity.type(loader, followLinks: false) !=
          FileSystemEntityType.notFound) {
        loaderFound = true;
        break;
      }
    }
    if (!loaderFound) {
      throw StateError('تم رفض الأرشيف: لم يتم العثور على glibc ARM64 loader.');
    }
  }

  String _safeArchiveFilename(String value) {
    final name = value.split(RegExp(r'[/\\]')).last.trim();
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_');
    return cleaned.isEmpty ? 'kali-rootfs.archive' : cleaned;
  }

  String? _normalizeArchivePath(String value) {
    var normalized = value.replaceAll('\\', '/');
    if (RegExp(r'^[A-Za-z]:').hasMatch(normalized)) return null;
    // Backup tools may store absolute device paths. Treat them as archive-
    // relative names by stripping the leading slash; never write to that path.
    normalized = normalized.replaceFirst(RegExp(r'^/+'), '');
    final parts = <String>[];
    for (final part in normalized.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') return null;
      parts.add(part);
    }
    return parts.join('/');
  }

  String? _detectRootfsPrefix(Archive archive) {
    final names = <String>{};
    for (final entry in archive.files) {
      final name = _normalizeArchivePath(entry.name);
      if (name != null) names.add(name);
    }
    final candidates = <String>[];
    for (final name in names) {
      // usr-merged Debian/Kali archives may contain usr/bin/bash plus a
      // root-level bin -> usr/bin symlink rather than a bin/bash entry.
      if (name.endsWith('usr/bin/bash')) {
        final prefix = name.substring(0, name.length - 'usr/bin/bash'.length);
        if (names.contains('${prefix}usr/bin/sh') &&
            names.contains('${prefix}bin')) {
          candidates.add(prefix);
        }
        continue;
      }
      if (!name.endsWith('bin/bash')) continue;
      final prefix = name.substring(0, name.length - 'bin/bash'.length);
      if (names.contains('${prefix}bin/sh')) candidates.add(prefix);
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      int score(String value) {
        final lower = value.toLowerCase();
        var result = 0;
        if (lower.contains('rootfs/')) result += 100;
        if (lower.contains('kali-arm64/')) result += 80;
        if (lower.contains('kali/')) result += 40;
        return result - value.length.clamp(0, 1000).toInt();
      }
      return score(b).compareTo(score(a));
    });
    return candidates.first;
  }

  bool _isSafeLinkTarget(String relativePath, String target) {
    if (target.isEmpty || target.contains('\\') || target.contains('\u0000')) return false;
    // Absolute symlinks are normal inside Linux rootfs trees and are resolved
    // by PRoot relative to the guest root, not the Android host filesystem.
    if (target.startsWith('/')) return !target.split('/').contains('..');
    final parts = relativePath.split('/')..removeLast();
    for (final part in target.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isEmpty) return false;
        parts.removeLast();
      } else {
        parts.add(part);
      }
    }
    return true;
  }

  Future<bool> _prepareArchiveForExtraction(File source, File tarDestination) async {
    final header = await source.openRead(0, 6).fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    bool starts(List<int> signature) => header.length >= signature.length &&
        List<int>.generate(signature.length, (i) => header[i]).toString() == signature.toString();
    if (starts(<int>[0x50, 0x4b, 0x03, 0x04]) || starts(<int>[0x50, 0x4b, 0x05, 0x06])) {
      return true;
    }
    await tarDestination.parent.create(recursive: true);
    final input = InputFileStream(source.path);
    final output = OutputFileStream(tarDestination.path);
    try {
      if (starts(<int>[0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00])) {
        XZDecoder().decodeStream(input, output, verify: true, throwOnError: true);
      } else if (starts(<int>[0x1f, 0x8b])) {
        GZipDecoder().decodeStream(input, output, verify: true);
      } else if (starts(<int>[0x42, 0x5a, 0x68])) {
        BZip2Decoder().decodeStream(input, output);
      } else if (starts(<int>[0x28, 0xb5, 0x2f, 0xfd])) {
        ZstdDecoder().decodeStream(input, output);
      } else if (header.length >= 2 && header[0] == 0x78 &&
          const <int>[0x01, 0x5e, 0x9c, 0xda].contains(header[1])) {
        ZLibDecoder().decodeStream(input, output);
      } else {
        await for (final chunk in source.openRead()) {
          output.writeBytes(chunk);
        }
      }
    } finally {
      await input.close();
      await output.close();
    }
    return false;
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
    await repairRuntimePermissions(rootfs.path);
  }

  /// Repairs only the paths required to enter the existing Kali userspace.
  /// This is idempotent and deliberately avoids recursively chmodding the
  /// rootfs, which could damage package-specific file permissions.
  Future<void> repairRuntimePermissions(String rootfsPath) async {
    final root = Directory(rootfsPath);
    if (!await root.exists()) {
      throw StateError('Kali rootfs does not exist: $rootfsPath');
    }
    final base = root.absolute.path;
    final directories = <String>[
      base,
      '$base/bin',
      '$base/lib',
      '$base/lib/aarch64-linux-gnu',
      '$base/usr',
      '$base/usr/bin',
      '$base/usr/lib',
      '$base/usr/lib/aarch64-linux-gnu',
      '$base/etc',
      '$base/root',
      '$base/tmp',
      '$base/var',
    ];
    final executables = <String>[
      '$base/bin/bash',
      '$base/bin/sh',
      '$base/usr/bin/env',
      '$base/usr/bin/dash',
      '$base/usr/bin/ls',
      '$base/usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1',
    ];
    final libraries = <String>[
      '$base/usr/lib/aarch64-linux-gnu/libc.so.6',
      '$base/usr/lib/aarch64-linux-gnu/libtinfo.so.6.6',
    ];

    Future<void> applyMode(String mode, List<String> paths, {required bool dirs}) async {
      final existing = <String>[];
      for (final path in paths) {
        final present = dirs ? await Directory(path).exists() : await File(path).exists();
        if (present) existing.add(path);
      }
      if (existing.isEmpty) return;
      final chmod = Platform.isAndroid ? '/system/bin/chmod' : 'chmod';
      final result = await Process.run(chmod, <String>[mode, ...existing], runInShell: false);
      if (result.exitCode != 0) {
        throw StateError('chmod $mode failed for Kali runtime paths: ${result.stderr}');
      }
    }

    // Searchable directories and executable ELF entry points are essential
    // for the glibc interpreter; shared objects need read permission, not
    // blanket executable permission.
    await applyMode('755', directories, dirs: true);
    await applyMode('755', executables, dirs: false);
    await applyMode('644', libraries, dirs: false);
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
      'sha256': extra['archive_sha256']?.toString() ?? 'manual-import',
      'installed_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'state': state,
      ...extra,
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}

class ZionKaliInstallResult {
  const ZionKaliInstallResult.success(this.value)
      : error = null,
        isSuccess = true;
  const ZionKaliInstallResult.failure(this.error)
      : value = null,
        isSuccess = false;

  final Directory? value;
  final Object? error;
  final bool isSuccess;
}

class SecurityException implements Exception {
  SecurityException(this.message);
  final String message;
  @override
  String toString() => message;
}
