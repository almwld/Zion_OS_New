import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/ai/ai_agent.dart';
import 'package:project_zion/ai/llama_service.dart';
import 'package:project_zion/agent/core/agent_models.dart';
import 'package:project_zion/agent/core/agent_policy.dart';

class RecordingLlamaService extends LlamaService {
  String lastPrompt = '';
  int lastMaxTokens = 0;
  double lastTemperature = 0;
  int generateCalls = 0;
  String reply = 'local reply';
  bool loadResult = true;

  @override
  Future<bool> loadModel(
    String path, {
    int threads = 4,
    String? loraPath,
    double loraScale = 1.0,
  }) async => loadResult;

  @override
  Future<String> generate(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    generateCalls++;
    lastPrompt = prompt;
    lastMaxTokens = maxTokens;
    lastTemperature = temperature;
    return reply;
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
  expect(llama.lastPrompt, contains('<|im_start|>user\nfirst question\n<|im_end|>'));
  expect(llama.lastPrompt, contains('<|im_start|>assistant\nlocal reply\n<|im_end|>'));
  expect(llama.lastPrompt, isNot(contains(r'${item.role}')));
  await agent.dispose();
 });
 test('local chat forwards bounded generation settings',() async {
  final llama = RecordingLlamaService();
  final agent = AIAgent(llama: llama);
  expect(await agent.initialize(modelPath: 'test.gguf', role: AgentRole.codingAssistant), isTrue);
  await agent.chat('explain this', maxTokens: 256, temperature: 1.1);
  expect(llama.lastMaxTokens, 256);
  expect(llama.lastTemperature, 1.1);
  await agent.dispose();
 });
 test('local chat ignores blank input without invoking inference',() async {
  final llama = RecordingLlamaService();
  final agent = AIAgent(llama: llama);
  expect(await agent.initialize(modelPath: 'test.gguf', role: AgentRole.codingAssistant), isTrue);
  expect(await agent.chat('   '), isEmpty);
  expect(llama.generateCalls, 0);
  await agent.dispose();
 });
 test('local chat clamps out-of-range generation settings',() async {
  final llama = RecordingLlamaService();
  final agent = AIAgent(llama: llama);
  expect(await agent.initialize(modelPath: 'test.gguf', role: AgentRole.codingAssistant), isTrue);
  await agent.chat('check bounds', maxTokens: 999, temperature: 99);
  expect(llama.lastMaxTokens, 256);
  expect(llama.lastTemperature, 1.5);
  await agent.dispose();
 });
 test('local chat strips common model turn markers',() async {
  final llama = RecordingLlamaService()..reply = '<|im_start|>assistant\nHello<|im_end|>\nUser: next turn';
  final agent = AIAgent(llama: llama);
  expect(await agent.initialize(modelPath: 'test.gguf', role: AgentRole.codingAssistant), isTrue);
  expect(await agent.chat('say hello'), 'Hello');
  await agent.dispose();
 });
 test('failed model replacement clears agent readiness',() async {
  final llama = RecordingLlamaService();
  final agent = AIAgent(llama: llama);
  expect(await agent.initialize(modelPath: 'first.gguf', role: AgentRole.codingAssistant), isTrue);
  expect(agent.isInitialized, isTrue);
  llama.loadResult = false;
  expect(await agent.initialize(modelPath: 'second.gguf', role: AgentRole.codingAssistant), isFalse);
  expect(agent.isInitialized, isFalse);
  await agent.dispose();
 });
 test('GGUF metadata safely parses numeric size strings',() {
  final model = LlamaModel.fromMap({
    'name': 'test-instruct.gguf',
    'path': '/local/test-instruct.gguf',
    'sizeBytes': '1048576',
    'readable': true,
  });
  expect(model.sizeBytes, 1048576);
  expect(model.readable, isTrue);
 });
 test('agent policy blocks destructive shell and requests approval for writes',(){
  const policy=AgentPolicy();
  final blocked=policy.evaluate(tool:'shell',params:{'command':'rm -rf /'});
  expect(blocked.risk,AgentRisk.blocked);
  final review=policy.evaluate(tool:'file',params:{'action':'write','path':'note.txt'});
  expect(review.requiresApproval,isTrue);
 });
 test('routine workspace diagnostics are auto-runnable without permitting compound commands',(){
  const policy=AgentPolicy();
  for (final command in [
    'git status --short',
    'git diff --check',
    'git log --oneline -n 5',
    'flutter --version',
    'dart --version',
    'command -v bash',
  ]) {
    final decision=policy.evaluate(tool:'shell',params:{'command':command});
    expect(decision.risk,AgentRisk.safe,reason:command);
    expect(decision.requiresApproval,isFalse,reason:command);
  }
  final compound=policy.evaluate(tool:'shell',params:{'command':'git status; echo done'});
  expect(compound.requiresApproval,isTrue);
 });
 test('read-only HTTP GET is safe',(){
  const policy=AgentPolicy();
  final d=policy.evaluate(tool:'http',params:{'method':'GET','url':'https://example.com'});
  expect(d.risk,AgentRisk.safe);
 });
}