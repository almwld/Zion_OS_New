import 'dart:io';

import 'command_policy.dart';

class PathPolicy {
  PathPolicy({List<String>? allowedRoots, List<String>? forbiddenPaths})
      : allowedRoots = List.unmodifiable(allowedRoots ??
            const [
              '/data/data/com.zion.os/files/zion_agent_sandbox',
              '/data/user/0/com.zion.os/files/zion_agent_sandbox',
              '/data/data/com.zion.os/files/sandbox',
              '/storage/emulated/0/Download/zion_workspace',
              '~/Zion_OS_New',
            ]),
        forbiddenPaths = List.unmodifiable(forbiddenPaths ??
            const [
              '/etc/shadow',
              '/etc/sudoers',
              '/proc/',
              '/sys/',
              '/storage/emulated/0/DCIM',
              '/WhatsApp',
              '/Telegram',
              '/sdcard/.ssh',
              '.ssh',
              '.env',
              '.aws',
              '.config',
            ]);

  final List<String> allowedRoots;
  final List<String> forbiddenPaths;

  String _stripQuotes(String token) {
    if (token.length < 2) return token;
    final quoted = (token.startsWith('"') && token.endsWith('"')) ||
        (token.startsWith("'") && token.endsWith("'"));
    return quoted ? token.substring(1, token.length - 1) : token;
  }

  List<String> extractPaths(String command) {
    return command
        .split(RegExp(r'\s+'))
        .map(_stripQuotes)
        .where((token) =>
            token.startsWith('/') ||
            token.startsWith('~/') ||
            token.startsWith('./') ||
            token.contains('/'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  /// يفحص القواعد النصية دون تفسير مسارات PRoot كمسارات Android.
  PolicyResult check(String command) {
    if (command.contains('..')) {
      return PolicyResult.deny('المسار يحتوي على ..');
    }

    final parts = command.split(RegExp(r'\s+')).map(_stripQuotes);
    for (final part in parts) {
      if (forbiddenPaths.any(
        (path) => part.toLowerCase().contains(path.toLowerCase()),
      )) {
        return PolicyResult.deny('مسار أو ملف حساس محظور: $part');
      }
    }

    final roots = allowedRoots.map(_expand).map(_normalize).toList();
    for (final raw in extractPaths(command)) {
      if (!raw.startsWith('/') && !raw.startsWith('~/')) continue;
      final normalized = _normalize(_expand(raw));
      if (!roots.any((root) =>
          normalized == root || normalized.startsWith('$root/'))) {
        return PolicyResult.deny('المسار خارج الجذور المسموحة: $raw');
      }
    }
    return PolicyResult.allow();
  }

  /// يتبع الروابط الرمزية على نظام ملفات Android المحلي فقط.
  ///
  /// لا يستخدم readlink عبر shell؛ فمسارات Kali/PRoot لها فضاء ملفات مستقل.
  Future<PolicyResult> checkAsync(
    String command, {
    String? workingDirectory,
  }) async {
    final lexical = check(command);
    if (!lexical.allowed) return lexical;

    final roots = <String>[];
    for (final root in allowedRoots.map(_expand)) {
      final resolved = await _resolveExistingPath(root);
      roots.add(_normalize(resolved ?? root));
    }

    final candidates = <String>{...extractPaths(command)};
    if (workingDirectory != null) {
      final tokens =
          command.split(RegExp(r'\s+')).map(_stripQuotes).toList();
      if (tokens.isNotEmpty &&
          const {'ls', 'cat', 'grep', 'find', 'wc', 'head', 'tail'}
              .contains(tokens.first)) {
        for (final token in tokens.skip(1)) {
          if (token.isNotEmpty && !token.startsWith('-')) {
            candidates.add(token);
          }
        }
      }
    }

    for (final raw in candidates) {
      final isAbsolute = raw.startsWith('/') || raw.startsWith('~/');
      if (!isAbsolute && workingDirectory == null) continue;
      final hostPath = _normalize(
        isAbsolute ? _expand(raw) : '$workingDirectory/$raw',
      );
      final resolved = await _resolveExistingPath(hostPath);
      if (resolved == null) continue;

      final canonical = _normalize(resolved);
      if (!roots.any((root) =>
          canonical == root || canonical.startsWith('$root/'))) {
        return PolicyResult.deny(
          'الرابط الرمزي يشير إلى مسار خارج الجذور المسموحة: $raw',
        );
      }
    }
    return PolicyResult.allow();
  }

  Future<String?> _resolveExistingPath(String path) async {
    var candidate = path;
    final suffix = <String>[];
    while (candidate.isNotEmpty) {
      try {
        final type =
            await FileSystemEntity.type(candidate, followLinks: false);
        if (type != FileSystemEntityType.notFound) {
          final resolved =
              await FileSystemEntity.resolveSymbolicLinks(candidate);
          return suffix.isEmpty
              ? resolved
              : '$resolved/${suffix.reversed.join('/')}';
        }
      } on FileSystemException {
        // نتابع إلى أقرب مسار موجود ثم نعيد إلحاق الجزء المتبقي.
      }

      final separator = candidate.lastIndexOf('/');
      if (separator <= 0) return null;
      suffix.add(candidate.substring(separator + 1));
      candidate = candidate.substring(0, separator);
    }
    return null;
  }

  String _expand(String path) {
    if (!path.startsWith('~/')) return path;
    final home =
        Platform.environment['HOME'] ?? '/data/data/com.zion.os/files/home';
    return '$home/${path.substring(2)}';
  }

  String _normalize(String path) {
    final parts = <String>[];
    for (final part in path.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else {
        parts.add(part);
      }
    }
    return '/${parts.join('/')}';
  }
}
