import 'dart:convert';
import 'dart:io';

import '../../../security/core/security_core.dart';
import 'termux_tar_archive.dart';
import '../zion_pkg.dart';
import '../zion_repository.dart';
import 'dependency_checker.dart';
import 'package_reader.dart';
import 'path_converter.dart';
import 'termux_detector.dart';
import 'verification_runner.dart';

enum TermuxImportMode { check, auto, verify, clean }

class TermuxImportResult {
  const TermuxImportResult({required this.mode, required this.success, required this.message, this.checked = 0, this.matched = 0, this.installed = 0, this.unavailable = const <String>[], this.failed = const <String>[]});
  final TermuxImportMode mode;
  final bool success;
  final String message;
  final int checked;
  final int matched;
  final int installed;
  final List<String> unavailable;
  final List<String> failed;
}

class TermuxImporter {
  static const manifestPath = ZionPkg.prefix + '/var/lib/zion-pkg/termux-import.json';

  TermuxImporter({ZionPkg? pkg, ZionRepository? repository, TermuxDetector? detector, TermuxPackageReader? reader, SecurityCore? securityCore})
      : _pkg = pkg ?? ZionPkg(repository: repository, securityCore: securityCore),
        _repository = repository ?? ZionRepository(),
        _detector = detector ?? const TermuxDetector(),
        _reader = reader ?? const TermuxPackageReader(),
        _securityCore = securityCore;

  final ZionPkg _pkg;
  final ZionRepository _repository;
  final TermuxDetector _detector;
  final TermuxPackageReader _reader;
  final SecurityCore? _securityCore;

  Future<TermuxImportResult> runTar(String tarPath, TermuxImportMode mode) async {
    if (mode != TermuxImportMode.check && mode != TermuxImportMode.auto) return TermuxImportResult(mode: mode, success: false, message: 'ERROR: TAR import supports --check or --auto only.');
    final archive = await TermuxTarArchive.open(tarPath);
    if (!archive.success) { _audit('termux.import.tar.' + mode.name, 'failed', {'path': tarPath, 'reason': archive.message}); return TermuxImportResult(mode: mode, success: false, message: archive.message); }
    final tempDir = await Directory.systemTemp.createTemp('zion-termux-import-');
    try {
      final statusFile = File(tempDir.path + '/status');
      await statusFile.writeAsString(archive.statusContent!, flush: true);
      final result = await _runStatus(mode, statusFile.path, 'tar:' + tarPath);
      _audit('termux.import.tar.' + mode.name, result.success ? 'success' : 'partial', {'path': tarPath, 'checked': result.checked, 'matched': result.matched, 'installed': result.installed});
      return result;
    } finally { await tempDir.delete(recursive: true); }
  }

  Future<TermuxImportResult> _runStatus(TermuxImportMode mode, String statusPath, String sourceLabel) async {
    final sourcePackages = await _reader.readStatus(statusPath);
    final repoPackages = await _repository.listAll();
    var matched = 0; var installed = 0;
    final unavailable = <String>[]; final failed = <String>[]; final importedNames = <String>[];
    for (final source in sourcePackages) {
      final targetArch = TermuxPathConverter.normalizeArchitecture(source.architecture);
      final candidate = _selectCandidate(source, repoPackages, targetArch);
      if (candidate == null) { unavailable.add(source.name); continue; }
      matched++;
      final dependencyCheck = await TermuxDependencyChecker(_repository).check(source, candidate.architecture);
      if (!dependencyCheck.ok) { failed.add(source.name + ': missing dependencies ' + dependencyCheck.missing.join(', ')); continue; }
      if (mode == TermuxImportMode.check) continue;
      final result = await _pkg.installByName(source.name, sourceLabel: 'termux-import');
      if (result.success) { installed++; importedNames.add(source.name); _audit('termux.import.install', 'success', {'package': source.name, 'version': candidate.version, 'architecture': candidate.architecture, 'source': sourceLabel}); }
      else { failed.add(source.name + ': ' + (result.error ?? result.message ?? '')); }
    }
    if (mode == TermuxImportMode.auto && importedNames.isNotEmpty) await _writeManifest(importedNames);
    final success = failed.isEmpty && unavailable.isEmpty;
    return TermuxImportResult(mode: mode, success: success, message: 'checked=' + sourcePackages.length.toString() + ', matched=' + matched.toString() + ', installed=' + installed.toString() + ', unavailable=' + unavailable.length.toString() + ', failed=' + failed.length.toString(), checked: sourcePackages.length, matched: matched, installed: installed, unavailable: unavailable, failed: failed);
  }

  Future<TermuxImportResult> run(TermuxImportMode mode) async {
    if (mode == TermuxImportMode.clean) return _clean();
    if (mode == TermuxImportMode.verify) return _verifyManifest();

    final detection = await _detector.detect();
    if (!detection.accessible) {
      _audit('termux.import.' + mode.name, 'UNAVAILABLE', {'reason': detection.reason, 'root': detection.rootPath});
      return TermuxImportResult(mode: mode, success: false, message: 'UNAVAILABLE: ' + detection.reason);
    }

    final result = await _runStatus(mode, detection.statusPath, 'termux');
    _audit('termux.import.' + mode.name, result.success ? 'success' : 'partial', {'checked': result.checked, 'matched': result.matched, 'installed': result.installed, 'unavailable': result.unavailable.length, 'failed': result.failed.length});
    return result;
  }

  PackageInfo? _selectCandidate(TermuxPackage source, List<PackageInfo> packages, String targetArch) {
    final compatible = packages.where((p) => p.name == source.name && TermuxPathConverter.isCompatible(p.architecture, targetArch)).toList();
    if (compatible.isEmpty) return null;
    for (final package in compatible) {
      if (package.version == source.version) return package;
    }
    return compatible.first;
  }

  Future<TermuxImportResult> _verifyManifest() async {
    final names = await _readManifest();
    final result = await TermuxVerificationRunner(_pkg).verify(names);
    _audit('termux.import.verify', result.ok ? 'success' : 'failed', {'checked': result.checked, 'missing': result.missing.length});
    return TermuxImportResult(mode: TermuxImportMode.verify, success: result.ok, message: 'checked=' + result.checked.toString() + ', missing=' + result.missing.length.toString(), checked: result.checked, matched: result.checked - result.missing.length, unavailable: result.missing);
  }

  Future<TermuxImportResult> _clean() async {
    final names = await _readManifest();
    final removed = <String>[];
    final failed = <String>[];

    for (final name in names) {
      final info = await _pkg.findPackage(name);
      if (info == null || info.source != 'termux-import') continue;
      final result = await _pkg.remove(name);
      if (result.success) {
        removed.add(name);
      } else {
        failed.add(name + ': ' + (result.error ?? result.message ?? ''));
      }
    }

    await _writeManifest(const <String>[]);
    _audit('termux.import.clean', failed.isEmpty ? 'success' : 'partial', {'removed': removed.length, 'failed': failed.length});
    return TermuxImportResult(mode: TermuxImportMode.clean, success: failed.isEmpty, message: 'removed=' + removed.length.toString() + ', failed=' + failed.length.toString(), installed: removed.length, failed: failed);
  }

  Future<List<String>> _readManifest() async {
    try {
      final file = File(manifestPath);
      if (!await file.exists()) return const <String>[];
      final value = jsonDecode(await file.readAsString());
      if (value is! List) return const <String>[];
      return value.whereType<String>().toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> _writeManifest(List<String> names) async {
    final file = File(manifestPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(names.toSet().toList()), flush: true);
  }

  void _audit(String action, String outcome, Map<String, Object?> metadata) {
    _securityCore?.auditLogger.log(action: action, actor: 'zion-pkg', outcome: outcome, target: 'termux-import', metadata: metadata);
  }
}
