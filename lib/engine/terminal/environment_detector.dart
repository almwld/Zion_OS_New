import '../environment/agent_environment.dart';
import '../../features/terminal/terminal_service.dart';

class EnvironmentReport {
  const EnvironmentReport({
    required this.zionReady,
    required this.kaliReady,
    required this.rootfsReady,
    required this.toolsByRuntime,
    this.details = const {},
  });

  final bool zionReady;
  final bool? kaliReady;
  final bool? rootfsReady;
  final Map<String, Set<String>> toolsByRuntime;
  final Map<String, String> details;

  bool hasTool(String runtime, String tool) =>
      toolsByRuntime[runtime]?.contains(tool) ?? false;

  Map<String, dynamic> toJson() => {
        'zionReady': zionReady,
        'kaliReady': kaliReady,
        'rootfsReady': rootfsReady,
        'toolsByRuntime': toolsByRuntime.map(
          (key, value) => MapEntry(key, value.toList()..sort()),
        ),
        'details': details,
      };
}

class EnvironmentDetector {
  EnvironmentDetector({
    required this.environment,
    required this.terminal,
  });

  final AgentEnvironment environment;
  final TerminalService? terminal;

  Future<EnvironmentReport> report({bool probeKali = false}) async {
    final status = await environment.inspect();
    final zionTools = <String>{};
    if (status.pythonReady) zionTools.add('python3');
    if (status.gitReady) zionTools.add('git');

    final service = terminal;
    if (status.terminalReady && service != null) {
      for (final tool in const ['flutter', 'dart']) {
        try {
          final result = await service.executeInInteractive(
            'which $tool',
            runtime: 'zion',
            timeout: const Duration(seconds: 4),
          );
          if (result.exitCode == 0 && result.stdout.trim().isNotEmpty) {
            zionTools.add(tool);
          }
        } catch (_) {
          // غياب الأداة لا يمنع فحص بقية البيئة.
        }
      }
    }

    bool? kaliReady;
    final kaliTools = <String>{};
    if (probeKali && service != null) {
      try {
        final result = await service.executeInInteractive(
          'echo ZION_KALI_PROBE',
          runtime: 'kali',
          timeout: const Duration(seconds: 8),
        );
        kaliReady = result.exitCode == 0 &&
            result.stdout.contains('ZION_KALI_PROBE');
        if (kaliReady) {
          for (final tool in const ['python3', 'git', 'flutter', 'dart']) {
            try {
              final found = await service.executeInInteractive(
                'which $tool',
                runtime: 'kali',
                timeout: const Duration(seconds: 4),
              );
              if (found.exitCode == 0 && found.stdout.trim().isNotEmpty) {
                kaliTools.add(tool);
              }
            } catch (_) {
              // تبقى الأداة غير مثبتة أو غير قابلة للفحص.
            }
          }
        }
      } catch (_) {
        kaliReady = false;
      }
    }

    return EnvironmentReport(
      zionReady: status.terminalReady,
      kaliReady: kaliReady,
      rootfsReady: null,
      toolsByRuntime: {
        'zion': Set.unmodifiable(zionTools),
        'kali': Set.unmodifiable(kaliTools),
      },
      details: {
        if (status.terminalError != null)
          'zionError': status.terminalError!,
        if (status.pythonVersion != null)
          'pythonVersion': status.pythonVersion!,
        if (status.gitVersion != null) 'gitVersion': status.gitVersion!,
        'kaliProbe': probeKali ? 'performed' : 'not-performed',
      },
    );
  }
}
