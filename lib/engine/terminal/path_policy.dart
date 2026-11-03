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

  List<String> extractPaths(String command) {
    final tokens = command.split(RegExp(r'\s+'));
    return tokens
        .map((token) =>
            token.replaceAll(RegExp(r'''^["']|["']$'''), ''))
        .where((token) =>
            token.startsWith('/') ||
            token.startsWith('~/') ||
            token.startsWith('./') ||
            token.contains('/'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  /// فحص القواعد النصية دون افتراض أن مسارات PRoot هي مسارات Android.
  PolicyResult check(String command) {
    if (command.contains('..')) {
      return PolicyResult.deny('المسار يحتوي على ..');
    }

    final parts = command
        .split(RegExp(r'\s+'))
        .map((part) => part.replaceAll(RegExp(r'''^["']|["']$'''), ''))
        .toList();

    for (final part in parts) {
      if (forbiddenPaths.any(
        (path) => part.toLowerCase().contains(path.toLowerCase()),
      )) {
        return PolicyResult.deny('مسار أو ملف حساس محظور: $part');
      }
    }

    final roots = allowedRoots.map(_expand).map(_normalize).toList();
    for (final raw in extractPaths(command)) {
      if (raw.startsWith('/') || raw.startsWith('~/')) {
        final normalized = _normalize(_expand(raw));
        if (!roots.any((root) =>
            normalized == root || normalized.startsWith('$root/'))) {
          return PolicyResult.deny('المسار خارج الجذور المسموحة: $raw');
        }
      }
    }
    return PolicyResult.allow();
  }

  /// يتبع الروابط الرمزية لمسارات Android المحلية الموجودة فقط.
  ///
  /// لا يستخدم realpath عبر shell؛ فمسارات Kali/PRoot لا تمثل مسارات
  /// نظام ملفات Android، ولا يجوز تفسيرها باستخدام Dart على المضيف.
  Future<PolicyResult> checkAsync(String command) async {
    final lexical = check(command);
    if (!lexical.allowed) return lexical;

    final roots = <String>[];
    for (final root in allowedRoots.map(_expand)) {
      final resolved = await _resolveExistingPath(root);
      roots.add(_normalize(resolved ?? root));
    }

    for (final raw in extractPaths(command)) {
      if (!raw.startsWith('/') && !raw.startsWith('~/')) continue;
      final hostPath = _normalize(_expand(raw));
      final resolved = await _resolveExistingPath(hostPath);
      if (resolved == null) {
        // لا يمكن إثبات سلامة المسار غير الموجود؛ يبقى الفحص النصي فقط.
        continue;
      }
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
        final type = await FileSystemEntity.type(candidate, followLinks: false);
        if (type != FileSystemEntityType.notFound) {
          final entity = type == FileSystemEntityType.directory
              ? Directory(candidate)
              : File(candidate);
          final resolved = await entity.resolveSymbolicLinks();
          return suffix.isEmpty
              ? resolved
              : '$resolved/${suffix.reversed.join('/')}';
        }
      } on FileSystemException {
        // نواصل إلى أقرب مجلد موجود، ثم نعيد إلحاق بقية المسار.
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
    final home = Platform.environment['HOME'] ??
        '/data/data/com.zion.os/files/home';
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
