import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../ai/llama_service.dart';
import '../features/terminal/terminal_service.dart';
import '../agent/tools/terminal_workflow_tool.dart';
import 'environment/agent_environment.dart';
import 'approval/approval_gate.dart';
import 'config/engine_config.dart';
import 'memory/memory_store.dart';
import 'providers/provider_selector.dart';
import 'state/task_state_store.dart';
import 'tools/github/github_client.dart';
import 'tools/execution/file_tool.dart';
import 'tools/execution/python_tool.dart';
import 'tools/execution/process_control_tool.dart';
import 'tools/execution/terminal_tool.dart';
import 'terminal/terminal_workflow.dart';
import 'terminal/workflow_observability.dart';
import 'terminal/workflow_state.dart';
import 'terminal/command_policy.dart';
import 'terminal/path_policy.dart';
import 'terminal/error_classifier.dart';
import 'terminal/output_truncator.dart';
import 'terminal/command_registry.dart';
import 'terminal/environment_detector.dart';
import 'terminal/environment_router.dart';
import 'terminal/llm_repair_advisor.dart';
import 'zion_engine.dart';

class EngineBootstrap {
  static Future<ZionEngine> init(EngineConfig config,{LlamaService? llama,TerminalService? terminal,Directory? sandboxRoot}) async {
    final errors=config.validate();
    if(errors.isNotEmpty)throw ArgumentError('إعدادات المحرك غير صالحة: ${errors.join('؛ ')}');
    final dir=await getApplicationSupportDirectory();
    final sandbox=sandboxRoot??Directory('${dir.path}/zion_agent_sandbox');
    final terminalService=terminal??TerminalService.activeInteractiveService;
    final environment=AgentEnvironment(terminal:terminalService,sandboxRoot:sandbox);
    await environment.prepareSandbox();
    final db=sqlite3.open('${dir.path}/zion_engine.sqlite3');
    terminalService?.retainForAgent();
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('PRAGMA foreign_keys=ON');
    final github=config.githubToken==null?null:GitHubClient(token:config.githubToken!);
    final engine=ZionEngine(config:config,providers:ProviderSelector(config:config,llama:llama??LlamaService()),
      database:db,github:github,approvals:ApprovalGate(),states:TaskStateStore(db),memory:MemoryStore(db),
      environment:environment,terminalLease:terminalService!=null);
    try{
      await engine.init();
      final audit=AuditLog(db);
      final events=AgentEventBus();
      final pathPolicy=PathPolicy();
      final workflow=terminalService==null?null:TerminalWorkflow(
        terminal:terminalService,stateStore:WorkflowStateStore(db),approvalGate:engine.approvals,
        audit:audit,events:events,commandPolicy:const CommandPolicy(),pathPolicy:pathPolicy,
        classifier:ErrorClassifier(),truncator:const OutputTruncator(),
        llmAdvisor:LLMRepairAdvisor(
          provider:()=>engine.providers.current,
          pathPolicy:pathPolicy,
        ),
        environmentRouter:EnvironmentRouter(
          detector:EnvironmentDetector(environment:environment,terminal:terminalService),
          registry:CommandRegistry(),
        ));
      engine.registerTool(TerminalWorkflowTool(workflow));
      return engine;
    }catch(_){
      db.dispose();await github?.dispose();
      if(terminalService!=null)await terminalService.releaseForAgent();
      rethrow;
    }
  }
}