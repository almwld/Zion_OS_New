import 'package:flutter/services.dart';
import '../../security/core/security_core.dart';

class ZionApiAuditBridge {
  ZionApiAuditBridge(this.securityCore);

  final SecurityCore securityCore;
  static const MethodChannel _channel = MethodChannel('zion.os/security');

  void register() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'audit') return null;
      final args = Map<String, dynamic>.from(
        (call.arguments as Map?)?.cast<String, dynamic>() ?? const {},
      );
      securityCore.auditLogger.log(
        action: 'zion-api.' + (args['method']?.toString() ?? 'unknown'),
        actor: args['source']?.toString() ?? 'zion-api',
        outcome: args['outcome']?.toString() ?? 'unknown',
        target: 'android-api',
        metadata: <String, Object?>{
          'details': args['details'],
          'source': args['source'],
        },
      );
      return null;
    });
  }
}
