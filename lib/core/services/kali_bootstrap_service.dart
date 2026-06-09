import 'dart:async';
import 'dart:io';

class KaliBootstrapService {
  static const String _kaliPath = '/data/local/kali';
  
  // المسارات المحتملة للأرشيف
  static const List<String> _possibleArchives = [
    '/sdcard/Zion Universal/bootstrap-aarch64.zip',
    '/sdcard/kali-bootstrap.tar.gz',
    '/sdcard/kali-armhf.tar.gz',
  ];

  /// الفحص والتجهيز الكامل
  static Future<String> bootstrap() async {
    // 1. فحص إذا كانت التوزيعة موجودة بالفعل
    if (await _isKaliInstalled()) {
      final mountResult = await _mountFilesystems();
      if (!mountResult) return 'Failed to mount filesystems. Root required.';
      await _startServices();
      return 'Kali Linux is already installed and ready.';
    }

    // 2. البحث عن أي أرشيف متاح
    String? archivePath;
    for (final path in _possibleArchives) {
      if (await File(path).exists()) {
        archivePath = path;
        break;
      }
    }

    if (archivePath == null) {
      return 'No bootstrap archive found. Please copy bootstrap.zip to /sdcard/Zion Universal/';
    }

    // 3. تثبيت الأرشيف
    final installResult = await _installArchive(archivePath);
    if (!installResult) return 'Failed to install bootstrap. Root required.';

    // 4. تجهيز بيئة chroot
    final mountResult = await _mountFilesystems();
    if (!mountResult) return 'Failed to mount filesystems. Root required.';

    // 5. تشغيل الخدمات
    await _startServices();

    return 'Kali Linux installed successfully.';
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

  /// تثبيت الأرشيف (يدعم Zip و Tar.Gz)
  static Future<bool> _installArchive(String archivePath) async {
    try {
      // إنشاء المجلد
      await Process.run('su', ['-c', 'mkdir -p $_kaliPath'], runInShell: true);

      if (archivePath.endsWith('.zip')) {
        // فك ضغط ملف zip
        final result = await Process.run(
          'su',
          ['-c', 'unzip -o "$archivePath" -d $_kaliPath'],
          runInShell: true,
        );
        return result.exitCode == 0;
      } else if (archivePath.endsWith('.tar.gz') || archivePath.endsWith('.tgz')) {
        // فك ضغط ملف tar.gz
        final result = await Process.run(
          'su',
          ['-c', 'tar -xzf "$archivePath" -C $_kaliPath --numeric-owner'],
          runInShell: true,
        );
        return result.exitCode == 0;
      }

      return false;
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
      'archives_checked': _possibleArchives,
    };
  }
}
