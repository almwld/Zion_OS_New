import '../../ai/llama_service.dart';
import '../config/engine_mode.dart';
import 'ai_provider.dart';
class LocalProvider implements AIProvider {
 final LlamaService llama;
 final String? modelPath;
 final bool autoLoad;
 LocalProvider({required this.llama,this.modelPath,this.autoLoad = true});
 @override String get name=>'llama.cpp (محلي)';
 @override EngineMode get mode=>EngineMode.local;
 @override Future<bool> isReady() async {
  // Terminal repair advice must never trigger an implicit model load.
  if(!autoLoad)return await llama.nativeLoaded;
  if(await llama.refreshLoadedState())return true;
  final path=modelPath;
  if(path==null||path.trim().isEmpty){final model=await llama.autoLoadBestModel();return model!=null&&llama.isLoaded;}
  return llama.loadModel(path);
 }
 @override Future<String> generate({required String prompt,String? systemPrompt,int? maxTokens,
 double temperature=0.2,void Function(String chunk)? onChunk,Future<void>? cancellation}) async {
  if(!await isReady())throw const ProviderException('النموذج المحلي غير جاهز',code:'local_not_ready');
  final full=systemPrompt==null?prompt:'$systemPrompt\n\n$prompt';
  final result=await llama.generate(full,maxTokens:(maxTokens??1024).clamp(1,2048),temperature:temperature);
  if(result.startsWith('ERROR:'))throw ProviderException(result,code:'local_generation');
  if(onChunk!=null&&result.isNotEmpty)onChunk(result);
  return result;
 }
 @override Future<void> dispose() async {
  await llama.unloadModel();
 }
}