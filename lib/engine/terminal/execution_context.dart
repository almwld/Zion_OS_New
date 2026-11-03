enum ExecutionEnvironment { zion, kali, rootfs, custom }

enum EnvironmentSelection { auto, zionOnly, kaliOnly, rootfsOnly }

class ExecutionContext {
  const ExecutionContext({
    required this.command,
    required this.environment,
    this.timeout = const Duration(seconds: 30),
    this.requiresNetwork = false,
    this.requiresWrite = false,
    this.requiredTools = const {},
  });

  final String command;
  final ExecutionEnvironment environment;
  final Duration timeout;
  final bool requiresNetwork;
  final bool requiresWrite;
  final Set<String> requiredTools;

  String get runtimeName => switch (environment) {
        ExecutionEnvironment.zion => 'zion',
        ExecutionEnvironment.kali => 'kali',
        ExecutionEnvironment.rootfs => 'rootfs',
        ExecutionEnvironment.custom => 'auto',
      };
}
