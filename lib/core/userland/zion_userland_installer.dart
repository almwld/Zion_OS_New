import 'dart:ffi';

import 'local_kali_bootstrap.dart';

class ZionUserlandInstallResult {
  const ZionUserlandInstallResult({
    required this.success,
    required this.message,
    this.releaseTag,
  });

  final bool success;
  final String message;
  final String? releaseTag;
}

class ZionUserlandInstaller {
  const ZionUserlandInstaller();

  Future<ZionUserlandInstallResult> installLatest({
    void Function(String message)? onProgress,
  }) async {
    if (Abi.current() != Abi.androidArm64) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'Kali NetHunter المحلي الحالي مدعوم على ARM64 فقط: ${Abi.current()}',
      );
    }

    final bootstrap = ZionLocalKaliBootstrap();
    final existing = await bootstrap.state();
    if (existing == ZionKaliInstallState.ready) {
      onProgress?.call('Kali Userland المحلي مثبت بالفعل.');
      return const ZionUserlandInstallResult(
        success: true,
        message: 'Kali Userland المحلي جاهز.',
        releaseTag: 'local-kali',
      );
    }

    final result = await bootstrap.install(
      onProgress: (progress) => onProgress?.call(
        '[${progress.percent}%] ${progress.message}',
      ),
    );

    if (result.isSuccess) {
      return const ZionUserlandInstallResult(
        success: true,
        message: 'تم تثبيت Kali Userland المحلي بنجاح.',
        releaseTag: 'local-kali',
      );
    }

    return ZionUserlandInstallResult(
      success: false,
      message: 'فشل تثبيت Kali المحلي: ${result.error}',
      releaseTag: 'local-kali',
    );
  }
}
