import 'dart:async';
import 'dart:io';

class KaliBootstrapService {
  static const String _kaliPath = '/data/local/kali';
  static const String _bootstrapArchive = '/storage/emulated/0/Zion Universal/kali-bootstrap.tar.gz';

  /// الفحص والتجهيز الكامل باستخدام الحزمة الحقيقية
  static Future<String> bootstrap() async {
    // 1. فحص إذا كانت التوزيعة موجودة بالفعل
    if (await _isKaliInstalled()) {
      final mountResult = await _mountFilesystems();
      if (!mountResult) return 'Failed to mount filesystems. Root required.';
      await _startServices();
      return 'Kali Linux is already installed and ready.';
    }

    // 2. فحص وجود الحزمة الحقيقية
    final archive = File(_bootstrapArchive);
    if (!await archive.exists()) {
      return 'Bootstrap archive not found at $_bootstrapArchive. Please copy it first.';
    }

    // 3. تثبيت الحزمة الحقيقية
    final installResult = await _installBootstrap();
    if (!installResult) return 'Failed to install bootstrap. Root required.';

    // 4. تجهيز بيئة chroot
    final mountResult = await _mountFilesystems();
    if (!mountResult) return 'Failed to mount filesystems. Root required.';

    // 5. تشغيل الخدمات
    await _startServices();

    return 'Kali Linux installed via bootstrap and ready.';
  }

  /// فحص وجود التوزيعة
  static Future<bool> _isKaliInstalled() async {
    try {
      final result = await Process.run('su', ['-c', 'ls $_kaliPath/bin/bash'], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// تثبيت الحزمة الحقيقية
  static Future<bool> _installBootstrap() async {
    try {
      // إنشاء المجلد
      await Process.run('su', ['-c', 'mkdir -p $_kaliPath'], runInShell: true);

      // فك ضغط الحزمة الحقيقية
      final result = await Process.run(
        'su',
        ['-c', 'tar -xzf $_bootstrapArchive -C $_kaliPath --numeric-owner'],
        runInShell: true,
      );

      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// ربط أنظمة الملفات
  static Future<bool> _mountFilesystems() async {
    try {
      final mounts = [
        'mount -o bind /dev $_kaliPath/dev',
        'mount -o bind /dev/pts $_kaliPath/dev/pts',
        'mount -o bind /proc $_kaliPath/proc',
        'mount -o bind /sys $_kaliPath/sys',
        'mount -t tmpfs tmpfs $_kaliPath/tmp',
      ];

      for (final mount in mounts) {
        final result = await Process.run('su', ['-c', mount], runInShell: true);
        if (result.exitCode != 0) return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// تشغيل الخدمات الأساسية
  static Future<void> _startServices() async {
    try {
      await Process.run('su', ['-c', 'chroot $_kaliPath /etc/init.d/ssh start'], runInShell: true);
      await Process.run('su', ['-c', 'chroot $_kaliPath /etc/init.d/networking start'], runInShell: true);
    } catch (_) {}
  }

  /// إيقاف التوزيعة
  static Future<void> shutdown() async {
    try {
      await Process.run('su', ['-c', 'chroot $_kaliPath /etc/init.d/ssh stop'], runInShell: true);
      await Process.run('su', ['-c', 'chroot $_kaliPath /etc/init.d/networking stop'], runInShell: true);

      final umounts = [
        'umount $_kaliPath/tmp',
        'umount $_kaliPath/sys',
        'umount $_kaliPath/proc',
        'umount $_kaliPath/dev/pts',
        'umount $_kaliPath/dev',
      ];

      for (final umount in umounts) {
        await Process.run('su', ['-c', umount], runInShell: true);
      }
    } catch (_) {}
  }

  /// الحصول على حالة التوزيعة
  static Future<Map<String, dynamic>> getStatus() async {
    final installed = await _isKaliInstalled();
    return {
      'installed': installed,
      'path': _kaliPath,
      'bootstrap': _bootstrapArchive,
    };
  }
}
