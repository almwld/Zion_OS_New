import 'dart:ffi';

import 'zion_bootstrap.dart';

class ZionUserlandInstallResult {
  const ZionUserlandInstallResult({required this.success, required this.message, this.releaseTag});
  final bool success;
  final String message;
  final String? releaseTag;
}

class ZionUserlandInstaller {
  const ZionUserlandInstaller();

  Future<ZionUserlandInstallResult> installLatest({void Function(String message)? onProgress}) async {
    final abi = Abi.current();
    onProgress?.call('فحص Zion Userland الموجود على الجهاز ($abi)...');

    if (!ZionBootstrap.isSupportedAndroidAbi()) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'معمارية جهاز Android غير مدعومة: $abi. لن يتم إنشاء bootstrap جديد.',
      );
    }

    final state = await ZionBootstrap.prepareExistingUserlandBackup(onProgress: onProgress);
    if (state.success) {
      return ZionUserlandInstallResult(
        success: true,
        message: 'تم اعتماد Userland الموجود على الجهاز مع إنشاء نسخة احتياطية محلية تلقائية.',
        releaseTag: await ZionBootstrap.currentRelease(),
      );
    }

    onProgress?.call('محاولة استعادة النسخة الاحتياطية المحلية لـ Zion Userland...');
    if (await ZionBootstrap.restoreLatestBackup()) {
      await ZionBootstrap.initializeRuntime();
      if (await ZionBootstrap.isInstalled()) {
        return const ZionUserlandInstallResult(
          success: true,
          message: 'تمت استعادة Zion Userland من النسخة الاحتياطية المحلية بنجاح.',
          releaseTag: 'local-backup',
        );
      }
    }

    return ZionUserlandInstallResult(
      success: false,
      message: (state.error ?? 'فشل تجهيز Zion Userland.') +
          ' لم يتم العثور على bootstrap صالح على الجهاز، ولن يتم تنزيله أو إنشاؤه من المستودع تلقائياً.',
    );
  }
}
