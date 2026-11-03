import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
class GitHubException implements Exception {
 final int statusCode;final String message;final String? documentationUrl;
 const GitHubException(this.statusCode,this.message,{this.documentationUrl});
 @override String toString()=>'GitHubException($statusCode): $message';
}
class GitHubClient {
 final String token;final http.Client _client;final bool _ownsClient;
 GitHubClient({required this.token,http.Client? client}):_client=client??http.Client(),_ownsClient=client==null;
 static const _api='https://api.github.com';
 Map<String,String> get _headers=>{'Accept':'application/vnd.github+json','Authorization':'Bearer $token',
 'X-GitHub-Api-Version':'2022-11-28','Content-Type':'application/json','User-Agent':'Zion-OS-Agent'};
 String _repo(String owner,String repo)=>'/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}';
 Future<dynamic> _request(String method,String path,{Map<String,dynamic>? body})async{
  try{
   final req=http.Request(method,Uri.parse('$_api$path'))..headers.addAll(_headers);
   if(body!=null)req.body=jsonEncode(body);
   final response=await _client.send(req).timeout(const Duration(seconds:45));
   final text=await response.stream.bytesToString();
   if(response.statusCode<200||response.statusCode>=300){
    var message=text;String? doc;
    try{final j=jsonDecode(text) as Map<String,dynamic>;message=j['message']?.toString()??text;doc=j['documentation_url']?.toString();}catch(_){}
    final code=response.statusCode;
    final prefix=switch(code){401=>'رمز GitHub غير صالح',403=>'صلاحيات غير كافية أو تجاوز معدل الطلبات',404=>'المورد غير موجود أو غير مصرح به',409=>'تعارض SHA أو حالة المستودع',422=>'GitHub رفض البيانات',>=500=>'عطل مؤقت في GitHub',_=>'فشل طلب GitHub'};
    throw GitHubException(code,'$prefix: $message',documentationUrl:doc);
   }
   if(text.isEmpty)return <String,dynamic>{};
   return jsonDecode(text);
  }on GitHubException{rethrow;}catch(e){throw GitHubException(0,'تعذر الاتصال بـ GitHub: $e');}
 }
 Future<Map<String,dynamic>> getFile(String owner,String repo,String path,{String? ref})async{
  final q=ref==null?'':'?ref=${Uri.encodeQueryComponent(ref)}';
  final encodedPath=path.split('/').map((p)=>Uri.encodeComponent(p)).join('/');
  final data=Map<String,dynamic>.from(await _request('GET','${_repo(owner,repo)}/contents/$encodedPath$q') as Map);
  final content=data['content']?.toString().replaceAll('\n','')??'';
  return {...data,'content':data['encoding']=='base64'?utf8.decode(base64.decode(base64.normalize(content))):content};
 }
 Future<Map<String,dynamic>> getTree(String owner,String repo,String ref,{bool recursive=true})async=>
  Map<String,dynamic>.from(await _request('GET','${_repo(owner,repo)}/git/trees/${Uri.encodeComponent(ref)}?recursive=${recursive?1:0}') as Map);
 Future<Map<String,dynamic>> getCheckRuns(String owner,String repo,{String? ref,int? pullNumber})async{
  var sha=ref;
  if((sha==null||sha.isEmpty)&&pullNumber!=null){final pr=await _request('GET','${_repo(owner,repo)}/pulls/$pullNumber') as Map;sha=(pr['head'] as Map?)?['sha']?.toString();}
  if(sha==null||sha.isEmpty)throw const GitHubException(422,'يلزم تحديد ref أو رقم PR');
  return Map<String,dynamic>.from(await _request('GET','${_repo(owner,repo)}/commits/${Uri.encodeComponent(sha)}/check-runs') as Map);
 }
 Future<String> getWorkflowLogs(String owner,String repo,int runId)async{
  try{
   final request=http.Request('GET',Uri.parse('$_api${_repo(owner,repo)}/actions/runs/$runId/logs'))..headers.addAll(_headers);
   final response=await _client.send(request).timeout(const Duration(seconds:60));
   if(response.statusCode<200||response.statusCode>=300){
    final body=await response.stream.bytesToString();
    throw GitHubException(response.statusCode,'تعذر تنزيل سجلات التشغيل: $body');
   }
   final bytes=await response.stream.toBytes();
   final archive=ZipDecoder().decodeBytes(bytes);
   final output=StringBuffer();
   for(final file in archive.files){
    if(!file.isFile)continue;
    final raw=file.content;
    if(raw is List<int>){
     output.writeln('===== ${file.name} =====');
     output.writeln(utf8.decode(raw,allowMalformed:true));
    }
   }
   return output.toString();
  }on GitHubException{rethrow;}catch(e){throw GitHubException(0,'فشل استخراج سجلات GitHub Actions: $e');}
 }
 Future<Map<String,dynamic>> updateFile(String owner,String repo,String path,{required String content,required String sha,required String message,required String branch})async{
  final p=path.split('/').map(Uri.encodeComponent).join('/');
  return Map<String,dynamic>.from(await _request('PUT','${_repo(owner,repo)}/contents/$p',body:{
   'message':message,'content':base64.encode(utf8.encode(content)),'sha':sha,'branch':branch}) as Map);
 }
 Future<Map<String,dynamic>> createBranch(String owner,String repo,String name,{String base='main'})async{
  final ref=await _request('GET','${_repo(owner,repo)}/git/ref/heads/${Uri.encodeComponent(base)}') as Map;
  final sha=((ref['object'] as Map)['sha']).toString();
  return Map<String,dynamic>.from(await _request('POST','${_repo(owner,repo)}/git/refs',body:{'ref':'refs/heads/$name','sha':sha}) as Map);
 }
 Future<Map<String,dynamic>> createPullRequest(String owner,String repo,{required String title,required String body,required String head,required String base})async=>
  Map<String,dynamic>.from(await _request('POST','${_repo(owner,repo)}/pulls',body:{'title':title,'body':body,'head':head,'base':base}) as Map);
 Future<void> dispose()async{if(_ownsClient)_client.close();}
}