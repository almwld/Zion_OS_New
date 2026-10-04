import 'dart:convert';
import 'dart:io';
class APIServer {
  HttpServer? _server;
  int? get port=>_server?.port;
  bool get running=>_server!=null;
  Future<void> start(Future<String> Function(String) generate,{int port=8765}) async {
    await stop();
    _server=await HttpServer.bind(InternetAddress.loopbackIPv4,port);
    _server!.listen((request) async {
      request.response.headers.contentType=ContentType.json;
      if(request.method!='POST'||request.uri.path!='/v1/chat/completions'){
        request.response.statusCode=404;
        request.response.write(jsonEncode({'error':{'message':'Not found'}}));
        await request.response.close(); return;
      }
      try{
        final body=jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        final messages=(body['messages'] as List?)??const [];
        final prompt=messages.isEmpty?'':((messages.last as Map)['content']?.toString()??'');
        final output=await generate(prompt);
        request.response.write(jsonEncode({'object':'chat.completion','choices':[{'index':0,'message':{'role':'assistant','content':output},'finish_reason':'stop'}]}));
      }catch(e){
        request.response.statusCode=400;
        request.response.write(jsonEncode({'error':{'message':e.toString()}}));
      }
      await request.response.close();
    });
  }
  Future<void> stop() async {final server=_server;_server=null;await server?.close(force:true);}
}
