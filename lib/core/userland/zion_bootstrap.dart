import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import '../../security/core/security_core.dart';

enum BootstrapStatus { installed, notConfigured, failed }
class BootstrapResult {
  const BootstrapResult._(this.status,{this.error,this.installedFiles=0});
  const BootstrapResult.success({int installedFiles=0}):this._(BootstrapStatus.installed,installedFiles:installedFiles);
  const BootstrapResult.failure(String error):this._(BootstrapStatus.failed,error:error);
  const BootstrapResult.notConfigured(String reason):this._(BootstrapStatus.notConfigured,error:reason);
  final BootstrapStatus status; final String? error; final int installedFiles;
  bool get success=>status==BootstrapStatus.installed;
}
class ZionBootstrap {
  static const base='/data/data/com.zion.os/files';
  static const home=base+'/home', prefix=base+'/usr', tmp=base+'/tmp';
  static const _maxArchiveBytes=256*1024*1024, _maxFiles=20000;
  const ZionBootstrap({SecurityCore? securityCore}):_securityCore=securityCore;
  final SecurityCore? _securityCore;
  static Future<bool> isInstalled() async {
    final marker=File(prefix+'/etc/zion-release.json'), pkg=File(prefix+'/bin/zion-pkg');
    if(!await marker.exists()||!await pkg.exists())return false;
    try{final v=jsonDecode(await marker.readAsString());return v is Map<String,dynamic>&&v['format']=='zion-userland-v1';}catch(_){return false;}
  }
  Future<BootstrapResult> installFromArchive(String archivePath,{void Function(double,String)? onProgress}) async {
    final started=DateTime.now();
    try{
      onProgress?.call(0,'بدء التحقق من حزمة Zion Userland...');
      final source=File(archivePath); if(!await source.exists())return _fail('الأرشيف غير موجود.');
      final length=await source.length(); if(length<=0||length>_maxArchiveBytes)return _fail('حجم الأرشيف غير مسموح به.');
      final archive=ZipDecoder().decodeBytes(await source.readAsBytes(),verify:true);
      if(archive.files.length>_maxFiles)return _fail('الأرشيف يتجاوز الحد الأقصى لعدد الملفات.');
      final manifest=_manifest(archive); if(manifest==null)return _fail('حزمة Zion Userland غير صالحة: zion-manifest.json مفقود.');
      if(manifest['format']!='zion-userland-v1')return _fail('إصدار حزمة Userland غير مدعوم.');
      final release=manifest['release']; if(release is! String||release.trim().isEmpty)return _fail('الحزمة لا تحتوي على release صالح.');
      final hashes=_hashes(manifest['files']); if(hashes==null)return _fail('قائمة سلامة الملفات غير صالحة.');
      onProgress?.call(.05,'التحقق من SHA-256...');
      var checked=0;
      for(final e in archive.files){
        if(!e.isFile||e.name=='zion-manifest.json')continue;
        final p=_safe(e.name); if(p==null)return _fail('مسار غير آمن داخل الأرشيف.');
        final expected=hashes[p]; if(expected==null)return _fail('الملف غير موجود في manifest: '+p);
        final actual=sha256.convert(List<int>.from(e.content as List<int>)).toString();
        if(actual.toLowerCase()!=expected.toLowerCase())return _fail('فشل تحقق SHA-256 للملف: '+p);
        checked++;
      }
      if(checked!=hashes.length)return _fail('manifest يحتوي ملفات غير موجودة في الأرشيف.');
      final staging=Directory(base+'/.bootstrap-staging-'+DateTime.now().microsecondsSinceEpoch.toString());
      await _dirs(staging.path); var extracted=0;
      for(final e in archive.files){
        if(!e.isFile||e.name=='zion-manifest.json')continue;
        final p=_safe(e.name); if(p==null)return _fail('مسار غير آمن داخل الأرشيف.');
        final target=File(staging.path+'/'+p); await target.parent.create(recursive:true); await target.writeAsBytes(List<int>.from(e.content as List<int>)); extracted++;
        if(extracted%100==0)onProgress?.call(.35,'استخراج: '+extracted.toString());
      }
      final rel=File(staging.path+'/usr/etc/zion-release.json'); await rel.parent.create(recursive:true);
      await rel.writeAsString(jsonEncode({'format':'zion-userland-v1','release':release,'installedAt':DateTime.now().toUtc().toIso8601String(),'manifestSha256':sha256.convert(utf8.encode(jsonEncode(manifest))).toString()}));
      await _config(staging.path); await _activate(staging);
      _audit('userland.bootstrap.install','success',{'release':release,'files':extracted,'archiveBytes':length,'durationMs':DateTime.now().difference(started).inMilliseconds,'source':'REAL_ARCHIVE'});
      onProgress?.call(1,'اكتمل تثبيت Userland.');
      return BootstrapResult.success(installedFiles:extracted);
    }catch(e){return _fail('فشل تثبيت Userland: '+e.toString());}
  }
  static Future<void> _dirs(String root) async {for(final p in ['home','usr','usr/bin','usr/sbin','usr/lib','usr/share','usr/etc','usr/var/lib/zion-pkg','usr/var/cache','usr/tmp','tmp','etc'])await Directory(root+'/'+p).create(recursive:true);}
  static Future<void> _config(String root) async {
    await File(root+'/home/.zionrc').writeAsString('export ZION_HOME="'+home+'"\nexport PREFIX="'+prefix+'"\nexport PATH="'+prefix+'/bin:'+prefix+'/sbin:/system/bin:/system/xbin"\nexport LD_LIBRARY_PATH="'+prefix+'/lib"\nexport TMPDIR="'+tmp+'"\nexport TERM="xterm-256color"\nexport COLORTERM="truecolor"\nexport LANG="C.UTF-8"\nexport LC_ALL="C.UTF-8"\n');
    final h=File(root+'/home/.zion_history');if(!await h.exists())await h.writeAsString('');
    final hosts=File(root+'/usr/etc/hosts');if(!await hosts.exists())await hosts.writeAsString('127.0.0.1 localhost\n::1 localhost\n');
    final db=File(root+'/usr/var/lib/zion-pkg/installed.json');if(!await db.exists())await db.writeAsString('[]');
  }
  static Future<void> _activate(Directory staging) async {
    final current=Directory(prefix),backup=Directory(base+'/.usr-previous-'+DateTime.now().microsecondsSinceEpoch.toString());
    if(await current.exists())await current.rename(backup.path);
    try{await staging.rename(current.path);if(await backup.exists())await backup.delete(recursive:true);}catch(_){if(await backup.exists()&&!await current.exists())await backup.rename(current.path);rethrow;}
  }
  static Map<String,dynamic>? _manifest(Archive a){for(final e in a.files)if(e.isFile&&e.name=='zion-manifest.json'){try{final v=jsonDecode(utf8.decode(List<int>.from(e.content as List<int>)));return v is Map<String,dynamic>?v:null;}catch(_){return null;}}return null;}
  static Map<String,String>? _hashes(Object? v){if(v is! Map)return null;final out=<String,String>{};for(final x in v.entries){final p=_safe(x.key.toString()),h=x.value.toString();if(p==null||!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(h))return null;out[p]=h;}return out;}
  static String? _safe(String path){if(path.isEmpty||path.startsWith('/')||path.startsWith(r'\'))return null;final n=path.replaceAll(r'\','/'),parts=n.split('/');if(parts.any((p)=>p.isEmpty||p=='.'||p=='..'))return null;return const {'usr','home','tmp','etc'}.contains(parts.first)?n:null;}
  BootstrapResult _fail(String m){_audit('userland.bootstrap.install','failed',{'error':m,'source':'REAL_ARCHIVE'});return BootstrapResult.failure(m);}
  void _audit(String a,String o,Map<String,Object?>m){_securityCore?.auditLogger.log(action:a,actor:'zion-userland',outcome:o,target:'local-userland',metadata:m);}
  static Future<Map<String,Object?>> getInfo() async=>!await isInstalled()?{'installed':false}:{'installed':true,'prefix':prefix,'home':home,'bash':await File(prefix+'/bin/bash').exists(),'zionPkg':await File(prefix+'/bin/zion-pkg').exists()};
}
