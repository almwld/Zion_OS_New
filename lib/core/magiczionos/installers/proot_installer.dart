import 'dart:io';

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

/// Validates the standard Termux PRoot shipped inside Zion Userland.
///
/// Do not replace it with proot-rs: that legacy binary does not implement
/// PRoot's -0/--root-id or --link2symlink flags used by Zion's runtime.
class ProotInstaller {
  Future<ProotInstallResult> install({bool force = false}) async {
    if (!await ZionBootstrap.isInstalled()) {
      return const ProotInstallResult(
        success: false,
        message: 'ثبّت Zion Userland أولاً؛ PRoot الرسمي يأتي ضمن الحزمة.',
      );
    }

    final target = File(ZionBootstrap.prefix + '/bin/proot');
    try {
      final stat = await target.stat();
      if (stat.type != FileSystemEntityType.file || (stat.mode & 0x49) == 0) {
        return ProotInstallResult(
          success: false,
          message: 'PRoot الرسمي غير قابل للتنفيذ: ${target.path}. أعد تثبيت Zion Userland.',
          path: target.path,
        );
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
        return ProotInstallResult(
          success: false,
          message: 'PRoot الموجود لم يجتز اختبار --version؛ لن يتم استبداله بملف غير متوافق.',
          path: target.path,
        );
      }

      final help = await Process.run(
        target.path,
        const <String>['--help'],
        runInShell: false,
        environment: environment,
      ).timeout(const Duration(seconds: 5));
      final usage = '${help.stdout}\n${help.stderr}'.toLowerCase();
      final supportsRootId = usage.contains('--root-id') ||
          RegExp(r'(^|\\s)-0([,\\s]|$)').hasMatch(usage);
      final supportsLink2Symlink = usage.contains('--link2symlink') ||
          RegExp(r'(^|\\s)-l([,\\s]|$)').hasMatch(usage);
      if (!supportsRootId || !supportsLink2Symlink) {
        return ProotInstallResult(
          success: false,
          message: 'نسخة PRoot لا تدعم خيارات -0 و--link2symlink المطلوبة. أعد تثبيت Zion Userland لتحديث PRoot الرسمي.',
          path: target.path,
        );
      }

      return ProotInstallResult(
        success: true,
        message: force
            ? 'تم التحقق من PRoot الرسمي؛ تتم إدارته ضمن Zion Userland ولا يُستبدل بتنزيل خارجي.'
            : 'تم التحقق من PRoot الرسمي وخياراته المطلوبة.',
        path: target.path,
      );
    } on FileSystemException {
      return const ProotInstallResult(
        success: false,
        message: 'PRoot غير موجود داخل Zion Userland. أعد تثبيت أو تحديث الحزمة.',
      );
    } catch (error) {
      return ProotInstallResult(
        success: false,
        message: 'تعذر التحقق من PRoot داخل Zion Userland: $error',
        path: target.path,
      );
    }
  }
}
