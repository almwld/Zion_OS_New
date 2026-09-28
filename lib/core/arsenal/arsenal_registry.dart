import 'dart:io';

enum ArsenalAvailability {
  available,
  permissionRequired,
  notConfigured,
  unavailable,
}

enum ArsenalCategory {
  attack,
  defense,
  analysis,
  tools,
  network,
  crypto,
  ai,
  forensics,
  wireless,
  web,
  system,
  utility,
}

class ArsenalTool {
  const ArsenalTool({
    required this.id,
    required this.name,
    required this.category,
    required this.availability,
    this.command,
    this.reason,
    this.requiresAuthorization = true,
  });

  final String id;
  final String name;
  final ArsenalCategory category;
  final ArsenalAvailability availability;
  final String? command;
  final String? reason;
  final bool requiresAuthorization;

  ArsenalTool copyWith({ArsenalAvailability? availability, String? reason}) => ArsenalTool(
        id: id, name: name, category: category,
        availability: availability ?? this.availability,
        command: command, reason: reason,
        requiresAuthorization: requiresAuthorization,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'availability': availability.name.toUpperCase(),
        'command': command,
        'reason': reason,
        'requiresAuthorization': requiresAuthorization,
      };
}

class ArsenalRegistry {
  ArsenalRegistry({Iterable<ArsenalTool>? tools})
      : _tools = List.unmodifiable(tools ?? _defaults);

  final List<ArsenalTool> _tools;

  List<ArsenalTool> get tools => _tools;

  List<ArsenalTool> byCategory(ArsenalCategory category) =>
      _tools.where((tool) => tool.category == category).toList(growable: false);

  ArsenalTool? resolve(String id) {
    for (final tool in _tools) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  Map<String, List<ArsenalTool>> grouped() {
    return <String, List<ArsenalTool>>{
      for (final category in ArsenalCategory.values)
        category.name: byCategory(category),
    };
  }

  static const List<ArsenalTool> _defaults = <ArsenalTool>[
    ArsenalTool(id: 'net.ping', name: 'Ping', category: ArsenalCategory.network, availability: ArsenalAvailability.available, command: 'ping'),
    ArsenalTool(id: 'net.ip', name: 'IP', category: ArsenalCategory.network, availability: ArsenalAvailability.available, command: 'ip'),
    ArsenalTool(id: 'net.ss', name: 'Socket Statistics', category: ArsenalCategory.network, availability: ArsenalAvailability.available, command: 'ss'),
    ArsenalTool(id: 'net.dns', name: 'DNS Lookup', category: ArsenalCategory.network, availability: ArsenalAvailability.notConfigured, command: 'dig', reason: 'Depends on the Zion userland DNS binary.'),
    ArsenalTool(id: 'terminal.shell', name: 'Native Terminal', category: ArsenalCategory.tools, availability: ArsenalAvailability.available, command: '/system/bin/sh'),
    ArsenalTool(id: 'packages.zion-pkg', name: 'Zion Package Manager', category: ArsenalCategory.system, availability: ArsenalAvailability.notConfigured, command: 'zion-pkg', reason: 'Zion userland bootstrap is not installed.'),
    ArsenalTool(id: 'linux.proot', name: 'PRoot', category: ArsenalCategory.system, availability: ArsenalAvailability.notConfigured, command: 'proot', reason: 'Native Zion PRoot runtime is not installed.'),
    ArsenalTool(id: 'root.magiczionos', name: '#magiczionos', category: ArsenalCategory.system, availability: ArsenalAvailability.notConfigured, reason: 'Availability is determined at runtime by SU, Chroot or PRoot.'),
    ArsenalTool(id: 'root.chroot', name: 'Chroot Root', category: ArsenalCategory.system, availability: ArsenalAvailability.notConfigured, reason: 'Requires real root and a validated distro rootfs.'),
    ArsenalTool(id: 'ssh.client', name: 'SSH Client', category: ArsenalCategory.network, availability: ArsenalAvailability.notConfigured, command: 'ssh', reason: 'SSH userland executable is not installed.'),
    ArsenalTool(id: 'ssh.sftp', name: 'SFTP', category: ArsenalCategory.network, availability: ArsenalAvailability.notConfigured, command: 'sftp', reason: 'SSH userland executable is not installed.'),
    ArsenalTool(id: 'storage.setup', name: 'Storage Setup', category: ArsenalCategory.utility, availability: ArsenalAvailability.permissionRequired, reason: 'Public storage access requires Android runtime authorization.'),
    ArsenalTool(id: 'forensics.hash', name: 'File Hashing', category: ArsenalCategory.forensics, availability: ArsenalAvailability.available),
    ArsenalTool(id: 'crypto.hash', name: 'Cryptographic Hashes', category: ArsenalCategory.crypto, availability: ArsenalAvailability.available),
    ArsenalTool(id: 'ai.analysis', name: 'Security Analysis', category: ArsenalCategory.ai, availability: ArsenalAvailability.available),
    ArsenalTool(id: 'web.inspect', name: 'Web Inspection', category: ArsenalCategory.web, availability: ArsenalAvailability.available),
    ArsenalTool(id: 'wireless.analysis', name: 'Wireless Defensive Analysis', category: ArsenalCategory.wireless, availability: ArsenalAvailability.permissionRequired),
    ArsenalTool(id: 'defense.audit', name: 'Security Audit', category: ArsenalCategory.defense, availability: ArsenalAvailability.available),
    ArsenalTool(id: 'analysis.logs', name: 'Audit Log Analysis', category: ArsenalCategory.analysis, availability: ArsenalAvailability.available),
    ArsenalTool(id: 'utility.system-info', name: 'System Information', category: ArsenalCategory.utility, availability: ArsenalAvailability.available),
    ArsenalTool(id: 'attack.lab', name: 'Authorized Lab Runner', category: ArsenalCategory.attack, availability: ArsenalAvailability.notConfigured, reason: 'Requires an explicitly configured isolated lab target.'),
  ];
}


class ArsenalRuntimeResolver {
  const ArsenalRuntimeResolver();

  Future<ArsenalRegistry> resolve([ArsenalRegistry? registry]) async {
    final source = registry ?? ArsenalRegistry();
    final tools = <ArsenalTool>[];
    for (final tool in source.tools) {
      tools.add(await _resolveTool(tool));
    }
    return ArsenalRegistry(tools: tools);
  }

  Future<ArsenalTool> _resolveTool(ArsenalTool tool) async {
    final command = tool.command?.trim();
    if (command == null || command.isEmpty) return tool;
    final candidates = <String>[];
    if (tool.id == 'terminal.shell') {
      candidates.addAll(<String>['/system/bin/sh', '/bin/sh', 'sh']);
    } else if (command.startsWith('/')) {
      candidates.add(command);
    } else {
      candidates.add('/data/data/com.zion.os/files/usr/bin/$command');
      candidates.add('/data/data/com.zion.os/files/usr/sbin/$command');
      candidates.add('/system/bin/$command');
      candidates.add('/system/xbin/$command');
      final path = Platform.environment['PATH'] ?? '';
      for (final dir in path.split(':').where((e) => e.isNotEmpty)) {
        candidates.add('$dir/$command');
      }
    }
    for (final candidate in candidates.toSet()) {
      try {
        final stat = await File(candidate).stat();
        if (stat.type == FileSystemEntityType.file && (stat.mode & 0x49) != 0) {
          return tool.copyWith(availability: ArsenalAvailability.available, reason: null);
        }
      } catch (_) {}
    }
    return tool.copyWith(
      availability: ArsenalAvailability.notConfigured,
      reason: 'Executable is not present or not reachable from the Zion runtime.',
    );
  }
}
