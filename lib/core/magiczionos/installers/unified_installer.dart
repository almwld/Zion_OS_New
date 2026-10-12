import 'package:flutter/foundation.dart';

import '../../userland/zion_userland_installer.dart';
import '../magiczionos_config.dart';
import 'proot_installer.dart';
import 'rootfs_downloader.dart';

class UnifiedInstallResult {
  const UnifiedInstallResult({
    required this.success,
    required this.message,
    required this.proot,
    required this.rootfs,
  });

  final bool success;
  final String message;
  final ProotInstallResult proot;
  final RootfsInstallResult rootfs;
}

class UnifiedInstaller {
  UnifiedInstaller({
    ProotInstaller? prootInstaller,
    RootfsDownloader? rootfsDownloader,
  })  : _prootInstaller = prootInstaller ?? ProotInstaller(),
        _rootfsDownloader = rootfsDownloader ?? RootfsDownloader();

  final ProotInstaller _prootInstaller;
  final RootfsDownloader _rootfsDownloader;

  Future<UnifiedInstallResult> install(
    RootStrategy strategy, {
    String distro = 'ubuntu',
    bool force = false,
    ValueChanged<double>? onProgress,
  }) async {
    if (strategy == RootStrategy.magiczionos || strategy == RootStrategy.chroot) {
      const result = ProotInstallResult(
        success: true,
        message: 'هذه الاستراتيجية لا تحتاج تثبيت PRoot.',
      );
      const root = RootfsInstallResult(
        success: true,
        message: 'لا يوجد rootfs مطلوب للتثبيت.',
      );
      return UnifiedInstallResult(
        success: true,
        message: 'لا يوجد تثبيت مطلوب.',
        proot: result,
        rootfs: root,
      );
    }

    onProgress?.call(0.03);
    final userland = await const ZionUserlandInstaller().installLatest(
      onProgress: (_) => onProgress?.call(0.15),
    );
    if (!userland.success) {
      return UnifiedInstallResult(
        success: false,
        message: userland.message,
        proot: ProotInstallResult(success: false, message: userland.message),
        rootfs: const RootfsInstallResult(
          success: false,
          message: 'لم يبدأ تثبيت rootfs لأن Zion Userland غير جاهز.',
        ),
      );
    }

    onProgress?.call(0.25);
    final proot = await _prootInstaller.install(force: force);
    if (!proot.success) {
      return UnifiedInstallResult(
        success: false,
        message: proot.message,
        proot: proot,
        rootfs: const RootfsInstallResult(
          success: false,
          message: 'لم يبدأ تثبيت rootfs لأن PRoot غير جاهز.',
        ),
      );
    }

    final selected = ZionRootfsDistro.values.firstWhere(
      (entry) => entry.name == distro,
      orElse: () => ZionRootfsDistro.ubuntu,
    );
    onProgress?.call(0.55);
    final rootfs = await _rootfsDownloader.install(selected, force: force);
    onProgress?.call(1.0);
    return UnifiedInstallResult(
      success: rootfs.success,
      message: rootfs.success
          ? 'تم التحقق من Zion Userland وPRoot وتثبيت $distro.'
          : rootfs.message,
      proot: proot,
      rootfs: rootfs,
    );
  }
}
