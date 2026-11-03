import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/engine_mode.dart';
import 'ai_provider.dart';
class CloudProvider implements AIProvider {
 final String apiKey,baseUrl,model; final http.Client _client; final bool _ownsClient;
 CloudProvider({required this.apiKey,required this.baseUrl,required this.model,http.Client? client})
 :_client=client??http.Client(),_ownsClient=client==null;
 @override String get name=>'OpenAI-compatible ($model)';
 @override EngineMode get mode=>EngineMode.cloud;
 @override Future<bool> isReady() async=>apiKey.trim().isNotEmpty&&Uri.tryParse(baseUrl)!=null;
 @override Future<String> generate({required String prompt,String? systemPrompt,int? maxTokens,
 double temperature=0.2,void Function(String chunk)? onChunk,Future<void>? cancellation}) async {
  final uri=Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'),'')}/chat/completions');
  final messages=<Map<String,String>>[];
  if(systemPrompt!=null&&systemPrompt.isNotEmpty)messages.add({'role':'system','content':systemPrompt});
  messages.add({'role':'user','content':prompt});
  final body=jsonEncode({'model':model,'messages':messages,'max_tokens':maxTokens??1024,'temperature':temperature,'stream':onChunk!=null});
  try {
   if(onChunk==null){
    final r=await _client.post(uri,headers:{'Authorization':'Bearer $apiKey','Content-Type':'application/json'},body:body).timeout(const Duration(minutes:3));
    if(r.statusCode<200||r.statusCode>=300)throw ProviderException('HTTP ${r.statusCode}: ${r.body}',code:'cloud_http_${r.statusCode}');
    final j=jsonDecode(r.body) as Map<String,dynamic>;
    final choices=j['choices'] as List?;final c=choices==null||choices.isEmpty?null:choices.first;
    final content=c is Map?(c['message'] as Map?)?['content']:null;
    if(content is! String)throw const ProviderException('استجابة المزود لا تحتوي محتوى',code:'invalid_response');
    return content;
   }
   final req=http.Request('POST',uri)..headers.addAll({'Authorization':'Bearer $apiKey','Content-Type':'application/json','Accept':'text/event-stream'})..body=body;
   final response=await _client.send(req).timeout(const Duration(minutes:3));
   if(response.statusCode<200||response.statusCode>=300){
    final error=await response.stream.bytesToString();throw ProviderException('HTTP ${response.statusCode}: $error',code:'cloud_http_${response.statusCode}');
   }
   final output=StringBuffer();var pending='';
   await for(final chunk in response.stream.transform(utf8.decoder)){
    pending+=chunk;
    while(pending.contains('\n')){
     final i=pending.indexOf('\n');final line=pending.substring(0,i).trim();pending=pending.substring(i+1);
     if(!line.startsWith('data:'))continue;
     final data=line.substring(5).trim();if(data=='[DONE]')return output.toString();if(data.isEmpty)continue;
     try{
      final event=jsonDecode(data) as Map<String,dynamic>;
      final choices=event['choices'] as List?;final delta=(choices != null && choices.isNotEmpty) ? (choices.first as Map)['delta'] : null;
      final text=delta is Map?delta['content']:null;
      if(text is String&&text.isNotEmpty){output.write(text);onChunk(text);}
     }on FormatException{/* تجاهل إطار غير مكتمل */}
    }
   }
   return output.toString();
  }on ProviderException{rethrow;}on TimeoutException{throw const ProviderException('انتهت مهلة الاتصال',code:'timeout');}
  catch(e){throw ProviderException('تعذر الاتصال السحابي: $e',code:'network');}
 }
 @override Future<void> dispose() async{if(_ownsClient)_client.close();}
}