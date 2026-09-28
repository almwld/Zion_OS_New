import 'dart:io';

class TermuxPackage {
  const TermuxPackage({required this.name, required this.version, required this.architecture, required this.status, this.depends = ''});
  final String name;
  final String version;
  final String architecture;
  final String status;
  final String depends;
  bool get installed => status.split(' ').last == 'installed';
}

class TermuxPackageReader {
  const TermuxPackageReader({Future<String> Function(String path)? readFile}) : _readFile = readFile;
  final Future<String> Function(String path)? _readFile;

  Future<List<TermuxPackage>> readStatus(String path) async {
    final raw = _readFile != null ? await _readFile!(path) : await File(path).readAsString();
    return _parse(raw);
  }

  List<TermuxPackage> _parse(String raw) {
    final records = <TermuxPackage>[];
    for (final record in raw.split(RegExp(r'\r?\n\r?\n+'))) {
      final fields = <String, String>{};
      String? current;
      for (final line in record.split(RegExp(r'\r?\n'))) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith(RegExp(r'\s'))) {
          if (current != null) fields[current] = (fields[current] ?? '') + '\n' + line.trim();
          continue;
        }
        final separator = line.indexOf(':');
        if (separator <= 0) continue;
        current = line.substring(0, separator).trim();
        fields[current] = line.substring(separator + 1).trim();
      }
      final name = fields['Package'];
      final version = fields['Version'];
      final architecture = fields['Architecture'];
      final status = fields['Status'];
      if (name == null || version == null || architecture == null || status == null) continue;
      if (!status.endsWith('installed')) continue;
      records.add(TermuxPackage(name: name, version: version, architecture: architecture, status: status, depends: fields['Depends'] ?? ''));
    }
    return records;
  }
}
