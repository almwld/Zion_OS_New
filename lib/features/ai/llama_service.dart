import 'llama_bridge.dart';
class LlamaService {
  final LlamaBridge bridge;
  LlamaService({LlamaBridge? bridge}):bridge=bridge??LlamaBridge();
  Future<bool> isReady()=>bridge.isLoaded();
  Future<void> load(String modelPath)=>bridge.load(modelPath);
  Future<String> generate(String prompt,{double temperature=.7}) {
    if(prompt.trim().isEmpty)return Future.value('');
    final t=temperature.clamp(0.0,2.0);
    return bridge.generate(prompt,temperature:t);
  }
  Future<void> unload()=>bridge.free();
}
