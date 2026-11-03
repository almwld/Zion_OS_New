import 'command_policy.dart';

class CommandMetadata {
  const CommandMetadata({
    this.preferredRuntime = 'zion',
    this.requiredTools = const {},
    this.timeout = const Duration(seconds: 30),
    this.requiresWrite = false,
    this.requiresApproval = false,
    this.requiresNetwork = false,
  });

  final String preferredRuntime;
  final Set<String> requiredTools;
  final Duration timeout;
  final bool requiresWrite;
  final bool requiresApproval;
  final bool requiresNetwork;
}

class CommandRegistry {
  CommandRegistry({CommandPolicy policy = const CommandPolicy()})
      : _policy = policy;

  final CommandPolicy _policy;

  static const Map<String, CommandMetadata> _commands = {
    'ls': CommandMetadata(timeout: Duration(seconds: 5)),
    'cat': CommandMetadata(timeout: Duration(seconds: 5)),
    'grep': CommandMetadata(timeout: Duration(seconds: 10)),
    'find': CommandMetadata(timeout: Duration(seconds: 15)),
    'wc': CommandMetadata(timeout: Duration(seconds: 5)),
    'head': CommandMetadata(timeout: Duration(seconds: 5)),
    'tail': CommandMetadata(timeout: Duration(seconds: 5)),
    'echo': CommandMetadata(timeout: Duration(seconds: 3)),
    'pwd': CommandMetadata(timeout: Duration(seconds: 3)),
    'whoami': CommandMetadata(timeout: Duration(seconds: 3)),
    'id': CommandMetadata(timeout: Duration(seconds: 3)),
    'uname': CommandMetadata(timeout: Duration(seconds: 3)),
    'df': CommandMetadata(timeout: Duration(seconds: 5)),
    'free': CommandMetadata(timeout: Duration(seconds: 5)),
    'ps': CommandMetadata(timeout: Duration(seconds: 5)),
    'which': CommandMetadata(timeout: Duration(seconds: 3)),
    'command': CommandMetadata(timeout: Duration(seconds: 3)),
    'git': CommandMetadata(
      preferredRuntime: 'auto',
      requiredTools: {'git'},
      timeout: Duration(seconds: 30),
      requiresWrite: true,
    ),
    'flutter': CommandMetadata(
      preferredRuntime: 'auto',
      requiredTools: {'flutter'},
      timeout: Duration(minutes: 10),
      requiresWrite: true,
      requiresApproval: true,
    ),
    'dart': CommandMetadata(
      preferredRuntime: 'auto',
      requiredTools: {'dart'},
      timeout: Duration(seconds: 60),
      requiresWrite: true,
    ),
    'npm': CommandMetadata(
      preferredRuntime: 'auto',
      requiredTools: {'npm'},
      timeout: Duration(minutes: 10),
      requiresWrite: true,
      requiresApproval: true,
    ),
    'python3': CommandMetadata(
      preferredRuntime: 'auto',
      requiredTools: {'python3'},
      timeout: Duration(seconds: 60),
      requiresWrite: true,
      requiresApproval: true,
    ),
  };

  CommandMetadata? lookup(String command) {
    final value = command.trim();
    if (value.isEmpty || value.length > 2000) return null;
    final policy = _policy.check(value);
    if (!policy.allowed) return null;
    if (RegExp(r'[|&;<>$(){}\[\]\x60\n\r]').hasMatch(value)) {
      return null;
    }
    final tokens = value.split(RegExp(r'\s+'));
    if (tokens.isEmpty || tokens.first.isEmpty) return null;
    final metadata = _commands[tokens.first];
    if (metadata == null) return null;
    return CommandMetadata(
      preferredRuntime: metadata.preferredRuntime,
      requiredTools: metadata.requiredTools,
      timeout: metadata.timeout,
      requiresWrite: metadata.requiresWrite,
      requiresApproval: policy.requiresApproval || metadata.requiresApproval,
      requiresNetwork: metadata.requiresNetwork,
    );
  }

  List<String> get allCommands => List.unmodifiable(_commands.keys);
}
