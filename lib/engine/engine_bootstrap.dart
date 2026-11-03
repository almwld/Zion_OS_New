import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../ai/llama_service.dart';
import 'approval/approval_gate.dart';
import 'config/engine_config.dart';
import 'memory/memory_store.dart';
import 'providers/provider_selector.dart';
import 'state/task_state_store.dart';
import 'tools/github/github_client.dart';
import 'zion_engine.dart';
class EngineBootstrap {
 static Future<ZionEngine> init(EngineConfig config,{LlamaService? llama})async{
  final errors=config.validate();if(errors.isNotEmpty)throw ArgumentError('إعدادات المحرك غير صالحة: ${errors.join('؛ ')}');
  final dir=await getApplicationSupportDirectory();
  final db=sqlite3.open('${dir.path}/zion_engine.sqlite3');
  db.execute('PRAGMA journal_mode=WAL');db.execute('PRAGMA foreign_keys=ON');
  final github=config.githubToken==null?null:GitHubClient(token:config.githubToken!);
  final engine=ZionEngine(config:config,providers:ProviderSelector(config:config,llama:llama??LlamaService()),
   database:db,github:github,approvals:ApprovalGate(),states:TaskStateStore(db),memory:MemoryStore(db));
  try{await engine.init();return engine;}catch(_){db.dispose();await github?.dispose();rethrow;}
 }
}