import 'dart:convert';
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
  static const _stateFilePath = '/data/data/com.zion.os/.userland_state.json';
  static Future<ZionUserlandInstallResult>? _installFuture;
  static bool _installCompleted = false;

  /// A valid Bash executable is authoritative; the state file prevents repeat
  /// copies, but a stale/missing marker never forces a 1.4 GB recopy by itself.
  Future<bool> isInstalled() async {
    final bashPath = '${ZionBootstrap.prefix}/bin/bash';
    try {
      if (!await File(bashPath).exists()) return false;
      final result = await Process.run(
        bashPath,
        const <String>['-c', 'printf ZION_USERLAND_BASH_OK'],
        runInShell: false,
        environment: <String, String>{
          ...Platform.environment,
          'HOME': ZionBootstrap.home,
          'PREFIX': ZionBootstrap.prefix,
          'TMPDIR': ZionBootstrap.tmp,
          'PATH': '${ZionBootstrap.prefix}/bin:${ZionBootstrap.prefix}/sbin:/system/bin:/system/xbin',
          'LD_LIBRARY_PATH': '${ZionBootstrap.prefix}/lib:${ZionBootstrap.prefix}/lib64',
          'TERM': 'xterm-256color',
          'LANG': 'C.UTF-8',
          'LC_ALL': 'C.UTF-8',
        },
      ).timeout(const Duration(seconds: 4));
      if (result.exitCode != 0 || !result.stdout.toString().contains('ZION_USERLAND_BASH_OK')) return false;

      final stateFile = File(_stateFilePath);
      var stateIsValid = false;
      if (await stateFile.exists()) {
        try {
          final state = jsonDecode(await stateFile.readAsString());
          stateIsValid = state is Map && state['installed'] == true && state['bashPath'] == bashPath;
        } catch (_) {
          // Rebuild a corrupt marker below; do not recopy a working Userland.
        }
      }
      if (!stateIsValid) {
        await _writeState(source: 'existing-userland', sizeBytes: 0);
      }
      _installCompleted = true;
      return true;
    } catch (e) {
      print('[Userland] installed check failed: $e');
      return false;
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
    _installCompleted = false;
  }

  Future<ZionUserlandInstallResult> installLatest({
    void Function(String message)? onProgress,
  }) {
    final active = _installFuture;
    if (active != null) return active;
    final future = _installLatestInternal(onProgress: onProgress).then((result) async {
      if (result.success) {
        _installCompleted = true;
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
    if (await isInstalled()) {
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
    if (await Directory(backupPath).exists()) {
      onProgress?.call('[Userland] Restoring direct directory backup: $backupPath');
      final restored = await _installFromDirectory(backupPath, onProgress: onProgress);
      if (restored.success) {
        return restored;
      }
      onProgress?.call('تعذرت استعادة النسخة المحلية مباشرة: ${restored.message}');
      // Do not silently replace a failed direct restore with a network fetch.
      return restored;
    }

    // Offline-first: inspect local package locations before considering any
    // network endpoint. Only verified Zion bootstrap ZIPs are accepted here;
    // a Kali rootfs tarball must not be unpacked into the Zion prefix.
    const localCandidates = <String>[
      '/storage/emulated/0/Download/kali-nethunter-rootfs-minimal-arm64.tar.xz',
      '/storage/emulated/0/Download/bootstrap-aarch64.zip',
      '/storage/emulated/0/Zion Universal/bootstrap-aarch64.zip',
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
    if (localArchiveSeen) {
      return const ZionUserlandInstallResult(
        success: false,
        message: 'عُثر على ملفات محلية، لكن لم توجد حزمة Zion ZIP صالحة تحتوي manifest وملفات متوافقة. لم تتم محاولة التنزيل عبر الإنترنت.',
      );
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

    final remote = await _downloadFromSingleEndpoint(
      abi,
      onProgress: onProgress,
    );
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
          '[${(progress * 100).round()}%] $message',
        ),
      );
      if (!result.success) {
        return ZionUserlandInstallResult(
          success: false,
          message: result.error ?? 'فشل تثبيت Userland.',
        );
      }
      // Verify the installed runtime end-to-end. A valid archive/hash is not
      // sufficient if the extracted shell or its shared libraries cannot run.
      if (!await ZionBootstrap.isInstalled() ||
          !await _hasCompatibleProot() ||
          !await _hasCompatibleShell()) {
        return const ZionUserlandInstallResult(
          success: false,
          message: 'اكتمل فك الحزمة لكن فشل فحص تشغيل الصدفة أو PRoot؛ لم يتم اعتماد Userland كجاهز.',
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

  Future<ZionUserlandInstallResult> _installFromDirectory(
    String sourcePath, {
    void Function(String message)? onProgress,
  }) async {
    try {
      final sourceDir = Directory(sourcePath);
      if (!await sourceDir.exists()) {
        return const ZionUserlandInstallResult(success: false, message: 'مجلد النسخة الاحتياطية غير موجود.');
      }
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

      onProgress?.call('[Userland] Copying files... (source is about 1.4 GB; this runs asynchronously)');
      final result = await Process.run('/system/bin/cp', <String>['-a', '${sourceDir.path}/.', '${targetDir.path}/'], runInShell: false).timeout(const Duration(minutes: 10));
      if (result.exitCode != 0) {
        onProgress?.call('cp -a failed (exit ${result.exitCode}): ${result.stderr}. Trying Dart copy fallback.');
        try {
          await _manualCopy(sourceDir, targetDir);
        } catch (e) {
          return ZionUserlandInstallResult(success: false, message: 'فشل نسخ النسخة المحلية: ${result.stderr}; fallback: $e');
        }
      }

      onProgress?.call('[Userland] Setting permissions (best-effort; root-owned files are tolerated)...');
      await _repairPermissions(targetDir);
      onProgress?.call('[Userland] Creating symlinks...');
      await _recreateCoreutilsSymlinks('${targetDir.path}/bin');
      await _createOtherSymlinks('${targetDir.path}/bin');

      if (!await _hasCompatibleShell()) {
        return const ZionUserlandInstallResult(success: false, message: 'تم النسخ، لكن Bash لا يعمل؛ تحقق من الصلاحيات ومكتبات التشغيل.');
      }
      // Termux usr is useful as a Bash environment even when PRoot is absent.
      // PRoot is an optional tool, not a prerequisite for launching Bash.
      await ZionBootstrap.initializeRuntime();
      await _writeState(source: sourcePath, sizeBytes: 1400000000);
      onProgress?.call('[Userland] ✓ Ready');
      return ZionUserlandInstallResult(success: true, message: 'تم نسخ Termux usr وإصلاح الصلاحيات والروابط والتحقق من Bash: ${targetDir.path}');
    } catch (e) {
      return ZionUserlandInstallResult(success: false, message: 'فشل تثبيت النسخة المحلية: $e');
    }
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
    if (!await bash.exists()) throw StateError('bash missing after Userland copy');
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

      if (entity is Link) {
        final linkTarget = await entity.target();
        final link = Link(destination);
        if (await link.exists()) {
          await link.delete();
        }
        await link.create(linkTarget);
      } else if (entity is Directory) {
        await _manualCopy(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      }
    }
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
