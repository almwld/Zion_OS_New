import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'zion_bootstrap.dart';

class ZionUserlandInstallResult {
  const ZionUserlandInstallResult({required this.success, required this.message, this.releaseTag});
  final bool success;
  final String message;
  final String? releaseTag;
}

class ZionUserlandInstaller {
  const ZionUserlandInstaller();

  static const _releaseApi =
      'https://api.github.com/repos/almwld/Zion_OS_New/releases/tags/zion-userland-latest';
  static const _maxDownloadBytes = 256 * 1024 * 1024;

  String? _assetNameForAbi() {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) return 'zion-userland-aarch64.zip';
    if (abi == Abi.androidArm) return 'zion-userland-arm.zip';
    if (abi == Abi.androidX64) return 'zion-userland-x86_64.zip';
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

  Future<({bool success, String? path, String? message})> _downloadPublishedArchive(
    String assetName, {
    void Function(String message)? onProgress,
  }) async {
    final client = http.Client();
    final temp = File(
      Directory.systemTemp.path + '/zion-userland-' +
      DateTime.now().microsecondsSinceEpoch.toString() + '.zip',
    );

    try {
      onProgress?.call('البحث عن حزمة Userland المنشورة: ' + assetName + '...');
      final releaseResponse = await client.get(
        Uri.parse(_releaseApi),
        headers: const <String, String>{
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'Zion-OS-Userland',
        },
      ).timeout(const Duration(seconds: 30));

      if (releaseResponse.statusCode != 200) {
        return (
          success: false,
          path: null,
          message: 'مستودع Userland غير متاح حاليًا (HTTP ' +
              releaseResponse.statusCode.toString() + ').',
        );
      }

      final release = jsonDecode(releaseResponse.body);
      if (release is! Map) {
        return (
          success: false,
          path: null,
          message: 'استجابة إصدار Userland غير صالحة.',
        );
      }

      final assets = release['assets'];
      if (assets is! List) {
        return (
          success: false,
          path: null,
          message: 'إصدار Userland لا يحتوي على ملفات.',
        );
      }

      String? downloadUrl;
      String? expectedDigest;
      int? expectedAssetSize;
      for (final item in assets) {
        if (item is Map && item['name'] == assetName) {
          final value = item['browser_download_url'];
          if (value is String) downloadUrl = value;
          final digest = item['digest'];
          if (digest is String && digest.startsWith('sha256:')) {
            expectedDigest = digest.substring('sha256:'.length).trim().toLowerCase();
          }
          final size = item['size'];
          if (size is num) expectedAssetSize = size.toInt();
          break;
        }
      }

      if (downloadUrl == null || !downloadUrl.startsWith('https://github.com/')) {
        return (
          success: false,
          path: null,
          message: 'حزمة ' + assetName + ' غير منشورة في إصدار Userland الحالي.',
        );
      }

      onProgress?.call('بدء تنزيل Userland الحقيقي...');
      final request = http.Request('GET', Uri.parse(downloadUrl))
        ..headers['User-Agent'] = 'Zion-OS-Userland';
      final response = await client.send(request).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        return (
          success: false,
          path: null,
          message: 'فشل تنزيل Userland (HTTP ' +
              response.statusCode.toString() + ').',
        );
      }

      final expected = response.contentLength ?? expectedAssetSize;
      if (expected != null && expected > _maxDownloadBytes) {
        return (
          success: false,
          path: null,
          message: 'حجم Userland المنشور يتجاوز الحد المسموح.',
        );
      }

      final sink = temp.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        received += chunk.length;
        if (received > _maxDownloadBytes) {
          await sink.close();
          try { await temp.delete(); } catch (_) {}
          return (
            success: false,
            path: null,
            message: 'تم إيقاف تنزيل Userland لتجاوز الحد الأقصى للحجم.',
          );
        }
        sink.add(chunk);
        if (received % (1024 * 1024 * 4) < chunk.length) {
          onProgress?.call(
            'تم تنزيل ' +
            (received / (1024 * 1024)).toStringAsFixed(1) +
            ' MB' +
            (expected == null
                ? ''
                : ' من ' + (expected / (1024 * 1024)).toStringAsFixed(1) + ' MB'),
          );
        }
      }
      await sink.close();

      if (expectedAssetSize != null && received != expectedAssetSize) {
        try { await temp.delete(); } catch (_) {}
        return (
          success: false,
          path: null,
          message: 'حجم حزمة Userland لا يطابق بيانات الإصدار المنشورة.',
        );
      }

      if (expectedDigest != null) {
        onProgress?.call('التحقق من SHA-256 للأرشيف المنشور...');
        final actualDigest = (await sha256.bind(temp.openRead()).first).toString().toLowerCase();
        if (actualDigest != expectedDigest) {
          try { await temp.delete(); } catch (_) {}
          return (
            success: false,
            path: null,
            message: 'فشل SHA-256 للأرشيف المنشور؛ تم رفض الحزمة.',
          );
        }
      }

      return (success: true, path: temp.path, message: null);
    } catch (e) {
      try {
        if (await temp.exists()) await temp.delete();
      } catch (_) {}
      return (
        success: false,
        path: null,
        message: 'تعذر تنزيل Zion Userland: ' + e.toString(),
      );
    } finally {
      client.close();
    }
  }
}
