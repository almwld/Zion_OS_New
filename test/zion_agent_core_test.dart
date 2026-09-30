import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/core/agent_models.dart';
import 'package:project_zion/agent/core/agent_policy.dart';

void main(){
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