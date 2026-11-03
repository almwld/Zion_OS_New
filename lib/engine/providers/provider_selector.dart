import '../../ai/llama_service.dart';
import '../config/engine_config.dart';
import '../config/engine_mode.dart';
import 'ai_provider.dart';
import 'cloud_provider.dart';
import 'local_provider.dart';
class ProviderSelector {
 final EngineConfig config;final LlamaService llama;AIProvider? _current;EngineMode _mode=EngineMode.unset;
 ProviderSelector({required this.config,required this.llama});
 AIProvider get current=>_current??(throw StateError('لم يتم اختيار مزود'));
 EngineMode get currentMode=>_mode;
 Future<void> switchTo(EngineMode mode) async {
  if(mode==EngineMode.unset)throw StateError('وضع التشغيل غير محدد');
  if(_current!=null&&_mode==mode&&await _current!.isReady())return;
  final old=_current;_current=null;_mode=EngineMode.unset;await old?.dispose();
  final next=switch(mode){
   EngineMode.local=>LocalProvider(llama:llama,modelPath:config.localModelPath),
   EngineMode.cloud=>CloudProvider(apiKey:config.cloudApiKey??'',baseUrl:config.cloudBaseUrl??'https://api.openai.com/v1',model:config.cloudModel??'gpt-4o-mini'),
   EngineMode.unset=>throw StateError('وضع غير صالح')
  };
  try{if(!await next.isReady())throw StateError('المزود ${mode.displayName} غير جاهز');_current=next;_mode=mode;}
  catch(_){await next.dispose();rethrow;}
 }
 Future<void> dispose() async{final old=_current;_current=null;_mode=EngineMode.unset;await old?.dispose();}
}