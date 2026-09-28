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
      await _activate(staging); await _config();
      _audit('userland.bootstrap.install','success',{'release':release,'files':extracted,'archiveBytes':length,'durationMs':DateTime.now().difference(started).inMilliseconds,'source':'REAL_ARCHIVE'});
      onProgress?.call(1,'اكتمل تثبيت Userland.');
      return BootstrapResult.success(installedFiles:extracted);
    }catch(e){return _fail('فشل تثبيت Userland: '+e.toString());}
  }
  static Future<void> _dirs(String root) async {for(final p in ['home','usr','usr/bin','usr/sbin','usr/lib','usr/share','usr/etc','usr/var/lib/zion-pkg','usr/var/cache','usr/tmp','tmp','etc'])await Directory(root+'/'+p).create(recursive:true);}
  static const Map<String, String> _zionApiScripts = {
    'zion-api-dispatch': r'''#!/system/bin/sh
set -eu
PREFIX="${PREFIX:-/data/data/com.zion.os/files/usr}"
RESULTS="$PREFIX/tmp/zion-api-results"
mkdir -p "$RESULTS"
method="${1:-}"
[ -n "$method" ] || { echo '{"available":false,"status":"UNAVAILABLE","reason":"Zion API method is required."}'; exit 2; }
shift
id="zion-$(date +%s 2>/dev/null)-$"
result="$RESULTS/$id.json"
rm -f "$result"
am start -n com.zion.os/.MainActivity -a com.zion.os.ZION_API --es method "$method" --es requestId "$id" "$@" >/dev/null 2>&1 || {
  echo '{"available":false,"status":"UNAVAILABLE","reason":"Unable to start Zion API bridge."}'; exit 1;
}
i=0
while [ "$i" -lt 100 ]; do
  if [ -s "$result" ]; then
    cat "$result"
    rm -f "$result"
    exit 0
  fi
  i=$((i+1))
  sleep 0.05
done
echo '{"available":false,"status":"UNAVAILABLE","reason":"Zion API response timeout."}'
exit 1
''',
    'zion-api-battery': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" battery\n',
    'zion-api-device-info': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" device-info\n',
    'zion-api-wifi-info': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" wifi-info\n',
    'zion-api-sensor': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" sensor "${@:-}"\n',
    'zion-api-camera-photo': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" camera-photo\n',
    'zion-api-camera-info': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" camera-info\n',
    'zion-api-media-player': '#!/system/bin/sh\nP="${1:?path required}"; M="${2:-*/*}"; exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" media-player --es path "$P" --es mime "$M"\n',
    'zion-api-audio-record': '#!/system/bin/sh\nif [ "${1:-start}" = "stop" ]; then exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" audio-record --ez stop true; else exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" audio-record --ez stop false; fi\n',
    'zion-api-location': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" location\n',
    'zion-api-gps-status': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" gps-status\n',
    'zion-api-notification': '#!/system/bin/sh\nT="${1:-Zion OS}"; C="${2:-}"; exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" notification --es title "$T" --es content "$C"\n',
    'zion-api-toast': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" toast --es text "${*:-}"\n',
    'zion-api-dialog': '#!/system/bin/sh\nT="${1:-Zion OS}"; M="${2:-}"; exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" dialog --es title "$T" --es message "$M"\n',
    'zion-api-vibrate': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" vibrate --el durationMs "${1:-250}"\n',
    'zion-api-clipboard-get': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" clipboard-get\n',
    'zion-api-clipboard-set': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" clipboard-set --es text "${*:-}"\n',
    'zion-api-tts-speak': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" tts-speak --es text "${*:-}"\n',
    'zion-api-tts-stop': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" tts-stop\n',
    'zion-api-sms-list': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" sms-list\n',
    'zion-api-sms-send': '#!/system/bin/sh\nN="${1:?number required}"; shift; exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" sms-send --es number "$N" --es body "${*:-}"\n',
    'zion-api-call': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" call --es number "${1:?number required}"\n',
    'zion-api-contacts-list': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" contacts-list\n',
    'zion-setup-storage': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" setup-storage\n',
    'zion-api-storage-get': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" storage-get\n',
    'zion-api-file-share': '#!/system/bin/sh\nP="${1:?path required}"; M="${2:-*/*}"; exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" file-share --es path "$P" --es mime "$M"\n',
    'zion-api-fingerprint': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" fingerprint\n',
    'zion-api-keystore': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" keystore --es alias "${1:-zion-api}"\n',
    'zion-api-wake-lock': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" wake-lock --ez enabled true\n',
    'zion-api-wake-unlock': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" wake-lock --ez enabled false\n',
    'zion-api-job-scheduler': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" job-scheduler --ei jobId "${1:-1}" --el delayMs "${2:-1000}"\n',
    'zion-api-brightness': '#!/system/bin/sh\nexec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-call" brightness --ei value "${1:?value 0..255 required}"\n',
  };

  static Future<void> _installZionApiScripts() async {
    final bin = Directory(prefix + '/bin');
    await bin.create(recursive: true);
    for (final e in _zionApiScripts.entries) {
      final file = File(bin.path + '/' + e.key);
      await file.writeAsString(e.value);
      try { await Process.run('chmod', <String>['700', file.path], runInShell: false); } catch (_) {}
    }
  }

  static Future<void> _config() async {
    await Directory(home).create(recursive:true);
    await File(home+'/.zionrc').writeAsString('export ZION_HOME="'+home+'"\nexport PREFIX="'+prefix+'"\nexport PATH="'+prefix+'/bin:'+prefix+'/sbin:/system/bin:/system/xbin"\nexport LD_LIBRARY_PATH="'+prefix+'/lib"\nexport TMPDIR="'+tmp+'"\nexport TERM="xterm-256color"\nexport COLORTERM="truecolor"\nexport LANG="C.UTF-8"\nexport LC_ALL="C.UTF-8"\n');
    final h=File(home+'/.zion_history');if(!await h.exists())await h.writeAsString('');
    final hosts=File(prefix+'/etc/hosts');if(!await hosts.exists())await hosts.writeAsString('127.0.0.1 localhost\n::1 localhost\n');
    final db=File(prefix+'/var/lib/zion-pkg/installed.json');if(!await db.exists())await db.writeAsString('[]');
    await _installZionApiScripts();
  }
  static Future<void> _activate(Directory staging) async {
    final stagedPrefix=Directory(staging.path+'/usr');
    if(!await stagedPrefix.exists())throw StateError('حزمة Userland لا تحتوي على usr صالح.');
    final current=Directory(prefix),backup=Directory(base+'/.usr-previous-'+DateTime.now().microsecondsSinceEpoch.toString());
    if(await current.exists())await current.rename(backup.path);
    try{await stagedPrefix.rename(current.path);if(await backup.exists())await backup.delete(recursive:true);if(await staging.exists())await staging.delete(recursive:true);}catch(_){if(await backup.exists()&&!await current.exists())await backup.rename(current.path);if(await staging.exists())await staging.delete(recursive:true);rethrow;}
  }
  static Map<String,dynamic>? _manifest(Archive a){for(final e in a.files)if(e.isFile&&e.name=='zion-manifest.json'){try{final v=jsonDecode(utf8.decode(List<int>.from(e.content as List<int>)));return v is Map<String,dynamic>?v:null;}catch(_){return null;}}return null;}
  static Map<String,String>? _hashes(Object? v){if(v is! Map)return null;final out=<String,String>{};for(final x in v.entries){final p=_safe(x.key.toString()),h=x.value.toString();if(p==null||!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(h))return null;out[p]=h;}return out;}
  static String? _safe(String path){if(path.isEmpty||path.startsWith('/')||path.startsWith(r'\'))return null;final n=path.replaceAll(r'\','/'),parts=n.split('/');if(parts.any((p)=>p.isEmpty||p=='.'||p=='..'))return null;return const {'usr','home','tmp','etc'}.contains(parts.first)?n:null;}
  BootstrapResult _fail(String m){_audit('userland.bootstrap.install','failed',{'error':m,'source':'REAL_ARCHIVE'});return BootstrapResult.failure(m);}
  void _audit(String a,String o,Map<String,Object?>m){_securityCore?.auditLogger.log(action:a,actor:'zion-userland',outcome:o,target:'local-userland',metadata:m);}
  static Future<Map<String,Object?>> getInfo() async=>!await isInstalled()?{'installed':false}:{'installed':true,'prefix':prefix,'home':home,'bash':await File(prefix+'/bin/bash').exists(),'zionPkg':await File(prefix+'/bin/zion-pkg').exists()};
}
