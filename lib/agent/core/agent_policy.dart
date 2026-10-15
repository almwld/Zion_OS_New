import 'agent_models.dart';

class AgentPolicyDecision {
  final AgentRisk risk;
  final String reason;
  final bool requiresApproval;

  const AgentPolicyDecision({
    required this.risk,
    required this.reason,
    required this.requiresApproval,
  });
}

class AgentPolicy {
  const AgentPolicy();

  AgentPolicyDecision evaluate({
    required String tool,
    required Map<String, dynamic> params,
  }) {
    if (tool == 'shell') {
      final command = (params['command'] ?? '').toString().trim();
      if (command.isEmpty) {
        return const AgentPolicyDecision(
          risk: AgentRisk.blocked,
          reason: 'أمر shell فارغ.',
          requiresApproval: false,
        );
      }
      if (_blockedShell(command)) {
        return const AgentPolicyDecision(
          risk: AgentRisk.blocked,
          reason: 'الأمر محظور من سياسة Zion Agent.',
          requiresApproval: false,
        );
      }
      if (!_safeShell(command)) {
        return const AgentPolicyDecision(
          risk: AgentRisk.review,
          reason: 'الأمر خارج قائمة التنفيذ التلقائي.',
          requiresApproval: true,
        );
      }
    }

    if (tool == 'http' &&
        (params['method'] ?? 'GET').toString().toUpperCase() != 'GET') {
      return const AgentPolicyDecision(
        risk: AgentRisk.review,
        reason: 'HTTP الذي يغيّر بيانات يحتاج موافقة.',
        requiresApproval: true,
      );
    }
    if (tool == 'file') {
      final action = (params['action'] ?? 'read').toString();
      if (action != 'read' && action != 'list') {
        return const AgentPolicyDecision(
          risk: AgentRisk.review,
          reason: 'تعديل الملفات يحتاج موافقة.',
          requiresApproval: true,
        );
      }
    }
    if (tool == 'python') {
      return const AgentPolicyDecision(
        risk: AgentRisk.review,
        reason: 'Python يعمل في مساحة المهمة وليس sandbox نظام تشغيل حقيقياً.',
        requiresApproval: true,
      );
    }
    return const AgentPolicyDecision(
      risk: AgentRisk.safe,
      reason: 'الأداة مسموحة.',
      requiresApproval: false,
    );
  }

  bool _blockedShell(String command) {
    final c = command.toLowerCase();
    const blocked = <String>[
      'rm -rf /',
      'mkfs',
      'dd if=',
      'shutdown',
      'reboot',
      'chmod 777 /',
      'mount ',
      'iptables -f',
    ];
    return blocked.any(c.contains);
  }

  bool _safeShell(String command) {
    final c = command.trim().toLowerCase();
    // Compound shell commands stay review-only; never auto-admit chaining.
    if (c.contains('&&') ||
        c.contains('||') ||
        c.contains(';') ||
        c.contains('|')) {
      return false;
    }

    const diagnosticCommands = <String>[
      'git status',
      'git status --short',
      'git status --branch',
      'git diff --check',
      'git diff --stat',
      'git diff --name-only',
      'git log --oneline',
      'git rev-parse --show-toplevel',
      'flutter --version',
      'dart --version',
      'dpkg -l',
      'apt list --installed',
      'pkg list-installed',
      'zion-pkg list',
    ];
    if (diagnosticCommands.contains(c)) return true;
    if (RegExp(r'^git log --oneline -n [1-9][0-9]?$').hasMatch(c)) {
      return true;
    }
    if (RegExp(r'^(which|command -v) [a-zA-Z0-9._/-]+$')
        .hasMatch(command.trim())) {
      return true;
    }

    // Bounded read-only inventory of shared storage and local distro roots.
    if (RegExp(r'^find /storage/emulated/0 -maxdepth [1-4] -type [df]$')
        .hasMatch(c)) {
      return true;
    }
    if (RegExp(
      r'^find /data/data/com\.zion\.os/files/home/\.zion/dists -maxdepth [1-5] -type [df]$',
    ).hasMatch(c)) {
      return true;
    }
    if (RegExp(r'^ls( -la)? /storage/emulated/0(/[^;&|]+)?$')
        .hasMatch(command.trim())) {
      return true;
    }
    if (RegExp(r'^zion-pkg search [a-zA-Z0-9.+_-]+$').hasMatch(c)) {
      return true;
    }

    return RegExp(
      r'^(pwd|ls(\s+-[a-z-]+)?(\s+[^\s]+)?|cat\s+[^\s]+|echo\s+.+|whoami|id|uname(\s+-[a-z]+)?|date|df(\s+-[a-z]+)?|du(\s+-[a-z]+)?|ps(\s+-[a-z]+)?)$',
    ).hasMatch(c);
  }
}
