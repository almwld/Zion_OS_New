import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/ai/ai_agent.dart';
import 'package:project_zion/ai/llama_service.dart';
import 'package:project_zion/agent/core/agent_models.dart';
import 'package:project_zion/agent/core/agent_policy.dart';

class RecordingLlamaService extends LlamaService {
  String lastPrompt = '';

  @override
  Future<bool> loadModel(
    String path, {
    int threads = 4,
    String? loraPath,
    double loraScale = 1.0,
  }) async => true;

  @override
  Future<String> generate(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    lastPrompt = prompt;
    return 'local reply';
  }

  @override
  Future<void> unloadModel() async {}
}

void main(){
 test('local AI prompt interpolates stored conversation roles',() async {
  final llama = RecordingLlamaService();
  final agent = AIAgent(llama: llama);
  expect(await agent.initialize(modelPath: 'test.gguf', role: AgentRole.codingAssistant), isTrue);
  await agent.chat('first question');
  await agent.chat('second question');
  expect(llama.lastPrompt, contains('<|user|>\nfirst question\n<|end|>'));
  expect(llama.lastPrompt, contains('<|assistant|>\nlocal reply\n<|end|>'));
  expect(llama.lastPrompt, isNot(contains(r'${item.role}')));
  await agent.dispose();
 });
 test('agent policy blocks destructive shell and requests approval for writes',(){
  const policy=AgentPolicy();
  final blocked=policy.evaluate(tool:'shell',params:{'command':'rm -rf /'});
  expect(blocked.risk,AgentRisk.blocked);
  final review=policy.evaluate(tool:'file',params:{'action':'write','path':'note.txt'});
  expect(review.requiresApproval,isTrue);
 });
 test('read-only HTTP GET is safe',(){
  const policy=AgentPolicy();
  final d=policy.evaluate(tool:'http',params:{'method':'GET','url':'https://example.com'});
  expect(d.risk,AgentRisk.safe);
 });
}