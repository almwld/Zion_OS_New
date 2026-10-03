import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'zion_bootstrap.dart';
import 'zion_bootstrap_endpoint.dart';

class ZionUserlandInstallResult {
  const ZionUserlandInstallResult({required this.success, required this.message, this.releaseTag});
  final bool success;
  final String message;
  final String? releaseTag;
}

class ZionUserlandInstaller {
  const ZionUserlandInstaller();

  static const _maxDownloadBytes = 256 * 1024 * 1024;
  static const _endpoint = ZionBootstrapEndpoint();

  String? _assetNameForAbi() {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) return 'aarch64';
    if (abi == Abi.androidArm) return 'arm';
    if (abi == Abi.androidX64) return 'x86_64';
    return null;
  }

  Future<ZionUserlandInstallResult> installLatest({
    void Function(String message)? onProgress,
  }) async {
    final abi = Abi.current();
    onProgress?.call('فحص Zion Userland الموجود على الجهاز (' + abi.toString() + ')...');

    if (!ZionBootstrap.isSupportedAndroidAbi()) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'معمارية جهاز Android غير مدعومة: ' + abi.toString(),
      );
    }

    if (await ZionBootstrap.isInstalled()) {
      await ZionBootstrap.initializeRuntime();
      return ZionUserlandInstallResult(
        success: true,
        message: 'Zion Userland مثبت بالفعل.',
        releaseTag: await ZionBootstrap.currentRelease(),
      );
    }

    final state = await ZionBootstrap.prepareExistingUserlandBackup(onProgress: onProgress);
    if (state.success) {
      return ZionUserlandInstallResult(
        success: true,
        message: 'تم اعتماد Userland الموجود على الجهاز مع إنشاء نسخة احتياطية محلية.',
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

    final asset = _assetNameForAbi();
    if (asset == null) {
      return ZionUserlandInstallResult(
        success: false,
        message: 'لا توجد حزمة Userland منشورة لهذه المعمارية: ' + abi.toString(),
      );
    }

    final remote = await _downloadPublishedArchive(asset, onProgress: onProgress);
    if (!remote.success || remote.path == null) {
      return ZionUserlandInstallResult(
        success: false,
        message: (state.error ?? 'لا يوجد Userland محلي صالح.') +
            '\n' +
            (remote.message ?? 'فشل تنزيل Zion Userland المنشور.'),
      );
    }

    try {
      onProgress?.call('تثبيت Zion Userland الحقيقي والتحقق من manifest وSHA-256...');
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
      return ZionUserlandInstallResult(
        success: true,
        message: 'تم تنزيل وتثبيت Zion Userland الحقيقي بنجاح.',
        releaseTag: await ZionBootstrap.currentRelease(),
      );
    } finally {
      try {
        await File(remote.path!).delete();
      } catch (_) {}
    }
  }

  Future<({bool success, String? path, String? message})> _downloadPublishedArchive({
    void Function(String message)? onProgress,
  }) async {
    final client = http.Client();
    final temp = File(Directory.systemTemp.path + '/zion-bootstrap-' + DateTime.now().microsecondsSinceEpoch.toString() + '.zip');
    try {
      final abi = _assetNameForAbi();
      if (abi == null) return (success: false, path: null, message: 'معمارية الجهاز غير مدعومة بواسطة Zion Bootstrap Endpoint.');
      onProgress?.call('الاتصال بـ Zion Bootstrap Endpoint...');
      final manifest = await _endpoint.fetch();
      final asset = manifest.assets[abi];
      if (asset == null) return (success: false, path: null, message: 'لا توجد حزمة منشورة للمعمارية ' + abi + ' في الإصدار ' + manifest.release + '.');
      if (asset.size > _maxDownloadBytes) return (success: false, path: null, message: 'حجم Bootstrap المنشور يتجاوز الحد المسموح.');
      onProgress?.call('تنزيل Zion Bootstrap (' + abi + ') من المصدر الخارجي...');
      final request = http.Request('GET', Uri.parse(asset.url))..headers['User-Agent'] = 'Zion-OS-Userland';
      final response = await client.send(request).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return (success: false, path: null, message: 'فشل تنزيل Bootstrap (HTTP ' + response.statusCode.toString() + ').');
      final expected = response.contentLength ?? asset.size;
      if (expected > _maxDownloadBytes) return (success: false, path: null, message: 'حجم Bootstrap يتجاوز الحد المسموح.');
      final sink = temp.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        received += chunk.length;
        if (received > _maxDownloadBytes) { await sink.close(); try { await temp.delete(); } catch (_) {} return (success: false, path: null, message: 'تم إيقاف التنزيل لتجاوز الحد الأقصى.'); }
        sink.add(chunk);
        if (received % (1024 * 1024 * 4) < chunk.length) onProgress?.call('تم تنزيل ' + (received / (1024 * 1024)).toStringAsFixed(1) + ' MB من ' + (asset.size / (1024 * 1024)).toStringAsFixed(1) + ' MB');
      }
      await sink.close();
      if (received != asset.size) { try { await temp.delete(); } catch (_) {} return (success: false, path: null, message: 'حجم Bootstrap لا يطابق الـEndpoint.'); }
      onProgress?.call('التحقق من SHA-256 للـBootstrap...');
      final actualDigest = (await sha256.bind(temp.openRead()).first).toString().toLowerCase();
      if (actualDigest != asset.sha256) { try { await temp.delete(); } catch (_) {} return (success: false, path: null, message: 'فشل SHA-256 للـBootstrap؛ تم رفض الحزمة.'); }
      return (success: true, path: temp.path, message: null);
    } catch (e) {
      try { if (await temp.exists()) await temp.delete(); } catch (_) {}
      return (success: false, path: null, message: 'تعذر تنزيل Zion Bootstrap: ' + e.toString());
    } finally { client.close(); }
  }
}
