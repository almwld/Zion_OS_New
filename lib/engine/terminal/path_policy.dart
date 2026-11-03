import 'dart:io';

import 'command_policy.dart';

class PathPolicy {
  PathPolicy({List<String>? allowedRoots, List<String>? forbiddenPaths})
      : allowedRoots = List.unmodifiable(allowedRoots ?? const [
          '/data/data/com.zion.os/files/zion_agent_sandbox',
          '/data/data/com.zion.os/files/sandbox',
          '/storage/emulated/0/Download/zion_workspace',
          '~/Zion_OS_New',
        ]),
        forbiddenPaths = List.unmodifiable(forbiddenPaths ?? const [
          '/etc/shadow','/etc/sudoers','/proc/','/sys/','/storage/emulated/0/DCIM',
          '/WhatsApp','/Telegram','/sdcard/.ssh','.env','.aws','.config'
        ]);
  final List<String> allowedRoots;
  final List<String> forbiddenPaths;
  static final RegExp _pathPattern = RegExp(r'(?:~?/|\./)?[A-Za-z0-9_./ -]+');

  List<String> extractPaths(String command) {
    final tokens = command.split(RegExp(r'\s+'));
    return tokens.where((t) => t.startsWith('/') || t.startsWith('~/') || t.startsWith('./') || t.contains('/'))
        .map((t) => t.replaceAll(RegExp(r'''^["']|["']$'''), '')).where((t) => t.isNotEmpty).toList();
  }

  PolicyResult check(String command) {
    if (command.contains('..')) return PolicyResult.deny('المسار يحتوي على ..');
    final parts = command.split(RegExp(r'\\s+')).map((e)=>e.replaceAll(RegExp(r'''^["']|["']
    for (final raw in paths) {
      final lower = raw.toLowerCase();
      if (forbiddenPaths.any((p) => lower.contains(p.toLowerCase()))) return PolicyResult.deny('مسار محظور: $raw');
      if (raw.startsWith('/')) {
        final normalized = _normalize(raw);
        final roots = allowedRoots.map(_expand).map(_normalize).toList();
        if (!roots.any((root) => normalized == root || normalized.startsWith('$root/'))) {
          return PolicyResult.deny('المسار المطلق خارج الجذور المسموحة: $raw');
        }
      } else if (raw.startsWith('~/')) {
        final expanded = _expand(raw);
        final roots = allowedRoots.map(_expand).map(_normalize);
        if (!roots.any((root) => _normalize(expanded) == root || _normalize(expanded).startsWith('$root/'))) {
          return PolicyResult.deny('مسار المنزل غير مصرح: $raw');
        }
      }
      if (RegExp(r'(^|/)\.').hasMatch(raw) && raw != './') return PolicyResult.deny('المسار المخفي أو النسبي غير مصرح: $raw');
    }
    return PolicyResult.allow();
  }

  String _expand(String p) {
    if (!p.startsWith('~/')) return p;
    final home = Platform.environment['HOME'] ?? '/data/data/com.zion.os/files/home';
    return '$home/${p.substring(2)}';
  }
  String _normalize(String p) {
    final parts = <String>[];
    for (final part in p.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') { if (parts.isNotEmpty) parts.removeLast(); }
      else { parts.add(part); }
    }
    return '/${parts.join('/')}';
  }
}
''), '')).toList();\n    for (final part in parts) {\n      if (forbiddenPaths.any((p) => part.toLowerCase().contains(p.toLowerCase())) || const {'.env','.aws','.config'}.any((p)=>part.toLowerCase().contains(p))) return PolicyResult.deny('مسار أو ملف حساس محظور: $part');\n    }\n    final paths = extractPaths(command);
    for (final raw in paths) {
      final lower = raw.toLowerCase();
      if (forbiddenPaths.any((p) => lower.contains(p.toLowerCase()))) return PolicyResult.deny('مسار محظور: $raw');
      if (raw.startsWith('/')) {
        final normalized = _normalize(raw);
        final roots = allowedRoots.map(_expand).map(_normalize).toList();
        if (!roots.any((root) => normalized == root || normalized.startsWith('$root/'))) {
          return PolicyResult.deny('المسار المطلق خارج الجذور المسموحة: $raw');
        }
      } else if (raw.startsWith('~/')) {
        final expanded = _expand(raw);
        final roots = allowedRoots.map(_expand).map(_normalize);
        if (!roots.any((root) => _normalize(expanded) == root || _normalize(expanded).startsWith('$root/'))) {
          return PolicyResult.deny('مسار المنزل غير مصرح: $raw');
        }
      }
      if (RegExp(r'(^|/)\.').hasMatch(raw) && raw != './') return PolicyResult.deny('المسار المخفي أو النسبي غير مصرح: $raw');
    }
    return PolicyResult.allow();
  }

  String _expand(String p) {
    if (!p.startsWith('~/')) return p;
    final home = Platform.environment['HOME'] ?? '/data/data/com.zion.os/files/home';
    return '$home/${p.substring(2)}';
  }
  String _normalize(String p) {
    final parts = <String>[];
    for (final part in p.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') { if (parts.isNotEmpty) parts.removeLast(); }
      else { parts.add(part); }
    }
    return '/${parts.join('/')}';
  }
}
