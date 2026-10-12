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

  Map<String, Object?> toJson() => <String, Object?>{
        'timestamp': timestamp.toIso8601String(),
        'action': action,
        'actor': actor,
        'outcome': outcome,
        if (target != null) 'target': target,
        'metadata': metadata,
      };
}

/// Lightweight audit trail.
///
/// Records are published and retained in memory synchronously, while disk I/O
/// is serialized asynchronously so frequent security events cannot block the
/// Flutter UI thread. Both memory and the persisted log are bounded.
class AuditLogger {
  AuditLogger({
    DateTime Function()? clock,
    this.filePath = '/data/data/com.zion.os/files/usr/var/log/audit.log',
    this.maxRecords = 2000,
    this.maxFileBytes = 2 * 1024 * 1024,
  }) : _clock = clock ?? DateTime.now {
    if (maxRecords < 1) {
      throw ArgumentError.value(maxRecords, 'maxRecords', 'Must be positive.');
    }
    if (maxFileBytes < 1024) {
      throw ArgumentError.value(maxFileBytes, 'maxFileBytes', 'Must be at least 1024 bytes.');
    }
  }

  final DateTime Function() _clock;
  final String filePath;
  final int maxRecords;
  final int maxFileBytes;
  final List<AuditRecord> _records = <AuditRecord>[];
  final StreamController<AuditRecord> _controller =
      StreamController<AuditRecord>.broadcast();
  Future<void> _writeQueue = Future<void>.value();
  bool _disposed = false;
  String? _lastPersistenceError;

  List<AuditRecord> get records => List<AuditRecord>.unmodifiable(_records);
  Stream<AuditRecord> get stream => _controller.stream;
  String? get lastPersistenceError => _lastPersistenceError;
  bool get persistenceHealthy => _lastPersistenceError == null;

  void log({
    required String action,
    required String actor,
    required String outcome,
    String? target,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    if (_disposed) return;

    final record = AuditRecord(
      timestamp: _clock().toUtc(),
      action: action,
      actor: actor,
      outcome: outcome,
      target: target,
      metadata: Map<String, Object?>.unmodifiable(metadata),
    );

    _records.add(record);
    if (_records.length > maxRecords) {
      _records.removeRange(0, _records.length - maxRecords);
    }
    if (!_controller.isClosed) _controller.add(record);

    // Keep writes ordered, but never perform filesystem work synchronously in
    // log(). A failed write is recorded without breaking subsequent logging.
    _writeQueue = _writeQueue
        .then((_) => _appendRecord(record))
        .catchError((Object error, StackTrace stackTrace) {
      _lastPersistenceError = error.toString();
    });
  }

  Future<void> _appendRecord(AuditRecord record) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);

    if (await file.exists() && await file.length() >= maxFileBytes) {
      final backup = File('$filePath.1');
      if (await backup.exists()) await backup.delete();
      await file.rename(backup.path);
    }

    await file.writeAsString(
      '${jsonEncode(record.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
    _lastPersistenceError = null;
  }

  /// Wait until all audit writes scheduled before this call have settled.
  Future<void> flush() => _writeQueue;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await flush();
    await _controller.close();
  }
}
