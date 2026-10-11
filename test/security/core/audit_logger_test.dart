import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/security/core/audit_logger.dart';

void main() {
  group('AuditLogger', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('zion-audit-test-');
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('keeps a bounded in-memory trail and persists records in order', () async {
      final path = '${directory.path}/logs/audit.log';
      final logger = AuditLogger(
        filePath: path,
        maxRecords: 2,
        clock: () => DateTime.utc(2026, 10, 12),
      );

      logger.log(action: 'boot', actor: 'test', outcome: 'ok');
      logger.log(action: 'permission.check', actor: 'test', outcome: 'denied');
      logger.log(action: 'terminal.open', actor: 'test', outcome: 'accepted');
      await logger.flush();

      expect(logger.records, hasLength(2));
      expect(logger.records.first.action, 'permission.check');
      expect(logger.records.last.action, 'terminal.open');
      expect(logger.persistenceHealthy, isTrue);

      final lines = await File(path).readAsLines();
      expect(lines, hasLength(3));
      expect((jsonDecode(lines.first) as Map<String, dynamic>)['action'], 'boot');
      expect((jsonDecode(lines.last) as Map<String, dynamic>)['action'], 'terminal.open');

      await logger.dispose();
    });

    test('rotates the persisted log when the configured size is reached', () async {
      final path = '${directory.path}/audit.log';
      final logger = AuditLogger(filePath: path, maxFileBytes: 1024);

      logger.log(
        action: 'large.record',
        actor: 'test',
        outcome: 'accepted',
        metadata: <String, Object?>{'payload': 'x' * 700},
      );
      await logger.flush();
      logger.log(
        action: 'next.record',
        actor: 'test',
        outcome: 'accepted',
        metadata: <String, Object?>{'payload': 'y' * 700},
      );
      await logger.flush();

      expect(await File('$path.1').exists(), isTrue);
      expect(await File(path).exists(), isTrue);
      expect((await File(path).readAsLines()), hasLength(1));

      await logger.dispose();
    });

    test('dispose is safe to call repeatedly and stops new records', () async {
      final logger = AuditLogger(filePath: '${directory.path}/audit.log');
      logger.log(action: 'before.dispose', actor: 'test', outcome: 'ok');
      await logger.dispose();
      await logger.dispose();
      logger.log(action: 'after.dispose', actor: 'test', outcome: 'ignored');

      expect(logger.records.map((record) => record.action), <String>['before.dispose']);
    });
  });
}
