import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'zion_bootstrap.dart';

class ZionUserlandInstallResult {
  const ZionUserlandInstallResult({required this.success, required this.message, this.releaseTag});
  final bool success; final String message; final String? releaseTag;
}

class ZionUserlandInstaller {
  const ZionUserlandInstaller();
  static const _bootstrapEndpoint = 'https://api.github.com/repos/almwld/Zion_OS_New/releases/tags/zion-userland-latest';
  static const _maxDownloadBytes = 256 * 1024 * 1024;

  String? _assetNameForAbi() {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) return 'zion-userland-aarch64.zip';
    if (abi == Abi.androidArm) return 'zion-userland-arm.zip';
    if (abi == Abi.androidX64) return 'zion-userland-x86_64.zip';
    return null;
  }

  Future<ZionUserlandInstallResult> installLatest({void Function(String message)? onProgress}) async {
    final abi = Abi.current();
    onProgress?.call('اكتشاف معمارية الجهاز: ' + abi.toString());
    if (!ZionBootstrap.isSupportedAndroidAbi()) {
      return ZionUserlandInstallResult(success: false, message: 'معمارية Android غير مدعومة حاليًا: ' + abi.toString());
    }
    if (await ZionBootstrap.isInstalled()) {
      await ZionBootstrap.initializeRuntime();
      return ZionUserlandInstallResult(success: true, message: 'Zion Userland مثبت بالفعل.', releaseTag: await ZionBootstrap.currentRelease());
    }
    final asset = _assetNameForAbi();
    if (asset == null) return ZionUserlandInstallResult(success: false, message: 'لا توجد حزمة Userland لهذه المعمارية: ' + abi.toString());
    final remote = await _downloadFromBootstrapEndpoint(asset, onProgress: onProgress);
    if (!remote.success || remote.path == null) return ZionUserlandInstallResult(success: false, message: remote.message ?? 'تعذر تنزيل Zion Userland.');
    try {
      onProgress?.call('التحقق من الحزمة ثم تثبيت Userland الحقيقي...');
      final result = await ZionBootstrap().installFromArchive(remote.path!, onProgress: (progress, message) => onProgress?.call('[' + (progress * 100).round().toString() + '%] ' + message));
      if (!result.success) return ZionUserlandInstallResult(success: false, message: result.error ?? 'فشل تثبيت Userland.');
      return ZionUserlandInstallResult(success: true, message: 'تم تنزيل وتثبيت Zion Userland بنجاح.', releaseTag: await ZionBootstrap.currentRelease());
    } finally {
      try { await File(remote.path!).delete(); } catch (_) {}
    }
  }

  Future<({bool success, String? path, String? message})> _downloadFromBootstrapEndpoint(String assetName, {void Function(String message)? onProgress}) async {
    final client = http.Client();
    try {
      final support = await getApplicationSupportDirectory();
      final downloadDir = Directory(support.path + '/zion/bootstrap-downloads');
      await downloadDir.create(recursive: true);
      final temp = File(downloadDir.path + '/' + assetName + '.download');
      onProgress?.call('الاتصال بمصدر Zion Bootstrap...');
      final releaseResponse = await client.get(Uri.parse(_bootstrapEndpoint), headers: const {'Accept': 'application/vnd.github+json', 'User-Agent': 'Zion-OS-Userland'}).timeout(const Duration(seconds: 30));
      if (releaseResponse.statusCode != 200) return (success: false, path: null, message: 'مصدر Zion Bootstrap غير متاح حاليًا (HTTP ' + releaseResponse.statusCode.toString() + ').');
      final decoded = jsonDecode(releaseResponse.body);
      if (decoded is! Map) return (success: false, path: null, message: 'استجابة Bootstrap غير صالحة.');
      final assets = decoded['assets'];
      if (assets is! List) return (success: false, path: null, message: 'مصدر Bootstrap لا يحتوي على حزم منشورة.');
      String? downloadUrl;
      for (final item in assets) {
        if (item is Map && item['name'] == assetName) {
          final candidate = item['browser_download_url'];
          if (candidate is String && candidate.startsWith('https://github.com/')) downloadUrl = candidate;
          break;
        }
      }
      if (downloadUrl == null) return (success: false, path: null, message: 'الحزمة ' + assetName + ' غير منشورة في إصدار Bootstrap الحالي.');
      onProgress?.call('تنزيل ' + assetName + ' إلى مساحة التطبيق الخاصة...');
      final request = http.Request('GET', Uri.parse(downloadUrl))..headers['User-Agent'] = 'Zion-OS-Userland';
      final response = await client.send(request).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return (success: false, path: null, message: 'فشل تنزيل Bootstrap (HTTP ' + response.statusCode.toString() + ').');
      final expected = response.contentLength;
      if (expected != null && expected > _maxDownloadBytes) return (success: false, path: null, message: 'حجم Bootstrap يتجاوز الحد المسموح.');
      if (await temp.exists()) await temp.delete();
      final sink = temp.openWrite(); var received = 0;
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          if (received > _maxDownloadBytes) throw StateError('Bootstrap تجاوز الحد الأقصى للحجم.');
          sink.add(chunk);
          if (received % (4 * 1024 * 1024) < chunk.length) {
            final downloaded = (received / (1024 * 1024)).toStringAsFixed(1);
            final total = expected == null ? '' : ' / ' + (expected / (1024 * 1024)).toStringAsFixed(1) + ' MB';
            onProgress?.call('Bootstrap: ' + downloaded + total + ' MB');
          }
        }
      } finally { await sink.close(); }
      if (!await temp.exists() || await temp.length() == 0) return (success: false, path: null, message: 'تم تنزيل Bootstrap فارغًا.');
      onProgress?.call('تم تنزيل Bootstrap؛ يبدأ الآن التحقق والتثبيت.');
      return (success: true, path: temp.path, message: null);
    } catch (e) {
      return (success: false, path: null, message: 'تعذر تنزيل Zion Bootstrap: ' + e.toString());
    } finally { client.close(); }
  }
}