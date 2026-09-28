import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AuditRecord {
  const AuditRecord({
    required this.timestamp,
    required this.action,
    required this.actor,
    required this.outcome,
    this.target,
    this.metadata = const <String, Object?>{},
  });
  final DateTime timestamp;
  final String action;
  final String actor;
  final String outcome;
  final String? target;
  final Map<String, Object?> metadata;
  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toIso8601String(), 'action': action, 'actor': actor,
    'outcome': outcome, if (target != null) 'target': target, 'metadata': metadata,
  };
}

class AuditLogger {
  AuditLogger({DateTime Function()? clock, this.filePath = '/data/data/com.zion.os/files/usr/var/log/audit.log'})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final String filePath;
  final List<AuditRecord> _records = <AuditRecord>[];
  final StreamController<AuditRecord> _controller = StreamController<AuditRecord>.broadcast();

  List<AuditRecord> get records => List.unmodifiable(_records);
  Stream<AuditRecord> get stream => _controller.stream;

  void log({
    required String action,
    required String actor,
    required String outcome,
    String? target,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final record = AuditRecord(
      timestamp: _clock().toUtc(), action: action, actor: actor, outcome: outcome,
      target: target, metadata: Map.unmodifiable(metadata),
    );
    _records.add(record);
    if (!_controller.isClosed) _controller.add(record);
    try {
      final file = File(filePath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(record.toJson()) + '\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Audit remains available in-memory when the platform filesystem is unavailable.
    }
  }

  Future<void> dispose() => _controller.close();
}
