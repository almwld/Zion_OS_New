import 'dart:io';

import 'package:archive/archive.dart';

class TermuxTarArchive {
  const TermuxTarArchive._({required this.success, required this.message, this.statusContent});
  final bool success;
  final String message;
  final String? statusContent;

  static Future<TermuxTarArchive> open(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return const TermuxTarArchive._(success: false, message: 'ERROR: TAR file not found.');
      var bytes = await file.readAsBytes();
      final lower = path.toLowerCase();
      if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) bytes = GZipDecoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(bytes, verify: true, storeData: true);
      String? status;
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final name = entry.name.replaceAll('\\\\', '/').replaceFirst(RegExp(r'^\\./'), '');
        if (name == 'var/lib/dpkg/status' || name.endsWith('/var/lib/dpkg/status')) {
          status = String.fromCharCodes(entry.readBytes() ?? const <int>[]); break;
        }
      }
      if (status == null) return const TermuxTarArchive._(success: false, message: 'UNAVAILABLE: TAR does not contain a Termux dpkg status database.');
      return TermuxTarArchive._(success: true, message: 'TAR status database detected.', statusContent: status);
    } catch (e) {
      return TermuxTarArchive._(success: false, message: 'ERROR: invalid or unreadable TAR: ' + e.toString());
    }
  }
}