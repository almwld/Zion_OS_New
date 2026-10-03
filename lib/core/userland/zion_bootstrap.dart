import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ffi';
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
  static const _backupRoot = base + '/.bootstrap-backups';
  static const _maxBackups = 2;

  static bool isSupportedAndroidAbi() {
    final abi = Abi.current();
    return abi == Abi.androidArm64 ||
        abi == Abi.androidArm ||
        abi == Abi.androidX64;
  }

  static Future<BootstrapResult> prepareExistingUserlandBackup({
    void Function(String message)? onProgress,
  }) async {
    if (!isSupportedAndroidAbi()) {
      return BootstrapResult.failure('ABI غير مدعوم: ${Abi.current()}');
    }
    final current = Directory(prefix);
    if (!await current.exists()) {
      return BootstrapResult.failure('Zion Userland غير موجود على الجهاز: $prefix');
    }
    if (!await _hasUsableShell(current.path)) {
      return BootstrapResult.failure('الـ bootstrap الموجود على الجهاز لا يحتوي Bash صالحاً.');
    }
    final root = Directory(_backupRoot);
    await root.create(recursive: true);
    final abi = Abi.current().toString();
    final sourceRelease = await _releaseValue(File(current.path + '/etc/zion-release.json'));
    final fingerprint = await _fingerprint(current);
    if (await _hasMatchingBackup(root, abi: abi, release: sourceRelease, fingerprint: fingerprint)) {
      onProgress?.call('النسخة الاحتياطية المحلية الحالية مطابقة لـ Userland؛ لن يتم إنشاء نسخة مكررة.');
      await _config();
      return BootstrapResult.success();
    }

    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
    final backup = Directory(root.path + '/usr-' + stamp);
    onProgress?.call('إنشاء نسخة احتياطية محلية من Userland الموجود على الجهاز...');
    await _copyDirectory(current, backup);
    final meta = File(backup.path + '/etc/zion-backup.json');
    await meta.parent.create(recursive: true);
    await meta.writeAsString(jsonEncode({
      'format': 'zion-userland-backup-v2',
      'abi': abi,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'sourcePrefix': prefix,
      'sourceRelease': sourceRelease,
      'fingerprint': fingerprint,
    }), flush: true);
    await _trimBackups();
    await _config();
    return BootstrapResult.success();
  }

  static Future<String> currentRelease() async =>
      _releaseValue(File(prefix + '/etc/zion-release.json'));

  static Future<bool> _hasUsableShell(String root) async {
    final bash = File(root + '/bin/bash');
    if (!await bash.exists()) return false;
    try {
      final r = await Process.run(bash.path, const ['-c', 'exit 0'], runInShell: false);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<String> _releaseValue(File marker) async {
    if (!await marker.exists()) return 'unknown';
    try {
      final v = jsonDecode(await marker.readAsString());
      return v is Map ? (v['release']?.toString() ?? 'unknown') : 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<String> _fingerprint(Directory root) async {
    final entries = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      final relative = entity.path.substring(root.path.length + 1);
      final stat = await entity.stat();
      var target = '';
      if (entity is Link) {
        try { target = await entity.target(); } catch (_) {}
      }
      entries.add(
        '${stat.type}|$relative|${stat.size}|${stat.modified.microsecondsSinceEpoch}|$target',
      );
    }
    entries.sort();
    return sha256.convert(utf8.encode(entries.join('\n'))).toString();
  }

  static Future<bool> _hasMatchingBackup(
    Directory root, {
    required String abi,
    required String release,
    required String fingerprint,
  }) async {
    final dirs = (await root.list(followLinks: false).where((e) => e is Directory).toList())
        .cast<Directory>();
    for (final backup in dirs) {
      final meta = File(backup.path + '/etc/zion-backup.json');
      if (!await meta.exists()) continue;
      try {
        final value = jsonDecode(await meta.readAsString());
        if (value is Map &&
            value['format'] == 'zion-userland-backup-v2' &&
            value['abi'] == abi &&
            value['sourceRelease'] == release &&
            value['fingerprint'] == fingerprint &&
            await _hasUsableShell(backup.path)) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  static Future<bool> _backupMatchesAbi(Directory backup, String abi) async {
    final meta = File(backup.path + '/etc/zion-backup.json');
    if (!await meta.exists()) return false;
    try {
      final value = jsonDecode(await meta.readAsString());
      return value is Map && value['abi'] == abi;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await _copyMode(source.path, target.path);
    await for (final entity in source.list(followLinks: false)) {
      final name = entity.path.substring(source.path.length + 1);
      final destination = target.path + '/' + name;
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await File(destination).parent.create(recursive: true);
        await entity.copy(destination);
        await _copyMode(entity.path, destination);
      } else if (entity is Link) {
        await Link(destination).parent.create(recursive: true);
        await Link(destination).create(await entity.target());
      }
    }
  }

  static Future<void> _copyMode(String source, String destination) async {
    try {
      final mode = (await FileStat.stat(source)).mode & 0x1ff;
      await Process.run('/system/bin/chmod', <String>[
        mode.toRadixString(8),
        destination,
      ], runInShell: false);
    } catch (_) {}
  }

  static Future<void> _trimBackups() async {
    final root = Directory(_backupRoot);
    if (!await root.exists()) return;
    final dirs = (await root.list(followLinks: false).where((e) => e is Directory).toList())
        .cast<Directory>();
    dirs.sort((a, b) => b.path.compareTo(a.path));
    for (var i = _maxBackups; i < dirs.length; i++) {
      try { await dirs[i].delete(recursive: true); } catch (_) {}
    }
  }

  static Future<bool> restoreLatestBackup() async {
    final root = Directory(_backupRoot);
    if (!await root.exists()) return false;
    final dirs = (await root.list(followLinks: false).where((e) => e is Directory).toList())
        .cast<Directory>();
    dirs.sort((a, b) => b.path.compareTo(a.path));
    final abi = Abi.current().toString();
    for (final backup in dirs) {
      if (!await _backupMatchesAbi(backup, abi)) continue;
      if (!await _hasUsableShell(backup.path)) continue;

      final current = Directory(prefix);
      final failed = Directory(base + '/.usr-failed-' + DateTime.now().microsecondsSinceEpoch.toString());
      final staging = Directory(base + '/.usr-restore-' + DateTime.now().microsecondsSinceEpoch.toString());
      try {
        // Copy instead of consuming the backup so the last known-good copy
        // remains available for a second rollback.
        await _copyDirectory(backup, staging);
        if (await current.exists()) await current.rename(failed.path);
        await staging.rename(current.path);
        if (await failed.exists()) await failed.delete(recursive: true);
        await _config();
        return await isInstalled();
      } catch (_) {
        try {
          if (await staging.exists()) await staging.delete(recursive: true);
        } catch (_) {}
        if (!await current.exists() && await failed.exists()) {
          try { await failed.rename(current.path); } catch (_) {}
        }
      }
    }
    return false;
  }

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
  static Future<void> _dirs(String root) async {for(final p in ['home','tmp','etc','usr','usr/bin','usr/sbin','usr/etc','usr/include','usr/lib','usr/libexec','usr/share','usr/tmp','usr/var','usr/var/lib','usr/var/lib/zion-pkg','usr/var/cache','usr/var/log'])await Directory(root+'/'+p).create(recursive:true);}
  static final Map<String, String> _zionApiScripts = {
    'zion-pkg': r'''#!/data/data/com.zion.os/files/usr/bin/bash
set -eu
PREFIX="${PREFIX:-/data/data/com.zion.os/files/usr}"
TOKEN_FILE="/data/data/com.zion.os/files/etc/zion-pkg.token"
RESULTS="$PREFIX/tmp/zion-pkg-results"
mkdir -p "$RESULTS"
[ -r "$TOKEN_FILE" ] || { echo 'UNAVAILABLE: zion-pkg token is not configured.'; exit 1; }
[ "$#" -le 2 ] || { echo 'Usage: zion-pkg <command> [argument]'; exit 2; }
command="${1:-help}"
value="${2:-}"
id="zion-pkg-$(date +%s 2>/dev/null)-$"
out="$RESULTS/$id.out"
status="$RESULTS/$id.status"
rm -f "$out" "$status"
am start -n com.zion.os/.MainActivity -a com.zion.os.ZION_PKG --es command "$command" --es value "$value" --es requestId "$id" --es token "$(cat "$TOKEN_FILE")" >/dev/null 2>&1 || {
  echo 'UNAVAILABLE: unable to start Zion package bridge.'
  exit 1
}
i=0
while [ "$i" -lt 200 ]; do
  if [ -s "$out" ] && [ -s "$status" ]; then
    cat "$out"
    rc="$(cat "$status")"
    rm -f "$out" "$status"
    exit "${rc:-1}"
  fi
  i=$((i+1))
  sleep 0.05
done
echo 'UNAVAILABLE: Zion package bridge timeout.'
rm -f "$out" "$status"
exit 1
''',

    'zion-api-dispatch': r'''#!/data/data/com.zion.os/files/usr/bin/bash
set -eu
PREFIX="${PREFIX:-/data/data/com.zion.os/files/usr}"
RESULTS="$PREFIX/tmp/zion-api-results"
TOKEN_FILE="/data/data/com.zion.os/files/etc/zion-api.token"
mkdir -p "$RESULTS"
[ -r "$TOKEN_FILE" ] || { echo '{"available":false,"status":"UNAVAILABLE","reason":"Zion API token is not configured."}'; exit 1; }
[ "$#" -le 32 ] || { echo '{"available":false,"status":"INVALID","reason":"Too many Zion API arguments."}'; exit 2; }
method="${1:-}"
[ -n "$method" ] || { echo '{"available":false,"status":"UNAVAILABLE","reason":"Zion API method is required."}'; exit 2; }
shift
id="zion-$(date +%s 2>/dev/null)-$$"
result="$RESULTS/$id.json"
rm -f "$result"
am start -n com.zion.os/.MainActivity -a com.zion.os.ZION_API --es method "$method" --es requestId "$id" --es token "$(cat "$TOKEN_FILE")" "$@" >/dev/null 2>&1 || {
  echo '{"available":false,"status":"UNAVAILABLE","reason":"Unable to start Zion API bridge."}'; exit 1;
}
i=0
while [ "$i" -lt 100 ]; do
  if [ -s "$result" ]; then cat "$result"; rm -f "$result"; exit 0; fi
  i=$((i+1)); sleep 0.05
done
echo '{"available":false,"status":"UNAVAILABLE","reason":"Zion API response timeout."}'
exit 1
''',
    'zion-api-battery': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" battery
''',
    'zion-api-device-info': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" device-info
''',
    'zion-api-wifi-info': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" wifi-info
''',
    'zion-api-sensor': r'''#!/data/data/com.zion.os/files/usr/bin/bash
if [ -n "${1:-}" ]; then exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" sensor --ei type "$1"; else exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" sensor; fi
''',
    'zion-api-camera-photo': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" camera-photo
''',
    'zion-api-camera-info': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" camera-info
''',
    'zion-api-media-player': r'''#!/data/data/com.zion.os/files/usr/bin/bash
P="${1:?path required}"; M="${2:-*/*}"
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" media-player --es path "$P" --es mime "$M"
''',
    'zion-api-audio-record': r'''#!/data/data/com.zion.os/files/usr/bin/bash
if [ "${1:-start}" = "stop" ]; then exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" audio-record --ez stop true; else exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" audio-record --ez stop false; fi
''',
    'zion-api-location': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" location
''',
    'zion-api-gps-status': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" gps-status
''',
    'zion-api-notification': r'''#!/data/data/com.zion.os/files/usr/bin/bash
T="${1:-Zion OS}"; C="${2:-}"
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" notification --es title "$T" --es content "$C"
''',
    'zion-api-toast': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" toast --es text "$*"
''',
    'zion-api-dialog': r'''#!/data/data/com.zion.os/files/usr/bin/bash
T="${1:-Zion OS}"; M="${2:-}"
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" dialog --es title "$T" --es message "$M"
''',
    'zion-api-vibrate': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" vibrate --el durationMs "${1:-250}"
''',
    'zion-api-clipboard-get': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" clipboard-get
''',
    'zion-api-clipboard-set': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" clipboard-set --es text "$*"
''',
    'zion-api-tts-speak': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" tts-speak --es text "$*"
''',
    'zion-api-tts-stop': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" tts-stop
''',
    'zion-api-sms-list': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" sms-list
''',
    'zion-api-sms-send': r'''#!/data/data/com.zion.os/files/usr/bin/bash
N="${1:?number required}"; shift
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" sms-send --es number "$N" --es body "$*"
''',
    'zion-api-call': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" call --es number "${1:?number required}"
''',
    'zion-api-contacts-list': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" contacts-list
''',
    'zion-setup-storage': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" setup-storage
''',
    'zion-api-storage-get': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" storage-get
''',
    'zion-api-file-share': r'''#!/data/data/com.zion.os/files/usr/bin/bash
P="${1:?path required}"; M="${2:-*/*}"
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" file-share --es path "$P" --es mime "$M"
''',
    'zion-api-fingerprint': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" fingerprint
''',
    'zion-api-keystore': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" keystore --es alias "${1:-zion-api}"
''',
    'zion-api-wake-lock': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" wake-lock --ez enabled true
''',
    'zion-api-wake-unlock': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" wake-lock --ez enabled false
''',
    'zion-api-job-scheduler': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" job-scheduler --ei jobId "${1:-1}" --el delayMs "${2:-1000}"
''',
    'zion-api-brightness': r'''#!/data/data/com.zion.os/files/usr/bin/bash
exec "${PREFIX:-/data/data/com.zion.os/files/usr}/bin/zion-api-dispatch" brightness --ei value "${1:?value 0..255 required}"
''',
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

  static Future<void> initializeRuntime() async => _config();
  static Future<void> _config() async {
    await Directory(home).create(recursive:true);
    await File(home+'/.zionrc').writeAsString('export ZION_HOME="'+home+'"\nexport PREFIX="'+prefix+'"\nexport PATH="'+prefix+'/bin:'+prefix+'/sbin:/system/bin:/system/xbin"\nexport LD_LIBRARY_PATH="'+prefix+'/lib"\nexport TMPDIR="'+tmp+'"\nexport TERM="xterm-256color"\nexport COLORTERM="truecolor"\nexport LANG="C.UTF-8"\nexport LC_ALL="C.UTF-8"\n');
    final h=File(home+'/.zion_history');if(!await h.exists())await h.writeAsString('');
    final hosts=File(prefix+'/etc/hosts');if(!await hosts.exists())await hosts.writeAsString('127.0.0.1 localhost\n::1 localhost\n');
    final db=File(prefix+'/var/lib/zion-pkg/installed.json');if(!await db.exists())await db.writeAsString('[]');
    final tokenFile=File(base+'/etc/zion-pkg.token');
    if(!await tokenFile.exists()){
      final random=Random.secure();
      final token=List<String>.generate(32,(_)=>random.nextInt(256).toRadixString(16).padLeft(2,'0')).join();
      await tokenFile.parent.create(recursive:true);
      await tokenFile.writeAsString(token,flush:true);
    }
    final apiTokenFile=File(base+'/etc/zion-api.token');
    if(!await apiTokenFile.exists()){
      final random=Random.secure();
      final token=List<String>.generate(32,(_)=>random.nextInt(256).toRadixString(16).padLeft(2,'0')).join();
      await apiTokenFile.parent.create(recursive:true);
      await apiTokenFile.writeAsString(token,flush:true);
    }
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
