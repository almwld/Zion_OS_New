import 'dart:io';
import '../../../agent/core/agent_models.dart';
import '../../../agent/tools/tool.dart';
import '../../environment/agent_environment.dart';
class FileTool extends AgentTool {
 final AgentEnvironment environment;FileTool(this.environment);
 @override String get name=>'file_operation';
 @override String get description=>'قراءة وكتابة وسرد الملفات داخل sandbox الخاص بالوكيل.';
 @override Map<String,dynamic> get parameters=>const {'operation':{'type':'string','required':true},'path':{'type':'string','required':true},'content':{'type':'string','required':false}};
 @override Set<AgentPermission> requiredPermissions(Map<String,dynamic> p)=>p['operation']=='read'||p['operation']=='list'?const {AgentPermission.readOnly}:const {AgentPermission.localWrite};
 @override bool requiresApproval(Map<String,dynamic> p)=>p['operation']=='write';
 Future<FileSystemEntity?> _resolve(String input,{required bool allowMissing})async{
  if(input.trim().isEmpty||input.contains('\u0000'))return null;
  final root=await environment.sandboxRoot.resolveSymbolicLinks();final candidate=File(input).isAbsolute?input:'$root/$input';
  final normalized=Uri.file(candidate).normalizePath().toFilePath();if(normalized!=root&&!normalized.startsWith('$root/'))return null;
  final type=FileSystemEntity.typeSync(normalized,followLinks:false);
  if(type==FileSystemEntityType.link){final target=await Link(normalized).resolveSymbolicLinks();if(target!=root&&!target.startsWith('$root/'))return null;return FileSystemEntity.typeSync(target)==FileSystemEntityType.directory?Directory(target):File(target);}
  if(type!=FileSystemEntityType.notFound){final target=await File(normalized).resolveSymbolicLinks();if(target!=root&&!target.startsWith('$root/'))return null;return type==FileSystemEntityType.directory?Directory(target):File(target);}
  if(!allowMissing)return null;final parent=Directory(normalized).parent;if(!await parent.exists())return null;final target=await parent.resolveSymbolicLinks();if(target!=root&&!target.startsWith('$root/'))return null;return File(normalized);
 }
 @override Future<StepResult> execute(Map<String,dynamic> p)async{
  final op=p['operation']?.toString()??'',path=p['path']?.toString()??'';
  try{await environment.prepareSandbox();
   if(op=='read'){final f=await _resolve(path,allowMissing:false);if(f is! File)return StepResult.failure('الملف غير موجود أو المسار غير آمن.');final s=await f.readAsString();return StepResult.success('تمت قراءة الملف.',data:{'path':f.path,'content':s.length>100000?s.substring(0,100000):s,'truncated':s.length>100000});}
   if(op=='list'){final d=await _resolve(path,allowMissing:false);if(d is! Directory)return StepResult.failure('المجلد غير موجود أو المسار غير آمن.');final items=await d.list(followLinks:false).map((e)=>e.uri.pathSegments.last).take(1000).toList();return StepResult.success('عدد العناصر: ${items.length}.',data:{'entries':items});}
   if(op=='write'){final c=p['content'];if(c is! String||c.length>1000000)return StepResult.failure('محتوى الكتابة غير صالح أو يتجاوز 1MB.');final f=await _resolve(path,allowMissing:true);if(f is! File)return StepResult.failure('المسار غير صالح أو خارج sandbox.');await f.writeAsString(c,flush:true);return StepResult.success('تمت كتابة الملف داخل sandbox.',data:{'path':f.path,'bytes':await f.length()});}
   return StepResult.failure('عملية غير معروفة: $op');
  }catch(e){return StepResult.failure('فشلت عملية الملفات: $e');}
 }
}