import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import '../../security/core/security_core.dart';

enum BootstrapStatus { installed, notConfigured, failed }
class BootstrapResult {
  const BootstrapResult._(this.status, {this.error, this.installedFiles = 0});
  const BootstrapResult.success({int installedFiles = 0}) : this._(BootstrapStatus.installed, installedFiles: installedFiles);
  const BootstrapResult.failure(String error) : this._(BootstrapStatus.failed, error: error);
  const BootstrapResult.notConfigured(String reason) : this._(BootstrapStatus.notConfigured, error: reason);
  final BootstrapStatus status; final String? error; final int installedFiles;
  bool get success => status == BootstrapStatus.installed;
}
class ZionBootstrap {
  static const base = '/data/data/com.zion.os/files';
  static const home = base + '/home';
  static const prefix = base + '/usr';
  static const tmp = base + '/tmp';
  static const _maxArchiveBytes = 256 * 1024 * 1024;
  static const _maxFiles = 20000;
  const ZionBootstrap({SecurityCore? securityCore}) : _securityCore = securityCore;
  final SecurityCore? _securityCore;

  static Future<bool> isInstalled() async {
    final marker = File(prefix + '/etc/zion-release.json');
    final pkg = File(prefix + '/bin/zion-pkg');
    if (!await marker.exists() || !await pkg.exists()) return false;
    try { final value = jsonDecode(await marker.readAsString()); return value is Map<String,dynamic> && value['format'] == 'zion-userland-v1'; } catch (_) { return false; }
  }

  Future<BootstrapResult> installFromArchive(String archivePath, {void Function(double progress,String status)? onProgress}) async {
    final started = DateTime.now();
    try {
      onProgress?.call(0,'بدء التحقق من حزمة Zion Userland...');
      final source = File(archivePath);
      if (!await source.exists()) return _fail('الأرشيف غير موجود.');
      final length = await source.length();
      if (length <= 0 || length > _maxArchiveBytes) return _fail('حجم الأرشيف غير مسموح به.');
      final archive = ZipDecoder().decodeBytes(await source.readAsBytes(), verify: true);
      if (archive.files.length > _maxFiles) return _fail('الأرشيف يتجاوز الحد الأقصى لعدد الملفات.');
      final manifest = _readManifest(archive);
      if (manifest == null) return _fail('حزمة Zion Userland غير صالحة: zion-manifest.json مفقود.');
      if (manifest['format'] != 'zion-userland-v1') return _fail('إصدار حزمة Userland غير مدعوم.');
      final release = manifest['release'];
      if (release is! String || release.trim().isEmpty) return _fail('الحزمة لا تحتوي على release صالح.');
      final hashes = _readHashes(manifest['files']);
      if (hashes == null) return _fail('قائمة سلامة الملفات غير صالحة.');
      onProgress?.call(.05,'التحقق من SHA-256...');
      var checked = 0;
      for (final entry in archive.files) {
        if (!entry.isFile || entry.name == 'zion-manifest.json') continue;
        final relative = _safeRelativePath(entry.name);
        if (relative == null) return _fail('مسار غير آمن داخل الأرشيف.');
        final expected = hashes[relative];
        if (expected == null) return _fail('الملف غير موجود في manifest: ' + relative);
        final actual = sha256.convert(List<int>.from(entry.content as List<int>)).toString();
        if (actual.toLowerCase() != expected.toLowerCase()) return _fail('فشل تحقق SHA-256 للملف: ' + relative);
        checked++;
        if (checked % 100 == 0) onProgress?.call(.05 + checked / archive.files.length * .25,'التحقق: ' + checked.toString());
      }
      final staging = Directory(base + '/.bootstrap-staging-' + DateTime.now().microsecondsSinceEpoch.toString());
      await _createDirectoryStructure(staging.path);
      onProgress?.call(.35,'استخراج إلى مساحة مؤقتة...');
      var extracted = 0;
      for (final entry in archive.files) {
        if (!entry.isFile || entry.name == 'zion-manifest.json') continue;
        final relative = _safeRelativePath(entry.name);
        if (relative == null) return _fail('مسار غير آمن داخل الأرشيف.');
        final target = File(staging.path + '/' + relative);
        await target.parent.create(recursive:true);
        await target.writeAsBytes(List<int>.from(entry.content as List<int>));
        extracted++;
        if (extracted % 100 == 0) onProgress?.call(.35 + extracted / archive.files.length * .45,'استخراج: ' + extracted.toString());
      }
      final releaseFile = File(staging.path + '/usr/etc/zion-release.json');
      await releaseFile.parent.create(recursive:true);
      await releaseFile.writeAsString(jsonEncode(<String,Object?>{
        'format':'zion-userland-v1','release':release,
        'installedAt':DateTime.now().toUtc().toIso8601String(),
        'manifestSha256':sha256.convert(utf8.encode(jsonEncode(manifest))).toString(),
      }));
      await _createConfigFiles(staging.path); await _setPermissions(staging.path); await _activateStaging(staging);
      onProgress?.call(1,'اكتمل تثبيت Userland.');
      _audit('userland.bootstrap.install','success',{'release':release,'archiveBytes':length,'files':extracted,'durationMs':DateTime.now().difference(started).inMilliseconds,'source':'REAL_ARCHIVE'});
      return BootstrapResult.success(installedFiles:extracted);
    } catch(e) { return _fail('فشل تثبيت Userland: ' + e.toString()); }
  }
  static Future<void> _createDirectoryStructure(String root) async {
    for(final relative in <String>['home','usr','usr/bin','usr/sbin','usr/lib','usr/share','usr/etc','usr/var','usr/var/lib','usr/var/lib/zion-pkg','usr/var/cache','usr/tmp','tmp','etc']) await Directory(root + '/' + relative).create(recursive:true);
  }
  static Future<void> _createConfigFiles(String root) async {
    await File(root + '/home/.zionrc').writeAsString('export ZION_HOME="' + home + '"\nexport PREFIX="' + prefix + '"\nexport PATH="' + prefix + '/bin:' + prefix + '/sbin:/system/bin:/system/xbin"\nexport LD_LIBRARY_PATH="' + prefix + '/lib"\nexport TMPDIR="' + tmp + '"\nexport TERM="xterm-256color"\nexport COLORTERM="truecolor"\nexport LANG="C.UTF-8"\nexport LC_ALL="C.UTF-8"\n');
    final history=File(root + '/home/.zion_history'); if(!await history.exists()) await history.writeAsString('');
    final hosts=File(root + '/usr/etc/hosts'); if(!await hosts.exists()) await hosts.writeAsString('127.0.0.1 localhost\n::1 localhost\n');
    final resolv=File(root + '/usr/etc/resolv.conf'); if(!await resolv.exists()) await resolv.writeAsString('nameserver 1.1.1.1\nnameserver 8.8.8.8\n');
    final db=File(root + '/usr/var/lib/zion-pkg/installed.json'); if(!await db.exists()) await db.writeAsString('[]');
  }
  static Future<void> _setPermissions(String root) async { await _chmod(root + '/home','700'); await _chmod(root + '/usr/bin','755'); await _chmod(root + '/usr/sbin','755'); await _chmod(root + '/usr/lib','755'); }
  static Future<void> _chmod(String path,String mode) async { try { if(await Directory(path).exists()) await Process.run('/system/bin/chmod',['-R',mode,path]); } catch(_){} }
  static Future<void> _activateStaging(Directory staging) async {
    final current=Directory(prefix); final backup=Directory(base + '/.usr-previous-' + DateTime.now().microsecondsSinceEpoch.toString());
    if(await current.exists()) await current.rename(backup.path);
    try { await staging.rename(current.path); if(await backup.exists()) await backup.delete(recursive:true); }
    catch(_) { if(await backup.exists() && !await current.exists()) await backup.rename(current.path); rethrow; }
  }
  static Map<String,dynamic>? _readManifest(Archive archive) {
    for(final entry in archive.files) if(entry.name == 'zion-manifest.json' && entry.isFile) { try { final v=jsonDecode(utf8.decode(List<int>.from(entry.content as List<int>))); return v is Map<String,dynamic> ? v : null; } catch(_) { return null; } }
    return null;
  }
  static Map<String,String>? _readHashes(Object? value) {
    if(value is! Map) return null; final result=<String,String>{};
    for(final item in value.entries) { final normalized=_safeRelativePath(item.key.toString()); final hash=item.value.toString(); if(normalized==null || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) return null; result[normalized]=hash; }
    return result;
  }
  static String? _safeRelativePath(String path) {
    if(path.isEmpty || path.startsWith('/') || path.startsWith(r'\')) return null;
    final normalized=path.replaceAll(r'\','/'); final parts=normalized.split('/');
    if(parts.any((p)=>p.isEmpty || p=='.' || p=='..')) return null;
    const roots=<String>{'usr','home','tmp','etc'}; return roots.contains(parts.first) ? normalized : null;
  }
  BootstrapResult _fail(String message) { _audit('userland.bootstrap.install','failed',{'error':message,'source':'REAL_ARCHIVE'}); return BootstrapResult.failure(message); }
  void _audit(String action,String outcome,Map<String,Object?> metadata) { _securityCore?.auditLogger.log(action:action,actor:'zion-userland',outcome:outcome,target:'local-userland',metadata:metadata); }
  static Future<Map<String,Object?>> getInfo() async => !await isInstalled() ? {'installed':false} : {'installed':true,'prefix':prefix,'home':home,'bash':await File(prefix + '/bin/bash').exists(),'zionPkg':await File(prefix + '/bin/zion-pkg').exists()};
}
