import 'dart:io';

class TermuxDetection {
  const TermuxDetection({required this.rootPath, required this.statusPath, required this.accessible, required this.reason});
  final String rootPath;
  final String statusPath;
  final bool accessible;
  final String reason;
}

class TermuxDetector {
  const TermuxDetector({this.rootPath = '/data/data/com.termux/files', Future<bool> Function(String path)? exists}) : _exists = exists;
  final String rootPath;
  final Future<bool> Function(String path)? _exists;

  Future<TermuxDetection> detect() async {
    final statusPath = rootPath + '/var/lib/dpkg/status';
    if (!await _pathExists(rootPath)) {
      return TermuxDetection(rootPath: rootPath, statusPath: statusPath, accessible: false, reason: 'Termux غير موجود أو غير قابل للوصول.');
    }
    if (!await _pathExists(statusPath)) {
      return TermuxDetection(rootPath: rootPath, statusPath: statusPath, accessible: false, reason: 'تم العثور على مسار Termux لكن قاعدة dpkg غير متاحة.');
    }
    return TermuxDetection(rootPath: rootPath, statusPath: statusPath, accessible: true, reason: 'تم العثور على قاعدة dpkg الخاصة بـ Termux.');
  }

  Future<bool> _pathExists(String path) async {
    if (_exists != null) return _exists!(path);
    try { return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound; } catch (_) { return false; }
  }
}
