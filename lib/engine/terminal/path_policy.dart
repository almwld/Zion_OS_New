import 'dart:io';
import 'command_policy.dart';

class PathPolicy {
  PathPolicy({List<String>? allowedRoots,List<String>? forbiddenPaths})
      : allowedRoots=List.unmodifiable(allowedRoots??const [
          '/data/data/com.zion.os/files/zion_agent_sandbox',
          '/data/data/com.zion.os/files/sandbox',
          '/storage/emulated/0/Download/zion_workspace',
          '~/Zion_OS_New',
        ]),
        forbiddenPaths=List.unmodifiable(forbiddenPaths??const [
          '/etc/shadow','/etc/sudoers','/proc/','/sys/','/storage/emulated/0/DCIM',
          '/WhatsApp','/Telegram','/sdcard/.ssh','.env','.aws','.config'
        ]);
  final List<String> allowedRoots;
  final List<String> forbiddenPaths;

  List<String> extractPaths(String command) {
    final tokens=command.split(RegExp(r'\s+'));
    return tokens
      .map((t)=>t.replaceAll(RegExp(r'''^["']|["']$'''),''))
      .where((t)=>t.startsWith('/')||t.startsWith('~/')||t.startsWith('./')||t.contains('/'))
      .where((t)=>t.isNotEmpty)
      .toList();
  }

  PolicyResult check(String command) {
    if(command.contains('..')) return PolicyResult.deny('المسار يحتوي على ..');
    final parts=command.split(RegExp(r'\s+')).map((e)=>e.replaceAll(RegExp(r'''^["']|["']$'''),'')).toList();
    for(final part in parts) {
      if(forbiddenPaths.any((p)=>part.toLowerCase().contains(p.toLowerCase()))) {
        return PolicyResult.deny('مسار أو ملف حساس محظور: $part');
      }
    }
    for(final raw in extractPaths(command)) {
      if(raw.startsWith('/')) {
        final normalized=_normalize(raw);
        final roots=allowedRoots.map(_expand).map(_normalize).toList();
        if(!roots.any((root)=>normalized==root||normalized.startsWith('$root/'))) {
          return PolicyResult.deny('المسار المطلق خارج الجذور المسموحة: $raw');
        }
      } else if(raw.startsWith('~/')) {
        final normalized=_normalize(_expand(raw));
        final roots=allowedRoots.map(_expand).map(_normalize);
        if(!roots.any((root)=>normalized==root||normalized.startsWith('$root/'))) {
          return PolicyResult.deny('مسار المنزل غير مصرح: $raw');
        }
      }
    }
    return PolicyResult.allow();
  }

  String _expand(String path) {
    if(!path.startsWith('~/')) return path;
    final home=Platform.environment['HOME']??'/data/data/com.zion.os/files/home';
    return '$home/${path.substring(2)}';
  }
  String _normalize(String path) {
    final parts=<String>[];
    for(final part in path.split('/')) {
      if(part.isEmpty||part=='.') continue;
      if(part=='..') { if(parts.isNotEmpty) parts.removeLast(); }
      else { parts.add(part); }
    }
    return '/${parts.join('/')}';
  }
}
