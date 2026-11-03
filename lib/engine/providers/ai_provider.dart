import '../config/engine_mode.dart';
abstract interface class AIProvider {
 String get name;
 EngineMode get mode;
 Future<bool> isReady();
 Future<String> generate({required String prompt,String? systemPrompt,int? maxTokens,
 double temperature=0.2,void Function(String chunk)? onChunk,Future<void>? cancellation});
 Future<void> dispose();
}
class ProviderException implements Exception {
 final String message; final String? code;
 const ProviderException(this.message,{this.code});
 @override String toString()=>'ProviderException(${code??'unknown'}): $message';
}