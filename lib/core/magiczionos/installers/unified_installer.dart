import 'package:flutter/foundation.dart';

import '../magiczionos_config.dart';
import 'proot_installer.dart';
import 'rootfs_downloader.dart';

class UnifiedInstallResult { const UnifiedInstallResult({required this.success, required this.message, required this.proot, required this.rootfs}); final bool success; final String message; final ProotInstallResult proot; final RootfsInstallResult rootfs; }
class UnifiedInstaller {
  UnifiedInstaller({ProotInstaller? prootInstaller, RootfsDownloader? rootfsDownloader}) : _prootInstaller = prootInstaller ?? ProotInstaller(), _rootfsDownloader = rootfsDownloader ?? RootfsDownloader();
  final ProotInstaller _prootInstaller; final RootfsDownloader _rootfsDownloader;
  Future<UnifiedInstallResult> install(RootStrategy strategy, {String distro = 'ubuntu', bool force = false, ValueChanged<double>? onProgress}) async {
    if (strategy == RootStrategy.magiczionos || strategy == RootStrategy.chroot) { const result = ProotInstallResult(success: true, message: 'هذه الاستراتيجية لا تحتاج تثبيت PRoot.'); const root = RootfsInstallResult(success: true, message: 'لا يوجد rootfs مطلوب للتثبيت.'); return UnifiedInstallResult(success: true, message: 'لا يوجد تثبيت مطلوب.', proot: result, rootfs: root); }
    onProgress?.call(0.05); final proot = await _prootInstaller.install(force: force); if (!proot.success) return UnifiedInstallResult(success: false, message: proot.message, proot: proot, rootfs: const RootfsInstallResult(success: false, message: 'لم يبدأ تثبيت rootfs.'));
    final selected = ZionRootfsDistro.values.firstWhere((e) => e.name == distro, orElse: () => ZionRootfsDistro.ubuntu); onProgress?.call(0.5); final rootfs = await _rootfsDownloader.install(selected, force: force); onProgress?.call(1.0);
    return UnifiedInstallResult(success: rootfs.success, message: rootfs.success ? 'تم تثبيت PRoot و' + distro + ' والتحقق منهما.' : rootfs.message, proot: proot, rootfs: rootfs);
  }
}