import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'zion_bootstrap.dart';
import 'zion_bootstrap_endpoint.dart';

class ZionUserlandInstallResult {
  const ZionUserlandInstallResult({required this.success, required this.message, this.releaseTag});
  final bool success; final String message; final String? releaseTag;
}

class ZionUserlandInstaller {
  const ZionUserlandInstaller();

  static const MethodChannel _storageChannel = MethodChannel('zion.os/storage');
  static const _stateFilePath = '/data/data/com.zion.os/.userland_state.json';
  static Future<ZionUserlandInstallResult>? _installFuture;

  /// A state marker and a Bash file's presence are installation metadata;
  /// they are not an execution test. Android may block an ELF binary even when
  /// the copied Userland tree is intact. Never invalidate the installation or
  /// trigger a full recopy solely because Process.start/Process.run is denied.
  Future<bool> isInstalled({void Function(String message)? onProgress}) async {
    final bashPath = '${ZionBootstrap.prefix}/bin/bash';
    final bashFile = File(bashPath);
    try {
      if (await bashFile.exists()) {
        final stat = await bashFile.stat();
        if (stat.size >= 100000) {
          onProgress?.call(
            '[Userland] Bash file present (${stat.size} bytes); execution is checked separately. Keeping usr/ in place.',
          );
          return true;
        }
        onProgress?.call(
          '[Userland] Bash file is unusually small (${stat.size} bytes); preserving usr/ for diagnosis.',
        );
        return false;
      }

      // Do not delete the prefix or its state marker on a failed probe. A
      // partial install must remain available for diagnosis and safe repair.
      final binDir = Directory('${ZionBootstrap.prefix}/bin');
      if (await binDir.exists()) {
        final entries = await binDir.list(followLinks: false).take(1).toList();
        if (entries.isNotEmpty) {
          onProgress?.call(
            '[Userland] usr/bin is non-empty but Bash is missing; preserving existing files and allowing a non-destructive repair attempt.',
          );
        }
      }
      return false;
    } catch (error) {
      onProgress?.call(
        '[Userland] Could not inspect Bash metadata: $error. Existing usr/ will be preserved.',
      );
      return false;
    }
  }

  /// Startup/installer diagnostics. Never mutates or removes the Userland tree.
  Future<void> _logUsrDiagnostics({void Function(String message)? onProgress}) async {
    final root = Directory(ZionBootstrap.prefix);
    final bash = File('${ZionBootstrap.prefix}/bin/bash');
    var totalBytes = 0;
    var binCount = 0;
    try {
      if (await root.exists()) {
        await for (final entity in root.list(recursive: true, followLinks: false)) {
          try {
            if (entity is File) totalBytes += await entity.length();
          } catch (_) {}
        }
      }
      final bin = Directory('${ZionBootstrap.prefix}/bin');
      if (await bin.exists()) binCount = await bin.list(followLinks: false).length;
      final exists = await bash.exists();
      final size = exists ? await bash.length() : 0;
      final message = '[Userland][DIAG] usr=${root.path} exists=${await root.exists()} bytes=$totalBytes binEntries=$binCount bashExists=$exists bashBytes=$size bashPath=${bash.path}';
      print(message);
      onProgress?.call(message);
    } catch (e) {
      final message = '[Userland][DIAG] Failed to inspect usr without modifying it: $e';
      print(message);
      onProgress?.call(message);
    }
  }

  Future<void> _writeState({required String source, required int sizeBytes}) async {
    final file = File(_stateFilePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(<String, Object>{
      'installed': true,
      'installedAt': DateTime.now().toUtc().toIso8601String(),
      'bashPath': '${ZionBootstrap.prefix}/bin/bash',
      'version': '1.0',
      'source': source,
      'sizeBytes': sizeBytes,
    }), flush: true);
    try {
      await Process.run('/system/bin/chmod', <String>['600', _stateFilePath], runInShell: false);
    } catch (_) {}
    print('[Userland] state saved: $_stateFilePath');
  }

  Future<void> uninstallState() async {
    final file = File(_stateFilePath);
    if (await file.exists()) await file.delete();
  }

  Future<ZionUserlandInstallResult> installLatest({
    void Function(String message)? onProgress,
  }) {
    final active = _installFuture;
    if (active != null) return active;
    final future = _installLatestInternal(onProgress: onProgress).then((result) async {
      if (result.success) {
        final stateFile = File(_stateFilePath);
        if (!await stateFile.exists()) {
          await _writeState(source: 'zion-userland-install', sizeBytes: 0);
        }
      }
      return result;
    });
    _installFuture = future;
    return future.whenComplete(() {
      if (identical(_installFuture, future)) _installFuture = null;
    });
  }

  Future<ZionUserlandInstallResult> _installLatestInternal({
    void Function(String message)? onProgress,
  }) async {
    await _logUsrDiagnostics(onProgress: onProgress);
    // Check the local Kali archive first, even if Termux usr is already
    // installed: Kali rootfs and the Termux-compatible prefix are separate.
    // The method returns null only when no supported local archive exists.
    final kaliResult = await _installFromKaliArchive(onProgress: onProgress);
    if (kaliResult != null) return kaliResult;

    if (await isInstalled(onProgress: onProgress)) {
      onProgress?.call('[Userland] Already installed; skipping copy.');
      return const ZionUserlandInstallResult(success: true, message: 'Userland already installed; no copy needed.');
    }

    final abi = ZionBootstrapEndpoint.currentAbi();
    onProgress?.call('اكتشاف معمارية الجهاز: $abi...');

    if (!ZionBootstrap.isSupportedAndroidAbi()) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'معمارية Android غير مدعومة حاليًا: $abi',
      );
    }

    // Restore the uncompressed Termux usr backup directly first. Do not
    // package it as ZIP/TAR: archive metadata and executable bits matter.
    const backupPath = '/storage/emulated/0/Download/termux_usr_backup';
    // The local backup has appeared under several directory layouts across
    // Android file managers. Search only known backup roots; do not walk the
    // whole shared-storage tree or mistake a Kali rootfs for Termux usr.
    const backupCandidates = <String>[
      // User-provided extracted, full Userland backup takes precedence.
      '/storage/emulated/0/zion-bootstrap/usr',
      backupPath,
      '/storage/emulated/0/termux_usr_backup',
      '/storage/emulated/0/Download/Termux/usr',
      '/storage/emulated/0/Download/termux/usr',
      '/storage/emulated/0/termux/usr',
      '/storage/emulated/0/Download/termux_usr_backup/usr',
      '/storage/emulated/0/Download/termux_usr_backup/termux_usr_backup',
      '/storage/emulated/0/Download/termux-backup/usr',
      '/storage/emulated/0/Zion/Userland/usr',
      // The user's local runtime bundle may contain an extracted Termux usr
      // tree under ZionUniversal (without a space). Only treat explicit usr
      // directories as Userland roots; never copy the containing folder of
      // shared libraries into PREFIX.
      '/storage/emulated/0/ZionUniversal/usr',
      '/storage/emulated/0/ZionUniversal/termux/usr',
      '/storage/emulated/0/ZionUniversal/files/usr',
      '/storage/emulated/0/ZionUniversal/termux_usr_backup',
    ];
    var hasBackupDirectory = false;
    for (final candidate in backupCandidates) {
      try {
        if (await Directory(candidate).exists()) {
          hasBackupDirectory = true;
          break;
        }
      } catch (_) {}
    }
    if (!hasBackupDirectory) {
      onProgress?.call('[Userland] Checking Android access to the local backup...');
      var granted = false;
      try {
        granted = await _storageChannel
                .invokeMethod<bool>('ensureAllFilesAccess')
                .timeout(const Duration(minutes: 5)) ??
            false;
      } catch (e) {
        onProgress?.call('[Userland] Android storage access check failed: $e');
      }
      if (!granted) {
        return const ZionUserlandInstallResult(
          success: false,
          message: 'Android 11+ requires one-time All files access for the local Download backup. Allow access in Android settings, then reopen Terminal; Zion cannot bypass this system restriction.',
        );
      }
    }
    String? directBackupFailure;
    var directBackupFound = false;
    for (final candidate in backupCandidates) {
      try {
        if (!await Directory(candidate).exists()) continue;
        directBackupFound = true;
        onProgress?.call('[Userland] Checking local backup candidate: $candidate');
        final restored = await _installFromDirectory(candidate, onProgress: onProgress);
        if (restored.success) return restored;
        directBackupFailure = restored.message;
        onProgress?.call('تعذرت استعادة النسخة المحلية من $candidate: ${restored.message}');
      } catch (e) {
        directBackupFailure = e.toString();
        onProgress?.call('[Userland] Could not restore candidate $candidate: $e');
      }
    }
    if (!directBackupFound) {
      directBackupFailure = 'لم يُعثر على مجلد النسخة الاحتياطية في المسارات المحلية المعروفة.';
    }

    // Offline-first: inspect local package locations before considering any
    // network endpoint. Only verified Zion bootstrap ZIPs are accepted here;
    // a Kali rootfs tarball must not be unpacked into the Zion prefix.
    const localCandidates = <String>[
      // Detect the existing shared-storage Kali tarball; never unpack it as Zion usr.
      '/storage/emulated/0/kali-arm64.tar',
      '/storage/emulated/0/Download/kali-nethunter-rootfs-minimal-arm64.tar.xz',
      '/storage/emulated/0/Download/bootstrap-aarch64.zip',
      '/storage/emulated/0/Zion Universal/bootstrap-aarch64.zip',
      '/storage/emulated/0/ZionUniversal/bootstrap-aarch64.zip',
      '/storage/emulated/0/ZionUniversal/termux-bootstrap-aarch64.zip',
      '/storage/emulated/0/ZionUniversal/termux-bootstrap.zip',
    ];
    var localArchiveSeen = false;
    for (final localPath in localCandidates) {
      final file = File(localPath);
      try {
        if (!await file.exists()) continue;
        localArchiveSeen = true;
        onProgress?.call('[Userland] Found local package: $localPath');
        if (!localPath.toLowerCase().endsWith('.zip')) {
          onProgress?.call('Kali rootfs موجود محليًا، لكنه ليس حزمة Zion Bootstrap؛ لن يُفك داخل usr حتى لا يتلف بيئة Zion.');
          continue;
        }
        final result = await ZionBootstrap().installFromArchive(
          localPath,
          onProgress: (progress, message) => onProgress?.call(
            '[${(progress * 100).round()}%] $message',
          ),
        );
        if (result.success &&
            await ZionBootstrap.isInstalled() &&
            await _hasCompatibleProot() &&
            await _hasCompatibleShell()) {
          await ZionBootstrap.initializeRuntime();
          return ZionUserlandInstallResult(
            success: true,
            message: 'تم تثبيت Zion Userland من الملف المحلي: ${file.uri.pathSegments.last}',
            releaseTag: await ZionBootstrap.currentRelease(),
          );
        }
        onProgress?.call('تعذر اعتماد الحزمة المحلية: ${result.error ?? 'فشل التحقق النهائي من Userland.'}');
      } catch (e) {
        onProgress?.call('تعذر استخدام الملف المحلي $localPath: $e');
      }
    }
    final String? localArchiveFailure = localArchiveSeen
        ? 'عُثر على أرشيف محلي لكن لم تجتز أي حزمة تحقق manifest وSHA-256 وABI.'
        : null;
    if (localArchiveFailure != null) {
      onProgress?.call('[Userland] $localArchiveFailure Checking the app-private known-good backup next.');
    }

    // A release marker and a working PRoot do not prove that the shell
    // executable is present. This was allowing a damaged/incomplete prefix
    // to be reported as "already installed", after which PTY startup failed.
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

    // Prefer a known-good local backup before downloading a full runtime.
    // Never treat a successful restore call alone as proof; revalidate both
    // the shell and PRoot before returning.
    if (await ZionBootstrap.restoreLatestBackup() &&
        await ZionBootstrap.isInstalled() &&
        await _hasCompatibleProot() &&
        await _hasCompatibleShell()) {
      await ZionBootstrap.initializeRuntime();
      return ZionUserlandInstallResult(
        success: true,
        message: 'تم استعادة نسخة Zion Userland سليمة محليًا.',
        releaseTag: await ZionBootstrap.currentRelease(),
      );
    }

    final directFailureText = directBackupFailure ?? 'غير متاحة';
    final archiveFailureText = localArchiveFailure ?? 'غير متاح أو لم يُعثر عليه';
    return ZionUserlandInstallResult(
      success: false,
      message: 'لم يتم العثور على Userland صالح. النسخة المباشرة: $directFailureText؛ الأرشيف المحلي: $archiveFailureText؛ النسخة الداخلية: غير صالحة أو غير موجودة. لم تتم محاولة الاتصال بالإنترنت.',
    );
  }

  /// Installs the explicitly supported local Kali NetHunter rootfs archive.
  ///
  /// Returns null only when the archive is absent, allowing the existing
  /// offline Termux recovery paths to continue. If the archive exists but is
  /// invalid or extraction fails, returns a failure instead of silently
  /// switching to a different source. Existing rootfs data is never deleted:
  /// a validated new rootfs is staged first and any old destination is renamed
  /// to a timestamped sibling before promotion.
  Future<ZionUserlandInstallResult?> _installFromKaliArchive({
    void Function(String message)? onProgress,
  }) async {
    const candidates = <String>[
      '/storage/emulated/0/Download/kali-nethunter-rootfs-minimal-arm64.tar.xz',
      '/storage/emulated/0/kali-nethunter-rootfs-minimal-arm64.tar.xz',
    ];

    File? archive;
    for (final path in candidates) {
      try {
        final candidate = File(path);
        if (await candidate.exists()) {
          archive = candidate;
          break;
        }
      } catch (_) {
        // Continue through the known local paths only.
      }
    }
    if (archive == null) {
      onProgress?.call('[Kali] No local NetHunter archive found; continuing offline Userland recovery.');
      return null;
    }

    final archivePath = archive.path;
    onProgress?.call('[Kali] Found local rootfs archive: $archivePath');
    try {
      final stat = await archive.stat();
      const minimumArchiveBytes = 100 * 1024 * 1024;
      if (stat.size <= minimumArchiveBytes) {
        return ZionUserlandInstallResult(
          success: false,
          message: 'أرشيف Kali المحلي أصغر من الحد المطلوب (>100 MiB): ${stat.size} bytes. لم يتم تعديل ملفاتك.',
        );
      }

      final distDir = Directory('${ZionBootstrap.home}/.zion/dists/kali');
      final target = Directory('${distDir.path}/rootfs');
      final targetBash = File('${target.path}/bin/bash');
      final targetPython = File('${target.path}/usr/bin/python3');

      // Do not overwrite an already complete installation just because the
      // source archive is present.
      if (await targetBash.exists() && await targetPython.exists()) {
        onProgress?.call('[Kali] Existing rootfs already has bin/bash and usr/bin/python3; preserving it.');
        return const ZionUserlandInstallResult(
          success: true,
          message: 'Kali rootfs موجود وسليم من ناحية الملفات المطلوبة؛ لم يتم استبداله.',
          releaseTag: 'local-kali-rootfs',
        );
      }

      await distDir.create(recursive: true);
      final staging = Directory(
        '${distDir.path}/rootfs.staging-${DateTime.now().microsecondsSinceEpoch}',
      );
      await staging.create(recursive: false);
      onProgress?.call('[Kali] Extracting archive into isolated staging directory: ${staging.path}');

      // Use the Dart archive decoder so extraction does not depend on
      // Android toybox tar supporting XZ, and never execute an ELF from
      // app-private storage. archive_io streams .tar.xz entries to disk.
      // Isolate.run keeps the long decode/extraction off the UI isolate.
      await Isolate.run<void>(() async {
        await extractFileToDisk(archivePath, staging.path);
      });

      final stagedBash = File('${staging.path}/bin/bash');
      final stagedPython = File('${staging.path}/usr/bin/python3');
      if (!await stagedBash.exists() || !await stagedPython.exists()) {
        onProgress?.call('[Kali] Staged archive did not contain both bin/bash and usr/bin/python3; staging preserved for diagnosis.');
        return ZionUserlandInstallResult(
          success: false,
          message: 'الأرشيف لا يحتوي في جذر الاستخراج على bin/bash وusr/bin/python3 معًا. تُرك مجلد staging للتشخيص ولم يتم المساس بملفاتك.',
        );
      }
      final bashStat = await stagedBash.stat();
      if (bashStat.size < 100000) {
        return ZionUserlandInstallResult(
          success: false,
          message: 'ملف bin/bash داخل أرشيف Kali غير مكتمل (${bashStat.size} bytes). تُرك staging دون حذف.',
        );
      }

      // If an incomplete destination exists, preserve it by renaming it;
      // never recursively delete user data to make room for the new rootfs.
      String? preservedPath;
      if (await target.exists()) {
        preservedPath = '${distDir.path}/rootfs.backup-${DateTime.now().microsecondsSinceEpoch}';
        await target.rename(preservedPath);
        onProgress?.call('[Kali] Existing rootfs preserved at $preservedPath');
      }
      try {
        await staging.rename(target.path);
      } catch (error) {
        // Best-effort rollback of the previous rootfs if promotion fails.
        if (preservedPath != null && !await target.exists()) {
          try {
            await Directory(preservedPath).rename(target.path);
          } catch (rollbackError) {
            onProgress?.call('[Kali] Rollback failed; previous rootfs remains at $preservedPath: $rollbackError');
          }
        }
        rethrow;
      }

      onProgress?.call('[Kali] ✓ Rootfs installed at ${target.path}');
      return const ZionUserlandInstallResult(
        success: true,
        message: 'تم تثبيت Kali NetHunter محليًا والتحقق من bin/bash وusr/bin/python3 دون اتصال بالإنترنت.',
        releaseTag: 'local-kali-rootfs',
      );
    } catch (error) {
      onProgress?.call('[Kali] Local archive installation failed: $error');
      return ZionUserlandInstallResult(
        success: false,
        message: 'تعذر تثبيت أرشيف Kali المحلي: $error. لم تُحذف ملفات المستخدم.',
      );
    }
  }

  Future<ZionUserlandInstallResult> _installFromDirectory(
    String sourcePath, {
    void Function(String message)? onProgress,
  }) async {
    Directory? rollbackTarget;
    Directory? rollbackSnapshot;
    var hadRollbackTarget = false;
    try {
      final requestedSourceDir = Directory(sourcePath);
      if (!await requestedSourceDir.exists()) {
        return const ZionUserlandInstallResult(success: false, message: 'مجلد النسخة الاحتياطية غير موجود.');
      }
      // Some backup tools wrap the actual Termux prefix in folders such as
      // termux_usr_backup/usr. Resolve the real prefix before copying; otherwise
      // a successful copy can still leave usr/bin empty.
      final sourceDir = await _resolveBackupUsrRoot(requestedSourceDir, onProgress: onProgress);
      if (sourceDir == null) {
        await _diagnoseBackupLayout(requestedSourceDir, onProgress: onProgress);
        return const ZionUserlandInstallResult(
          success: false,
          message: 'لم يُعثر داخل النسخة الاحتياطية على مجلد bin غير فارغ. لم تُنسخ بنية غير معروفة إلى usr؛ راجع تشخيص بنية النسخة الاحتياطية.',
        );
      }
      onProgress?.call('[Userland] Resolved backup root: ${sourceDir.path}');
      final targetDir = Directory(ZionBootstrap.prefix);
      await targetDir.create(recursive: true);

      onProgress?.call('[Userland] Checking private storage...');
      final df = await Process.run('/system/bin/df', <String>['-k', targetDir.path], runInShell: false);
      if (df.exitCode == 0) {
        final lines = df.stdout.toString().trim().split('\n');
        if (lines.length >= 2) {
          final columns = lines.last.trim().split(RegExp(r'\s+'));
          if (columns.length >= 4) {
            final availableKb = int.tryParse(columns[3]);
            if (availableKb != null && availableKb < 1800 * 1024) {
              return const ZionUserlandInstallResult(success: false, message: 'المساحة الحرة غير كافية؛ يلزم نحو 1.8 GB على الأقل داخل مساحة التطبيق.');
            }
          }
        }
      }

      // Snapshot the existing prefix before touching any file. If the snapshot
      // cannot be completed, abort without changing usr/ at all.
      final hadTarget = await targetDir.exists();
      final safetyBackup = Directory('${targetDir.path}.backup.${DateTime.now().millisecondsSinceEpoch}');
      rollbackTarget = targetDir;
      rollbackSnapshot = safetyBackup;
      hadRollbackTarget = hadTarget;
      if (hadTarget) {
        try {
          onProgress?.call('[Userland] Creating rollback snapshot: ${safetyBackup.path}');
          await _manualCopy(targetDir, safetyBackup);
          if (!await File('${safetyBackup.path}/bin/bash').exists() &&
              !await Directory(safetyBackup.path).exists()) {
            throw StateError('Safety snapshot verification failed');
          }
        } catch (e) {
          try { if (await safetyBackup.exists()) await safetyBackup.delete(recursive: true); } catch (_) {}
          return ZionUserlandInstallResult(
            success: false,
            message: 'تعذر إنشاء نسخة أمان من usr الحالي؛ أُلغيت العملية دون تعديل usr: $e',
          );
        }
      }
      Future<void> rollbackIfPossible() async {
        if (!hadTarget || !await safetyBackup.exists()) {
          onProgress?.call('[Userland] No verified previous usr snapshot; current files are being preserved (no destructive cleanup).');
          return;
        }
        final failed = Directory('${targetDir.path}.failed.${DateTime.now().millisecondsSinceEpoch}');
        try {
          if (await targetDir.exists()) await targetDir.rename(failed.path);
          await safetyBackup.rename(targetDir.path);
          try { if (await failed.exists()) await failed.delete(recursive: true); } catch (_) {}
          onProgress?.call('[Userland] Rollback completed; previous usr restored.');
        } catch (e) {
          onProgress?.call('[Userland] Rollback could not promote the snapshot: $e. Snapshot preserved at ${safetyBackup.path}.');
          if (!await targetDir.exists() && await failed.exists()) {
            try { await failed.rename(targetDir.path); } catch (_) {}
          }
        }
      }

      onProgress?.call('[Userland] Copying files...');
      final result = await _copyDirectoryWithProgress(sourceDir.path, targetDir.path, onProgress: onProgress);
      if (result.exitCode == 124) {
        await rollbackIfPossible();
        return const ZionUserlandInstallResult(
          success: false,
          message: 'انتهت مهلة نسخ Userland؛ تمت استعادة النسخة السابقة إن توفرت، ولم تُحذف usr دون نسخة أمان.',
        );
      }
      if (result.exitCode != 0) {
        onProgress?.call('cp -a failed (exit ${result.exitCode}): ${result.stderr}. Trying Dart copy fallback.');
        try {
          await _manualCopy(sourceDir, targetDir);
        } catch (e) {
          await rollbackIfPossible();
          return ZionUserlandInstallResult(success: false, message: 'فشل نسخ النسخة المحلية: ${result.stderr}; fallback: $e');
        }
      }

      onProgress?.call('[Userland] Setting permissions (best-effort; root-owned files are tolerated)...');
      await _repairPermissions(targetDir);
      onProgress?.call('[Userland] Creating symlinks...');
      await _recreateCoreutilsSymlinks('${targetDir.path}/bin');
      await _createOtherSymlinks('${targetDir.path}/bin');

      if (!await _hasCompatibleShell()) {
        await _diagnoseShellCandidates(onProgress: onProgress);
        await rollbackIfPossible();
        return const ZionUserlandInstallResult(
          success: false,
          message: 'لم يجتز Userland فحص الصدفة؛ تمت استعادة النسخة السابقة إن توفرت، وستستخدم الطرفية /system/bin/sh عند الحاجة.',
        );
      }
      // Termux usr is useful as a Bash environment even when PRoot is absent.
      // PRoot is an optional tool, not a prerequisite for launching Bash.
      await ZionBootstrap.initializeRuntime();
      await _writeState(source: sourcePath, sizeBytes: 1400000000);
      if (hadTarget && await safetyBackup.exists()) {
        try { await safetyBackup.delete(recursive: true); } catch (e) {
          onProgress?.call('[Userland] Installed successfully; retained safety snapshot at ${safetyBackup.path}: $e');
        }
      }
      onProgress?.call('[Userland] ✓ Ready');
      return ZionUserlandInstallResult(success: true, message: 'تم نسخ Termux usr وإصلاح الصلاحيات والروابط والتحقق من Bash: ${targetDir.path}');
    } catch (e) {
      // Last-resort rollback for exceptions thrown by permission repair,
      // symlink repair, runtime setup, or state writing. Never delete a prefix
      // unless a safety snapshot exists and can be promoted into its place.
      final target = rollbackTarget;
      final snapshot = rollbackSnapshot;
      if (target != null && snapshot != null && hadRollbackTarget) {
        try {
          if (await snapshot.exists()) {
            final failed = Directory('${target.path}.failed.${DateTime.now().millisecondsSinceEpoch}');
            if (await target.exists()) await target.rename(failed.path);
            await snapshot.rename(target.path);
            // Retain the rejected tree if cleanup fails; it is recoverable data.
            try { if (await failed.exists()) await failed.delete(recursive: true); } catch (_) {}
            onProgress?.call('[Userland] Exception rollback completed; prior usr restored.');
          } else {
            onProgress?.call('[Userland] Exception occurred but no rollback snapshot exists; usr was not deleted.');
          }
        } catch (rollbackError) {
          onProgress?.call('[Userland] Exception rollback failed: $rollbackError. Current and snapshot trees were preserved where possible.');
        }
      } else {
        onProgress?.call('[Userland] Exception occurred without a previous usr snapshot; current files were preserved.');
      }
      return ZionUserlandInstallResult(success: false, message: 'فشل تثبيت النسخة المحلية: $e');
    }
  }

  /// Finds the actual Termux prefix in backups that may be wrapped in
  /// one or more folders. An empty bin/ is never accepted as a valid prefix.
  Future<Directory?> _resolveBackupUsrRoot(
    Directory requestedRoot, {
    void Function(String message)? onProgress,
  }) async {
    final queue = <({Directory dir, int depth})>[(dir: requestedRoot, depth: 0)];
    final visited = <String>{};
    Directory? best;
    var bestScore = -1;
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!visited.add(current.dir.path) || current.depth > 4) continue;
      final bin = Directory('${current.dir.path}/bin');
      if (await bin.exists()) {
        try {
          final entries = await bin.list(followLinks: false).take(10000).toList();
          if (entries.isNotEmpty) {
            var score = entries.length > 100 ? 100 : entries.length;
            for (final marker in <String>['bash', 'sh', 'coreutils', 'apt', 'proot']) {
              if (await File('${bin.path}/$marker').exists() ||
                  await Link('${bin.path}/$marker').exists()) {
                score += marker == 'bash' ? 1000 : 20;
              }
            }
            if (score > bestScore) {
              best = current.dir;
              bestScore = score;
            }
          }
        } catch (e) {
          onProgress?.call('[Userland] Could not inspect ${bin.path}: $e');
        }
      }
      if (current.depth == 4) continue;
      try {
        await for (final entity in current.dir.list(followLinks: false)) {
          if (entity is Directory) {
            final name = entity.path.split('/').last;
            if (name == 'proc' || name == 'sys' || name == 'dev') continue;
            queue.add((dir: entity, depth: current.depth + 1));
          }
        }
      } catch (e) {
        onProgress?.call('[Userland] Could not scan ${current.dir.path}: $e');
      }
    }
    return best;
  }

  Future<void> _diagnoseBackupLayout(
    Directory root, {
    void Function(String message)? onProgress,
  }) async {
    const maxDepth = 3;
    final queue = <({Directory dir, int depth})>[(dir: root, depth: 0)];
    var shown = 0;
    while (queue.isNotEmpty && shown < 80) {
      final current = queue.removeAt(0);
      if (current.depth > maxDepth) continue;
      try {
        final entries = await current.dir.list(followLinks: false).take(40).toList();
        final line = '[Userland] Backup layout: ${current.dir.path} (${entries.length} entries)';
        print(line);
        onProgress?.call(line);
        shown++;
        if (current.depth < maxDepth) {
          for (final entry in entries) {
            if (entry is Directory) {
              queue.add((dir: entry, depth: current.depth + 1));
            }
          }
        }
      } catch (e) {
        onProgress?.call('[Userland] Cannot inspect ${current.dir.path}: $e');
      }
    }
  }

  Future<({int exitCode, String stderr})> _copyDirectoryWithProgress(
    String sourcePath,
    String targetPath, {
    void Function(String message)? onProgress,
  }) async {
    var totalEntries = 0;
    try {
      final count = await Process.run(
        '/system/bin/sh',
        <String>['-c', r'find "$1" -mindepth 1 -print 2>/dev/null | wc -l', 'zion-copy-count', sourcePath],
        runInShell: false,
      ).timeout(const Duration(minutes: 2));
      totalEntries = int.tryParse(count.stdout.toString().trim()) ?? 0;
    } catch (_) {
      // Copy still proceeds if the platform find implementation is limited.
    }

    final process = await Process.start(
      '/system/bin/cp',
      <String>['-av', '$sourcePath/.', '$targetPath/'],
      runInShell: false,
    );
    final stderr = StringBuffer();
    var copiedEntries = 0;
    var lastPercent = -1;
    final watch = Stopwatch()..start();
    final stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      copiedEntries++;
      if (totalEntries > 0) {
        final percent = ((copiedEntries * 100) ~/ totalEntries).clamp(0, 99);
        if (percent >= lastPercent + 5) {
          lastPercent = percent;
          onProgress?.call('[Userland] Copying files... $percent%');
        }
      }
    });
    final stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .listen(stderr.write);
    final ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      onProgress?.call('[Userland] Copying files... still running (${watch.elapsed.inSeconds}s)');
    });
    var exitCode = 124;
    try {
      exitCode = await process.exitCode.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return 124;
        },
      );
    } finally {
      ticker.cancel();
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();
      watch.stop();
    }
    if (exitCode == 0) onProgress?.call('[Userland] Copying files... 100%');
    return (exitCode: exitCode, stderr: stderr.toString());
  }

  /// Repair permissions without allowing a few root-owned shared libraries to
  /// abort the restore. Directories stay traversable; Bash is verified afterward.
  Future<void> _repairPermissions(Directory root) async {
    Future<void> recursiveChmod(String path, String mode, {bool critical = false}) async {
      if (!await Directory(path).exists()) return;
      try {
        final result = await Process.run(
          '/system/bin/chmod', <String>['-R', mode, path],
          runInShell: false,
        ).timeout(const Duration(minutes: 2));
        print('[Permissions] $path: exit=${result.exitCode}');
        if (critical && result.exitCode != 0) {
          print('[Permissions] $path had partial chmod failures; verifying executable instead of aborting.');
        }
      } catch (e) {
        print('[Permissions] $path ignored: $e');
      }
    }

    await recursiveChmod('${root.path}/bin', '755', critical: true);
    await recursiveChmod('${root.path}/libexec', '755', critical: true);

    // Never chmod -R 644 on a directory tree: that removes execute/traverse
    // bits from directories. find changes files only and leaves directory modes.
    for (final entry in <({String name, String mode})>[
      (name: 'lib', mode: '644'),
      (name: 'share', mode: '644'),
      (name: 'etc', mode: '644'),
    ]) {
      final path = '${root.path}/${entry.name}';
      if (!await Directory(path).exists()) continue;
      try {
        final dirs = await Process.run(
          '/system/bin/find', <String>[path, '-type', 'd', '-exec', 'chmod', '755', '{}', '+'],
          runInShell: false,
        ).timeout(const Duration(minutes: 2));
        final files = await Process.run(
          '/system/bin/find', <String>[path, '-type', 'f', '-exec', 'chmod', entry.mode, '{}', '+'],
          runInShell: false,
        ).timeout(const Duration(minutes: 2));
        print('[Permissions] $path: dirs=${dirs.exitCode}, files=${files.exitCode} (non-fatal)');
      } catch (e) {
        print('[Permissions] $path (ignored): $e');
      }
    }

    // Restore execution bits on known entry points if ownership allows it.
    for (final path in <String>[
      '${root.path}/bin/bash',
      '${root.path}/bin/coreutils',
      '${root.path}/bin/gawk',
      '${root.path}/bin/vim',
    ]) {
      try {
        await Process.run('/system/bin/chmod', <String>['755', path], runInShell: false);
      } catch (_) {}
    }

    final bash = File('${root.path}/bin/bash');
    if (!await bash.exists()) {
      // A backup may contain a usable sh/dash but omit Bash. Do not throw
      // before diagnostics run: preserve the copied tree and let TerminalService
      // select the verified fallback shell without repeating a large restore.
      await _diagnoseShellCandidates();
      print('[Permissions] Bash is missing; preserving Userland for sh/dash fallback.');
      return;
    }
    final test = await Process.run(
      bash.path, const <String>['-c', 'printf BASH_OK'],
      runInShell: false,
      environment: <String, String>{
        ...Platform.environment,
        'HOME': ZionBootstrap.home,
        'PREFIX': ZionBootstrap.prefix,
        'TMPDIR': ZionBootstrap.tmp,
        'PATH': '${root.path}/bin:${root.path}/sbin:/system/bin:/system/xbin',
        'LD_LIBRARY_PATH': '${root.path}/lib:${root.path}/lib64',
        'TERM': 'xterm-256color',
        'LANG': 'C.UTF-8',
        'LC_ALL': 'C.UTF-8',
      },
    ).timeout(const Duration(seconds: 5));
    if (test.exitCode != 0 || !test.stdout.toString().contains('BASH_OK')) {
      throw StateError('bash verification failed (exit=${test.exitCode}): ${test.stderr}');
    }
    print('[Permissions] ✓ Critical Bash check passed; non-critical chmod errors were tolerated.');
  }

  Future<void> _recreateCoreutilsSymlinks(String binDir) async {
    if (!await File('$binDir/coreutils').exists()) {
      print('[Symlinks] coreutils multicall binary not found; preserving existing commands.');
      return;
    }
    const tools = <String>[
      'ls','cat','cp','mv','rm','mkdir','rmdir','chmod','chown','ln','touch','echo','pwd','whoami','id','true','false','yes','env','basename','dirname','head','tail','wc','sort','uniq','cut','tr','tee','sleep','seq','shuf','readlink','realpath','stat','du','df','date','hostname','uname','nproc','printenv','printf','test','timeout','kill','unlink','install','mkfifo','mknod','od','base64','basenc','cksum','comm','csplit','dd','dir','dircolors','expand','expr','factor','fmt','fold','groups','join','link','logname','md5sum','sha1sum','sha256sum','nl','nohup','numfmt','paste','pathchk','pr','ptx','runcon','split','stdbuf','sum','sync','tac','truncate','tsort','tty','unexpand','users','vdir','chcon',
    ];
    for (final tool in tools) {
      await _createLinkIfMissing('$binDir/$tool', 'coreutils');
    }
  }

  Future<void> _createOtherSymlinks(String binDir) async {
    const mappings = <String, String>{'sh':'bash','awk':'gawk','nawk':'gawk','vi':'vim','editor':'nano','nc':'netcat','python':'python3','pip':'pip3'};
    for (final entry in mappings.entries) {
      await _createLinkIfMissing('$binDir/${entry.key}', entry.value);
    }
  }

  Future<void> _createLinkIfMissing(String linkPath, String targetName) async {
    final targetPath = '${File(linkPath).parent.path}/$targetName';
    if (!await File(targetPath).exists() && !await Link(targetPath).exists()) return;
    // Preserve existing real commands and avoid self-links such as bash -> bash.
    if (await File(linkPath).exists() || await Link(linkPath).exists()) return;
    try {
      await Link(linkPath).create(targetName);
    } catch (e) {
      print('[Symlinks] ${linkPath.split('/').last} failed: $e');
    }
  }

  Future<void> _manualCopy(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final name = entity.uri.pathSegments.isNotEmpty
          ? entity.uri.pathSegments[entity.uri.pathSegments.length - 1]
          : entity.path.split('/').last;
      final destination = '${target.path}/$name';
      final destinationType = await FileSystemEntity.type(
        destination,
        followLinks: false,
      );

      if (entity is Link) {
        // FileSystemEntity.exists() follows links and returns false for a
        // broken destination symlink. Remove by entity type so retries can
        // replace broken links instead of failing with EEXIST.
        if (destinationType != FileSystemEntityType.notFound) {
          await _removeExistingPath(destination, destinationType);
        }
        final linkTarget = await entity.target();
        await Link(destination).create(linkTarget);
      } else if (entity is Directory) {
        if (destinationType != FileSystemEntityType.notFound &&
            destinationType != FileSystemEntityType.directory) {
          await _removeExistingPath(destination, destinationType);
        }
        await Directory(destination).create(recursive: true);
        await _manualCopy(entity, Directory(destination));
      } else if (entity is File) {
        if (destinationType == FileSystemEntityType.link ||
            destinationType == FileSystemEntityType.directory) {
          await _removeExistingPath(destination, destinationType);
        }
        await entity.copy(destination);
      }
    }
  }

  Future<void> _removeExistingPath(
    String path,
    FileSystemEntityType type,
  ) async {
    if (type == FileSystemEntityType.link) {
      await Link(path).delete();
    } else if (type == FileSystemEntityType.file) {
      await File(path).delete();
    } else if (type == FileSystemEntityType.directory) {
      // Never recursively remove an existing Userland directory to resolve a
      // copy conflict. Stop the repair and preserve the on-device files for
      // diagnosis instead of risking deletion of usr/bin or another subtree.
      throw FileSystemException(
        'Refusing destructive recursive delete during Userland restore',
        path,
      );
    } else if (type != FileSystemEntityType.notFound) {
      throw FileSystemException('Unsupported existing destination type', path);
    }
  }

  /// Diagnose missing/broken shells after restoring a local Userland backup.
  Future<void> _diagnoseShellCandidates({void Function(String message)? onProgress}) async {
    final usrDir = ZionBootstrap.prefix;
    final candidates = <String>['$usrDir/bin/bash', '$usrDir/bin/sh', '$usrDir/bin/busybox', '$usrDir/bin/dash', '/system/bin/sh'];
    var found = false;
    for (final path in candidates) {
      try {
        if (!await File(path).exists()) continue;
        found = true;
        final heading = '[Userland] Found shell candidate: $path';
        print(heading); onProgress?.call(heading);
        final args = path.endsWith('/busybox') ? <String>['sh', '-c', 'printf ZION_SHELL_DIAGNOSTIC_OK'] : <String>['-c', 'printf ZION_SHELL_DIAGNOSTIC_OK'];
        final result = await Process.run(path, args, runInShell: false, environment: _shellDiagnosticEnvironment()).timeout(const Duration(seconds: 3));
        final detail = '[Userland] Test $path: exit=${result.exitCode}; stdout=${result.stdout}; stderr=${result.stderr}';
        print(detail); onProgress?.call(detail);
        break;
      } catch (error) {
        final detail = '[Userland] Shell candidate check failed for $path: $error';
        print(detail); onProgress?.call(detail);
      }
    }
    if (!found) {
      const message = '[Userland] No bash/sh/busybox/dash found in usr/bin; TerminalService should use /system/bin/sh.';
      print(message); onProgress?.call(message);
    }
    final binDir = Directory('$usrDir/bin');
    if (await binDir.exists()) {
      try {
        final entries = await binDir.list(followLinks: false).toList();
        final heading = '[Userland] bin/ contains ${entries.length} entries:';
        print(heading); onProgress?.call(heading);
        for (final entry in entries.take(30)) { final line = '  ${entry.path}'; print(line); onProgress?.call(line); }
      } catch (error) { final line = '[Userland] Unable to list bin/: $error'; print(line); onProgress?.call(line); }
    } else {
      const message = '[Userland] Expected usr/bin directory is missing.';
      print(message); onProgress?.call(message);
    }
  }

  Map<String, String> _shellDiagnosticEnvironment() => <String, String>{
    ...Platform.environment,
    'HOME': ZionBootstrap.home, 'PREFIX': ZionBootstrap.prefix, 'TMPDIR': ZionBootstrap.tmp,
    'PATH': '${ZionBootstrap.prefix}/bin:${ZionBootstrap.prefix}/sbin:/system/bin:/system/xbin',
    'LD_LIBRARY_PATH': '${ZionBootstrap.prefix}/lib:${ZionBootstrap.prefix}/lib64',
    'TERM': 'xterm-256color', 'LANG': 'C.UTF-8', 'LC_ALL': 'C.UTF-8',
  };
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

}
