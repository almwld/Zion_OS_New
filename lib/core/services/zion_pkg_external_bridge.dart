import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../security/core/security_core.dart';
import '../userland/zion_pkg.dart';
import '../userland/zion_pkg_cli.dart';

class ZionPkgExternalBridge {
  ZionPkgExternalBridge(this.securityCore);
  final SecurityCore securityCore;
  static const MethodChannel _channel = MethodChannel('zion.os/pkg-external');
  static const String _resultDir = ZionPkg.prefix + '/tmp/zion-pkg-results';

  void register() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'execute') return null;
      final args = Map<Object?, Object?>.from((call.arguments as Map?) ?? const {});
      final requestId = (args['requestId'] ?? '').toString();
      if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(requestId)) return null;
      final command = (args['command'] ?? 'help').toString();
      final value = (args['value'] ?? '').toString();
      final cliArgs = value.isEmpty ? <String>[command] : <String>[command, value];
      String output;
      var exitCode = 0;
      try {
        output = await ZionPkgCli(ZionPkg(securityCore: securityCore)).run(cliArgs);
        if (output.startsWith('ERROR:') || output.startsWith('UNAVAILABLE:')) exitCode = 1;
      } catch (e) {
        output = 'ERROR: ' + e.toString();
        exitCode = 1;
      }
      final dir = Directory(_resultDir);
      await dir.create(recursive: true);
      await File(_resultDir + '/' + requestId + '.out').writeAsString(output + '\n',flush:true);
      await File(_resultDir + '/' + requestId + '.status').writeAsString(exitCode.toString(),flush:true);
      return null;
    });
  }
}
