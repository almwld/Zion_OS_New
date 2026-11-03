import 'package:sqlite3/sqlite3.dart';

class UsageRecord {
  final String taskId;
  final String provider;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final bool estimated;
  final double? costUsd;
  final int createdAt;

  const UsageRecord({
    required this.taskId,
    required this.provider,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.estimated,
    required this.costUsd,
    required this.createdAt,
  });
}

class CostTracker {
  final Database database;

  CostTracker(this.database);

  void initialize() {
    database.execute(
      'CREATE TABLE IF NOT EXISTS ai_usage (id INTEGER PRIMARY KEY AUTOINCREMENT, task_id TEXT NOT NULL, provider TEXT NOT NULL, model TEXT NOT NULL, input_tokens INTEGER NOT NULL, output_tokens INTEGER NOT NULL, estimated INTEGER NOT NULL, cost_usd REAL, created_at INTEGER NOT NULL)',
    );
  }

  void record(UsageRecord item) {
    database.execute(
      'INSERT INTO ai_usage(task_id,provider,model,input_tokens,output_tokens,estimated,cost_usd,created_at) VALUES(?,?,?,?,?,?,?,?)',
      [
        item.taskId,
        item.provider,
        item.model,
        item.inputTokens,
        item.outputTokens,
        item.estimated ? 1 : 0,
        item.costUsd,
        item.createdAt,
      ],
    );
  }

  List<Map<String, Object?>> summary({String? taskId}) {
    const columns = '''
      provider,
      model,
      COUNT(*) AS requests,
      SUM(input_tokens) AS input_tokens,
      SUM(output_tokens) AS output_tokens,
      SUM(estimated) AS estimated_requests,
      SUM(CASE WHEN cost_usd IS NULL THEN 1 ELSE 0 END) AS unknown_cost_requests,
      CASE WHEN COUNT(cost_usd)=COUNT(*) THEN SUM(cost_usd) ELSE NULL END AS cost_usd
    ''';
    final rows = taskId == null
        ? database.select(
            'SELECT $columns FROM ai_usage GROUP BY provider,model ORDER BY requests DESC',
          )
        : database.select(
            'SELECT $columns FROM ai_usage WHERE task_id = ? GROUP BY provider,model ORDER BY requests DESC',
            [taskId],
          );
    return rows
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }

  void clear() => database.execute('DELETE FROM ai_usage');
}
