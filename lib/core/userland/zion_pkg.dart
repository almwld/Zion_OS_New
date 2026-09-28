import 'dart:convert';
import 'dart:io';
import '../../security/core/security_core.dart';

enum PackageStatus { installed, available, system, notInstalled }
class PackageInfo {
  const PackageInfo({required this.name,required this.version,required this.installedAt,required this.source});
  final String name,version,source; final DateTime installedAt;
  factory PackageInfo.fromJson(Map<String,dynamic> json)=>PackageInfo(name:json['name'] as String,version:json['version'] as String,installedAt:DateTime.parse(json['installedAt'] as String),source:json['source'] as String);
  Map<String,Object?> toJson()=>{'name':name,'version':version,'installedAt':installedAt.toIso8601String(),'source':source};
}
class PkgResult {
  const PkgResult._({required this.success,this.message,this.error});
  const PkgResult.success(String message):this._(success:true,message:message);
  const PkgResult.failure(String error):this._(success:false,error:error);
  final bool success; final String? message,error;
}
class ZionPkg {
  static const prefix='/data/data/com.zion.os/files/usr';
  static const home='/data/data/com.zion.os/files/home';
  static const dbPath=prefix + '/var/lib/zion-pkg/installed.json';
  static const cacheDir=prefix + '/var/cache/zion-pkg';
  const ZionPkg({SecurityCore? securityCore}):_securityCore=securityCore;
  final SecurityCore? _securityCore;

  Future<List<PackageInfo>> getInstalledPackages() async {
    try { final db=File(dbPath); if(!await db.exists()) return <PackageInfo>[]; final decoded=jsonDecode(await db.readAsString()); if(decoded is! List) return <PackageInfo>[]; return decoded.whereType<Map>().map((e)=>PackageInfo.fromJson(Map<String,dynamic>.from(e))).toList(growable:false); } catch(_) { return <PackageInfo>[]; }
  }
  Future<PackageInfo?> findPackage(String name) async { for(final p in await getInstalledPackages()) if(p.name==name) return p; return null; }
  Future<PackageStatus> getStatus(String name) async {
    if(await findPackage(name)!=null) return PackageStatus.installed;
    if(await File(prefix + '/bin/' + name).exists()) return PackageStatus.available;
    final system=await _which(name); if(system!=null) return PackageStatus.system;
    return PackageStatus.notInstalled;
  }
  Future<PkgResult> installFromFile(String debPath) async {
    final file=File(debPath); if(!await file.exists()) return _fail('ملف الحزمة غير موجود.');
    if(!debPath.toLowerCase().endsWith('.deb')) return _fail('zion-pkg يدعم ملفات .deb فقط.');
    final dpkg=prefix + '/bin/dpkg', dpkgDeb=prefix + '/bin/dpkg-deb';
    if(!await _isFile(dpkg) || !await _isFile(dpkgDeb)) return _notConfigured('dpkg/dpkg-deb غير مثبتين داخل Zion Userland. لن يتم استخدام dpkg النظام.');
    final metadata=await Process.run(dpkgDeb,['-f',debPath,'Package','Version'],runInShell:false,environment:_environment());
    if(metadata.exitCode!=0) return _fail('ملف .deb غير صالح أو تعذر قراءة بياناته.');
    final lines=metadata.stdout.toString().trim().split(RegExp(r'\s+'));
    if(lines.length<2 || lines[0].isEmpty || lines[1].isEmpty) return _fail('بيانات Package/Version غير مكتملة.');
    final result=await Process.run(dpkg,['--root=' + prefix,'-i',debPath],runInShell:false,environment:_environment());
    if(result.exitCode!=0) return _fail('فشل تثبيت الحزمة: ' + result.stderr.toString().trim());
    await _record(PackageInfo(name:lines[0],version:lines[1],installedAt:DateTime.now().toUtc(),source:file.path));
    _audit('userland.pkg.install','success',{'package':lines[0],'version':lines[1],'source':'REAL_DPKG'});
    return const PkgResult.success('تم تثبيت الحزمة عبر dpkg الخاص بـ Zion Userland.');
  }
  Future<PkgResult> remove(String name) async {
    if(name.trim().isEmpty || name.contains('/') || name.contains('..')) return _fail('اسم الحزمة غير صالح.');
    final dpkg=prefix + '/bin/dpkg'; if(!await _isFile(dpkg)) return _notConfigured('dpkg غير مثبت داخل Zion Userland.');
    final r=await Process.run(dpkg,['--root=' + prefix,'-r',name],runInShell:false,environment:_environment());
    if(r.exitCode!=0) return _fail('فشل حذف الحزمة: ' + r.stderr.toString().trim());
    await _remove(name); _audit('userland.pkg.remove','success',{'package':name}); return const PkgResult.success('تم حذف الحزمة.');
  }
  Future<PkgResult> update()=>_aptAction(['update'],'userland.pkg.update');
  Future<PkgResult> upgrade()=>_aptAction(['upgrade','-y'],'userland.pkg.upgrade');
  Future<Map<String,PackageStatus>> checkTools() async {
    final result=<String,PackageStatus>{}; for(final n in ['bash','apt','dpkg','dpkg-deb','proot','ssh','curl','wget','git','python3']) result[n]=await getStatus(n); return result;
  }
  Future<PkgResult> _aptAction(List<String> args,String action) async {
    final apt=prefix + '/bin/apt'; if(!await _isFile(apt)) return _notConfigured('apt غير مثبت داخل Zion Userland.');
    await Directory(cacheDir).create(recursive:true); final r=await Process.run(apt,args,runInShell:false,environment:_environment());
    if(r.exitCode==0){_audit(action,'success',{'source':'REAL_APT'});return const PkgResult.success('اكتملت العملية عبر apt الخاص بـ Zion Userland.');}
    return _fail('فشلت عملية apt: ' + r.stderr.toString().trim());
  }
  Future<String?> _which(String name) async { try { final r=await Process.run('/system/bin/sh',['-c','command -v "' + name.replaceAll('"','') + '"'],runInShell:false); if(r.exitCode!=0)return null; final v=r.stdout.toString().trim(); return v.isEmpty?null:v; } catch(_){return null;} }
  Future<bool> _isFile(String path) async { try { return (await File(path).stat()).type==FileSystemEntityType.file; } catch(_){return false;} }
  Map<String,String> _environment()=>{'PREFIX':prefix,'HOME':home,'PATH':prefix + '/bin:/system/bin:/system/xbin','TMPDIR':prefix + '/tmp'};
  Future<void> _record(PackageInfo info) async { final p=(await getInstalledPackages()).toList()..removeWhere((e)=>e.name==info.name)..add(info); final db=File(dbPath); await db.parent.create(recursive:true); await db.writeAsString(const JsonEncoder.withIndent('  ').convert(p.map((e)=>e.toJson()).toList())); }
  Future<void> _remove(String name) async { final p=(await getInstalledPackages()).where((e)=>e.name!=name).toList(); final db=File(dbPath); await db.parent.create(recursive:true); await db.writeAsString(const JsonEncoder.withIndent('  ').convert(p.map((e)=>e.toJson()).toList())); }
  PkgResult _notConfigured(String m){_audit('userland.pkg.operation','not-configured',{'reason':m});return PkgResult.failure('NOT_CONFIGURED: ' + m);}
  PkgResult _fail(String m){_audit('userland.pkg.operation','failed',{'error':m});return PkgResult.failure(m);}
  void _audit(String a,String o,Map<String,Object?> m){_securityCore?.auditLogger.log(action:a,actor:'zion-pkg',outcome:o,target:'local-userland',metadata:m);}
}
