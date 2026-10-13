import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import 'zion_bootstrap.dart';
import 'zion_bootstrap_endpoint.dart';

class ZionUserlandInstallResult {
  const ZionUserlandInstallResult({required this.success, required this.message, this.releaseTag});
  final bool success; final String message; final String? releaseTag;
}

class ZionUserlandInstaller {
  const ZionUserlandInstaller();

  static const _maxDownloadBytes = 256 * 1024 * 1024;

  Future<ZionUserlandInstallResult> installLatest({
    void Function(String message)? onProgress,
  }) async {
    final abi = ZionBootstrapEndpoint.currentAbi();
    onProgress?.call('اكتشاف معمارية الجهاز: ' + abi + '...');

    if (!ZionBootstrap.isSupportedAndroidAbi()) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'معمارية Android غير مدعومة حاليًا: ' + abi,
      );
    }

    if (await ZionBootstrap.isInstalled() &&
        await _hasCompatibleProot() &&
        await _hasCompatibleShell()) {
      await ZionBootstrap.initializeRuntime();
      return ZionUserlandInstallResult(
        success: true,
        message: 'Zion Userland مثبت بالفعل والصدفة قابلة للتشغيل.',
        releaseTag: await ZionBootstrap.currentRelease(),
      );
    }

    if (await _hasKaliRootfs() && await _hasCompatibleProot()) {
      return const ZionUserlandInstallResult(
        success: true,
        message: 'بيئة Kali المحلية موجودة وقابلة للتشغيل عبر PRoot.',
      );
    }

    if (await ZionBootstrap.restoreLatestBackup() &&
        await ZionBootstrap.isInstalled() &&
        await _hasCompatibleProot() &&
        await _hasCompatibleShell()) {
      await ZionBootstrap.initializeRuntime();
      return ZionUserlandInstallResult(
        success: true,
        message: 'تمت استعادة نسخة Zion Userland سليمة محليًا.',
        releaseTag: await ZionBootstrap.currentRelease(),
      );
    }

    // Local sources are always attempted before the network. Kali rootfs is
    // installed under the canonical PRoot path, never over the usr prefix.
    const localCandidates = <String>[
      '/storage/emulated/0/Download/kali-nethunter-rootfs-minimal-arm64.tar.xz',
      '/storage/emulated/0/Download/bootstrap-aarch64.zip',
      '/storage/emulated/0/Zion Universal/bootstrap-aarch64.zip',
    ];
    var foundLocalFile = false;
    String? localFailure;
    for (final path in localCandidates) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        foundLocalFile = true;
        onProgress?.call('[Userland] Found local package: ' + path);
        final result = await _installFromFile(path, onProgress: onProgress);
        if (result.success) return result;
        localFailure = result.message;
        onProgress?.call('تعذر استخدام ' + path + ': ' + result.message);
      } catch (error) {
        localFailure = 'تعذر فحص الملف المحلي ' + path + ': ' + error.toString();
      }
    }

    final backupPath = '/storage/emulated/0/Download/termux_usr_backup';
    final backupDir = Directory(backupPath);
    if (await backupDir.exists()) {
      foundLocalFile = true;
      onProgress?.call('[Userland] Using local termux_usr_backup');
      final restored = await _installFromBackup(backupPath);
      if (restored.success && await _hasCompatibleProot() &&
          await _hasCompatibleShell()) {
        return restored;
      }
      localFailure = restored.success
          ? 'تم نسخ النسخة الاحتياطية لكن فشل التحقق من Bash أو PRoot.'
          : restored.message;
    }

    // Do not hit DNS when a local archive exists but is invalid or unsupported.
    if (foundLocalFile) {
      return ZionUserlandInstallResult(
        success: false,
        message: localFailure ??
            'وُجدت ملفات محلية، لكن لم تنجح أي حزمة في تجهيز بيئة قابلة للتشغيل.',
      );
    }

    onProgress?.call('[Userland] No local files found, trying network...');
    final remote = await _downloadFromSingleEndpoint(abi, onProgress: onProgress);
    if (!remote.success || remote.path == null) {
      return ZionUserlandInstallResult(
        success: false,
        message: remote.message ?? 'تعذر تنزيل Zion Userland.',
      );
    }

    try {
      onProgress?.call('تم تنزيل Bootstrap والتحقق من SHA-256؛ يبدأ التثبيت...');
      final result = await ZionBootstrap().installFromArchive(
        remote.path!,
        onProgress: (progress, message) => onProgress?.call(
          '[' + (progress * 100).round().toString() + '%] ' + message,
        ),
      );
      if (!result.success) {
        return ZionUserlandInstallResult(
          success: false,
          message: result.error ?? 'فشل تثبيت Userland.',
        );
      }
      if (!await ZionBootstrap.isInstalled() ||
          !await _hasCompatibleProot() ||
          !await _hasCompatibleShell()) {
        return const ZionUserlandInstallResult(
          success: false,
          message:
              'اكتمل فك الحزمة لكن فشل فحص تشغيل الصدفة أو PRoot؛ لم يتم اعتماد Userland كجاهز.',
        );
      }
      return ZionUserlandInstallResult(
        success: true,
        message: 'تم تنزيل وتثبيت Zion Userland والتحقق من تشغيل الصدفة بنجاح.',
        releaseTag: await ZionBootstrap.currentRelease(),
      );
    } finally {
      try {
        await File(remote.path!).delete();
      } catch (_) {}
    }
  }

  Future<ZionUserlandInstallResult> _installFromFile(
    String sourcePath, {
    void Function(String message)? onProgress,
  }) async {
    final fileName = sourcePath.split('/').last;
    try {
      if (fileName.endsWith('.tar.xz')) {
        final source = File(sourcePath);
        final length = await source.length();
        if (length <= 0 || length > 1024 * 1024 * 1024) {
          return const ZionUserlandInstallResult(
            success: false,
            message: 'حجم أرشيف Kali المحلي غير صالح.',
          );
        }

        final distsDir = Directory(ZionBootstrap.home + '/.zion/dists/kali');
        await distsDir.create(recursive: true);
        final staging = Directory(
          distsDir.path + '/.rootfs-staging-' +
              DateTime.now().microsecondsSinceEpoch.toString(),
        );
        final rootfs = Directory(distsDir.path + '/rootfs');
        final backupDir = Directory(
          '/storage/emulated/0/Download/termux_usr_backup',
        );

        try {
          await staging.create(recursive: true);
          final prefix = ZionBootstrap.prefix;
          final tarCandidates = <String>[
            prefix + '/bin/tar',
            backupDir.path + '/bin/tar',
          ];
          final environment = <String, String>{
            ...Platform.environment,
            'HOME': ZionBootstrap.home,
            'PREFIX': prefix,
            'PATH': backupDir.path + '/bin:' + prefix +
                '/bin:' + prefix + '/sbin:/system/bin:/system/xbin',
            'LD_LIBRARY_PATH': backupDir.path + '/lib:' +
                backupDir.path + '/lib64:' + prefix + '/lib:' + prefix + '/lib64',
            'TMPDIR': ZionBootstrap.tmp,
          };
          var extracted = false;
          String? extractionError;
          for (final tarPath in tarCandidates) {
            if (!await File(tarPath).exists()) continue;
            try {
              final result = await Process.run(
                tarPath,
                <String>['-xJf', sourcePath, '-C', staging.path],
                runInShell: false,
                environment: environment,
              ).timeout(const Duration(minutes: 15));
              if (result.exitCode == 0) {
                extracted = true;
                break;
              }
              extractionError = result.stderr.toString();
            } catch (error) {
              extractionError = error.toString();
            }
          }

          if (!extracted && await File('/system/bin/toybox').exists()) {
            try {
              final result = await Process.run(
                '/system/bin/toybox',
                <String>['tar', '-xJf', sourcePath, '-C', staging.path],
                runInShell: false,
                environment: environment,
              ).timeout(const Duration(minutes: 15));
              if (result.exitCode == 0) {
                extracted = true;
              } else {
                extractionError = result.stderr.toString();
              }
            } catch (error) {
              extractionError = error.toString();
            }
          }

          if (!extracted) {
            return ZionUserlandInstallResult(
              success: false,
              message: 'تعذر فك أرشيف Kali محليًا باستخدام أدوات الجهاز: ' +
                  (extractionError ?? 'لا يوجد tar يدعم xz'),
            );
          }

          var extractedRoot = staging;
          if (!await File(extractedRoot.path + '/bin/sh').exists()) {
            final children = await staging.list(followLinks: false)
                .where((entity) => entity is Directory)
                .cast<Directory>().toList();
            for (final child in children) {
              if (await File(child.path + '/bin/sh').exists()) {
                extractedRoot = child;
                break;
              }
            }
          }
          if (!await File(extractedRoot.path + '/bin/sh').exists()) {
            return const ZionUserlandInstallResult(
              success: false,
              message: 'فُك أرشيف Kali لكن لم يُعثر على bin/sh؛ لم يتم تفعيل الجذر.',
            );
          }

          if (extractedRoot.path != staging.path) {
            final normalized = Directory(staging.path + '-normalized');
            await extractedRoot.rename(normalized.path);
            if (await staging.exists()) await staging.delete(recursive: true);
            await normalized.rename(staging.path);
          }

          final oldRoot = Directory(
            distsDir.path + '/.rootfs-old-' +
                DateTime.now().microsecondsSinceEpoch.toString(),
          );
          if (await rootfs.exists()) await rootfs.rename(oldRoot.path);
          try {
            await staging.rename(rootfs.path);
            if (await oldRoot.exists()) await oldRoot.delete(recursive: true);
          } catch (_) {
            if (!await rootfs.exists() && await oldRoot.exists()) {
              await oldRoot.rename(rootfs.path);
            }
            rethrow;
          }

          await Directory(ZionBootstrap.home).create(recursive: true);
          await Directory(ZionBootstrap.tmp).create(recursive: true);
          if (!await _hasCompatibleProot() && await backupDir.exists()) {
            final seeded = await _installFromBackup(backupDir.path);
            if (!seeded.success) {
              return ZionUserlandInstallResult(
                success: false,
                message: 'تم تثبيت جذر Kali محليًا، لكن تجهيز PRoot من النسخة الاحتياطية فشل: ' +
                    seeded.message,
              );
            }
          }
          if (!await _hasKaliRootfs() || !await _hasCompatibleProot()) {
            return const ZionUserlandInstallResult(
              success: false,
              message: 'تم فك جذر Kali محليًا، لكن PRoot غير جاهز؛ لم يتم إعلان الطرفية قابلة للتشغيل.',
            );
          }
          onProgress?.call('تم تثبيت Kali rootfs محليًا في ' + rootfs.path + '.');
          return ZionUserlandInstallResult(
            success: true,
            message: 'تم تثبيت Kali Userland من الملف المحلي: ' + fileName,
          );
        } finally {
          try {
            if (await staging.exists()) await staging.delete(recursive: true);
          } catch (_) {}
        }
      }

      if (fileName.endsWith('.zip')) {
        final result = await ZionBootstrap().installFromArchive(
          sourcePath,
          onProgress: (progress, message) => onProgress?.call(
            '[' + (progress * 100).round().toString() + '%] ' + message,
          ),
        );
        if (!result.success) {
          return ZionUserlandInstallResult(
            success: false,
            message: result.error ?? 'ملف ZIP ليس حزمة Zion Userland صالحة.',
          );
        }
        if (!await ZionBootstrap.isInstalled() ||
            !await _hasCompatibleProot() ||
            !await _hasCompatibleShell()) {
          return const ZionUserlandInstallResult(
            success: false,
            message: 'تم فك ZIP لكن فشل التحقق من Bash أو PRoot.',
          );
        }
        return ZionUserlandInstallResult(
          success: true,
          message: 'تم تثبيت Zion Userland من الملف المحلي: ' + fileName,
          releaseTag: await ZionBootstrap.currentRelease(),
        );
      }

      return const ZionUserlandInstallResult(
        success: false,
        message: 'نوع الحزمة المحلية غير معروف.',
      );
    } catch (error) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'فشل التثبيت من الملف المحلي ' + fileName + ': ' + error.toString(),
      );
    }
  }

  Future<ZionUserlandInstallResult> _installFromBackup(
    String backupPath,
  ) async {
    try {
      final backup = Directory(backupPath);
      if (!await backup.exists()) {
        return const ZionUserlandInstallResult(
          success: false,
          message: 'مجلد النسخة الاحتياطية غير موجود.',
        );
      }
      final usrDir = Directory(ZionBootstrap.prefix);
      await usrDir.create(recursive: true);
      final entities = await backup.list(followLinks: false).toList();
      for (final entity in entities) {
        final name = entity.path.split('/').last;
        final targetPath = usrDir.path + '/' + name;
        if (entity is Directory) {
          await _copyDirectory(entity, Directory(targetPath));
        } else if (entity is File) {
          await entity.copy(targetPath);
        } else if (entity is Link) {
          final link = Link(targetPath);
          await link.parent.create(recursive: true);
          if (await link.exists()) await link.delete();
          await link.create(await entity.target());
        }
      }

      await Directory(usrDir.path + '/bin').create(recursive: true);
      try {
        await Process.run(
          '/system/bin/chmod',
          <String>['-R', '755', usrDir.path + '/bin'],
          runInShell: false,
        );
      } catch (_) {}
      await Directory(ZionBootstrap.home).create(recursive: true);
      await Directory(ZionBootstrap.tmp).create(recursive: true);

      if (!await _hasCompatibleShell()) {
        return const ZionUserlandInstallResult(
          success: false,
          message: 'نُسخت النسخة الاحتياطية لكن لم يتمكن Bash المحلي من العمل.',
        );
      }
      return const ZionUserlandInstallResult(
        success: true,
        message: 'تم تجهيز الصدفة محليًا من termux_usr_backup؛ لم يتم تنزيل أي ملف.',
      );
    } catch (error) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'فشل استعادة النسخة الاحتياطية المحلية: ' + error.toString(),
      );
    }
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final name = entity.path.substring(source.path.length + 1);
      final destination = target.path + '/' + name;
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await File(destination).parent.create(recursive: true);
        await entity.copy(destination);
      } else if (entity is Link) {
        await Link(destination).parent.create(recursive: true);
        final link = Link(destination);
        if (await link.exists()) await link.delete();
        await link.create(await entity.target());
      }
    }
  }

  Future<bool> _hasKaliRootfs() async {
    final root = Directory(ZionBootstrap.home + '/.zion/dists/kali/rootfs');
    return await File(root.path + '/bin/sh').exists() &&
        await File(root.path + '/etc/os-release').exists();
  }

  Future<bool> _hasCompatibleShell() async {
    const candidates = <String>[
      '${ZionBootstrap.prefix}/bin/bash',
      '${ZionBootstrap.prefix}/bin/zsh',
      '${ZionBootstrap.prefix}/bin/fish',
      '${ZionBootstrap.prefix}/bin/ash',
    ];
    final environment = <String, String>{
      ...Platform.environment,
      'HOME': ZionBootstrap.home,
      'PREFIX': ZionBootstrap.prefix,
      'TMPDIR': ZionBootstrap.tmp,
      'PATH': '${ZionBootstrap.prefix}/bin:${ZionBootstrap.prefix}/sbin:/system/bin:/system/xbin',
      'LD_LIBRARY_PATH': '${ZionBootstrap.prefix}/lib:${ZionBootstrap.prefix}/lib64',
      'TERM': 'xterm-256color',
      'LANG': 'C.UTF-8',
      'LC_ALL': 'C.UTF-8',
    };

    for (final path in candidates) {
      try {
        final stat = await File(path).stat();
        if (stat.type != FileSystemEntityType.file || (stat.mode & 0x49) == 0) {
          continue;
        }
        final result = await Process.run(
          path,
          const <String>['-c', 'printf ZionUserlandShellOK'],
          runInShell: false,
          environment: environment,
        ).timeout(const Duration(seconds: 4));
        if (result.exitCode == 0 &&
            result.stdout.toString().contains('ZionUserlandShellOK')) {
          return true;
        }
      } catch (_) {
        // Try the next supported shell; a missing shared library or broken
        // executable must not be mistaken for a usable runtime.
      }
    }
    return false;
  }

  Future<bool> _hasCompatibleProot() async {
    final target = File(ZionBootstrap.prefix + '/bin/proot');
    try {
      final stat = await target.stat();
      if (stat.type != FileSystemEntityType.file || (stat.mode & 0x49) == 0) {
        return false;
      }
      final environment = <String, String>{
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
      final version = await Process.run(
        target.path,
        const <String>['--version'],
        runInShell: false,
        environment: environment,
      ).timeout(const Duration(seconds: 5));
      if (version.exitCode != 0 ||
          !('${version.stdout}\n${version.stderr}')
              .toLowerCase()
              .contains('proot')) {
        return false;
      }
      final help = await Process.run(
        target.path,
        const <String>['--help'],
        runInShell: false,
        environment: environment,
      ).timeout(const Duration(seconds: 5));
      final usage = '${help.stdout}\n${help.stderr}'.toLowerCase();
      final rootId = usage.contains('--root-id') ||
          RegExp(r'(^|\s)-0([,\s]|$)').hasMatch(usage);
      final link2symlink = usage.contains('--link2symlink') ||
          RegExp(r'(^|\s)-l([,\s]|$)').hasMatch(usage);
      return rootId && link2symlink;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? path, String? message})>
      _downloadFromSingleEndpoint(
    String abi, {
    void Function(String message)? onProgress,
  }) async {
    final client = http.Client();
    File? temp;

    try {
      onProgress?.call('الاتصال بـ Zion Bootstrap Endpoint...');
      final manifest = await const ZionBootstrapEndpoint().fetch();
      final asset = manifest.assets[abi];
      if (asset == null) {
        return (
          success: false,
          path: null,
          message: 'الـBootstrap Endpoint لا يوفر حزمة للمعمارية $abi.',
        );
      }

      if (asset.size <= 0 || asset.size > _maxDownloadBytes) {
        return (
          success: false,
          path: null,
          message: 'حجم Bootstrap المنشور غير مسموح به.',
        );
      }

      final downloadDir = Directory('${ZionBootstrap.base}/zion/bootstrap-downloads');
      await downloadDir.create(recursive: true);
      temp = File('${downloadDir.path}/bootstrap-$abi.download');

      onProgress?.call('تنزيل Bootstrap $abi إلى مساحة التطبيق الخاصة...');
      final request = http.Request('GET', Uri.parse(asset.url))
        ..headers['User-Agent'] = 'Zion-OS-Userland';
      final response = await client.send(request).timeout(
        const Duration(seconds: 60),
      );
      if (response.statusCode != 200) {
        return (
          success: false,
          path: null,
          message: 'فشل تنزيل Bootstrap (HTTP ${response.statusCode}).',
        );
      }

      final expectedLength = response.contentLength;
      if (expectedLength != null && expectedLength != asset.size) {
        return (
          success: false,
          path: null,
          message: 'حجم Bootstrap المستلم لا يطابق الـEndpoint.',
        );
      }

      if (await temp.exists()) {
        await temp.delete();
      }
      final sink = temp.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          if (received > _maxDownloadBytes || received > asset.size) {
            throw StateError('Bootstrap تجاوز الحجم المعلن.');
          }
          sink.add(chunk);
          if (received % (4 * 1024 * 1024) < chunk.length) {
            final downloaded =
                (received / (1024 * 1024)).toStringAsFixed(1);
            final total = (asset.size / (1024 * 1024)).toStringAsFixed(1);
            onProgress?.call('Bootstrap: $downloaded / $total MB');
          }
        }
      } finally {
        await sink.close();
      }

      if (received != asset.size) {
        return (
          success: false,
          path: null,
          message: 'حجم Bootstrap النهائي لا يطابق الـEndpoint.',
        );
      }

      onProgress?.call('التحقق من SHA-256 للحزمة...');
      final digest = (await sha256.bind(temp.openRead()).first).toString();
      if (digest.toLowerCase() != asset.sha256.toLowerCase()) {
        return (
          success: false,
          path: null,
          message: 'فشل تحقق SHA-256 لـ Bootstrap.',
        );
      }

      onProgress?.call('Bootstrap صالح ومطابق للمعمارية $abi.');
      return (success: true, path: temp.path, message: null);
    } catch (e) {
      try {
        if (temp != null && await temp.exists()) {
          await temp.delete();
        }
      } catch (_) {}
      return (
        success: false,
        path: null,
        message: 'تعذر تنزيل Zion Bootstrap: $e',
      );
    } finally {
      client.close();
    }
  }
}
