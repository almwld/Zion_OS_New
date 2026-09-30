import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static final BackupService _instance=BackupService._internal();
  factory BackupService()=>_instance;
  BackupService._internal();
  String? _backupPath;

  Future<void> init() async { if(_backupPath!=null&&await Directory(_backupPath!).exists())return; final d=Directory('${(await getApplicationDocumentsDirectory()).path}/backups');await d.create(recursive:true);_backupPath=d.path; }
  Future<Directory> _dir()async{await init();return Directory(_backupPath!);}
  String _safe(String n){final s=n.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'),'_').replaceAll(RegExp(r'_+'),'_').replaceAll(RegExp(r'^\.+'),'');return s.isEmpty?'Zion_Backup':s;}

  bool _sensitive(String key){final k=key.toLowerCase();return k.contains('token')||k.contains('password')||k.contains('secret')||k.contains('private_key')||k.contains('apikey')||k.contains('api_key');}

  Future<Map<String,dynamic>> createBackup(String backupName)async{
    final out=<String,dynamic>{'success':false,'size':0,'timestamp':DateTime.now().toIso8601String()};
    try{
      final dir=await _dir(); final prefs=await SharedPreferences.getInstance(); final data=<String,dynamic>{};
      for(final key in prefs.getKeys()){if(_sensitive(key))continue;final v=prefs.get(key);if(v is bool||v is String||v is int||v is double||v is List<String>)data[key]=v;}
      final files=<String,List<int>>{};
      for(final path in ['/data/data/com.zion.os/files/usr/var/lib/zion-pkg/installed.json','/data/data/com.zion.os/files/usr/var/cache/zion-pkg']) {
        final f=File(path); if(await f.exists()&&await f.stat().then((s)=>s.type==FileSystemEntityType.file)){files[path.split('/').last]=await f.readAsBytes();}
      }
      final manifest=<String,dynamic>{'format':'zion-backup-v2','created_at':DateTime.now().toUtc().toIso8601String(),'preferences':data.keys.toList()..sort(),'files':<String,String>{}};
      final fileHashes=manifest['files'] as Map<String,String>;
      for(final e in files.entries){fileHashes[e.key]=sha256.convert(e.value).toString();}
      final archive=Archive();
      final prefsBytes=utf8.encode(jsonEncode(data));
      archive.addFile(ArchiveFile('preferences.json',prefsBytes.length,prefsBytes));
      for(final e in files.entries){archive.addFile(ArchiveFile('files/'+e.key,e.value.length,e.value));}
      final manifestBytes=utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile('manifest.json',manifestBytes.length,manifestBytes));
      final bytes=ZipEncoder().encode(archive); if(bytes==null)throw StateError('تعذر إنشاء أرشيف النسخة الاحتياطية.');
      final name=_safe(backupName); final file=File('${dir.path}/${name}_${DateTime.now().millisecondsSinceEpoch}.zionbackup');await file.writeAsBytes(bytes,flush:true);
      final stat=await file.stat();out..['success']=true..['path']=file.path..['size']=stat.size..['name']=name;
      await _addHistory(name,file.path,stat.size);
    }catch(e){out['error']=e.toString();}return out;
  }

  Future<Map<String,dynamic>> restoreBackup(String path)async{
    final out=<String,dynamic>{'success':false,'restored_items':0};
    try{
      final dir=await _dir();final file=File(path);final root=dir.absolute.path;final actual=file.absolute.path;
      if(!actual.startsWith(root+Platform.pathSeparator)||!actual.endsWith('.zionbackup')){out['error']='Backup must be an application-owned .zionbackup file.';return out;}
      if(!await file.exists()){out['error']='Backup file not found';return out;}
      final archive=ZipDecoder().decodeBytes(await file.readAsBytes(),verify:true);
      ArchiveFile? get(String n){for(final f in archive.files){if(f.name==n)return f;}return null;}
      final mf=get('manifest.json');final pf=get('preferences.json');if(mf==null||pf==null)throw const FormatException('Backup manifest is incomplete.');
      final manifest=jsonDecode(utf8.decode(List<int>.from(mf.content)));final prefsData=jsonDecode(utf8.decode(List<int>.from(pf.content)));
      if(manifest is! Map||manifest['format']!='zion-backup-v2'||prefsData is! Map)throw const FormatException('Unsupported or invalid backup format.');
      final hashes=manifest['files'];if(hashes is Map){for(final e in hashes.entries){final f=get('files/'+e.key.toString());if(f==null)throw FormatException('Missing backup file: '+e.key.toString());final actualHash=sha256.convert(List<int>.from(f.content)).toString();if(actualHash.toLowerCase()!=e.value.toString().toLowerCase())throw FormatException('SHA-256 mismatch: '+e.key.toString());}}
      final prefs=await SharedPreferences.getInstance();int restored=0;
      for(final e in (prefsData as Map).entries){if(_sensitive(e.key.toString()))continue;final v=e.value;bool ok=false;if(v is bool)ok=await prefs.setBool(e.key,v);else if(v is String)ok=await prefs.setString(e.key,v);else if(v is int)ok=await prefs.setInt(e.key,v);else if(v is double)ok=await prefs.setDouble(e.key,v);else if(v is List&&v.every((x)=>x is String))ok=await prefs.setStringList(e.key,v.cast<String>());if(ok)restored++;}
      out..['success']=true..['restored_items']=restored;
    }catch(e){out['error']=e.toString();}return out;
  }

  Future<List<Map<String,dynamic>>> getBackupHistory()async{final d=await _dir();final f=File('${d.path}/backup_history.json');if(!await f.exists())return [];try{final v=jsonDecode(await f.readAsString());if(v is! List)return [];return v.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList().reversed.toList();}catch(_){return [];}}
  Future<void> _addHistory(String name,String path,int size)async{final d=await _dir();final f=File('${d.path}/backup_history.json');List<Map<String,dynamic>> h=[];if(await f.exists()){try{final v=jsonDecode(await f.readAsString());if(v is List)h=v.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}catch(_){}}h.add({'name':name,'path':path,'size':size,'timestamp':DateTime.now().toUtc().toIso8601String()});if(h.length>20)h=h.sublist(h.length-20);await f.writeAsString(jsonEncode(h),flush:true);}
  Future<void> deleteBackup(String path)async{try{final d=await _dir();final root=d.absolute.path;final f=File(path);if(!f.absolute.path.startsWith(root+Platform.pathSeparator)||!f.path.endsWith('.zionbackup'))return;if(await f.exists())await f.delete();final h=File('${d.path}/backup_history.json');if(await h.exists()){final v=jsonDecode(await h.readAsString());if(v is List){final n=v.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).where((e)=>e['path']!=path).toList();await h.writeAsString(jsonEncode(n),flush:true);}}}catch(_){}}
  Future<Map<String,dynamic>> getBackupStats()async{final h=await getBackupHistory();return {'total_backups':h.length,'total_size':h.fold<int>(0,(s,e)=>s+(e['size'] is num?(e['size'] as num).toInt():0)),'last_backup':h.isEmpty?null:h.first['timestamp']};}
  String formatSize(int bytes){if(bytes<1024)return '${bytes} B';if(bytes<1024*1024)return '${(bytes/1024).toStringAsFixed(1)} KB';return '${(bytes/(1024*1024)).toStringAsFixed(1)} MB';}
}
