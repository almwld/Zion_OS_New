import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'kali_chroot_service.dart';

/// Real Kali/PRoot lifecycle manager.
///
/// The runtime is only reported as available after the actual binary and
/// filesystem are detected. High-risk offensive wrappers are deliberately not
/// exposed here; defensive discovery can use the safe Nmap adapter below.
class KaliLoaderService {
  static const String _installPath = '/data/local/kali';
  static const String _zionFolder = '/storage/emulated/0/Zion Universal';

  static String? _prootPath;
  static bool _hasRootCache = false;
  static bool _rootChecked = false;

  static final List<Map<String, String>> _sources = [
    {'name': 'bootstrap-aarch64.zip', 'path': '$_zionFolder/bootstrap-aarch64.zip', 'type': 'zip'},
    {'name': 'kali-bootstrap.tar.gz', 'path': '$_zionFolder/kali-bootstrap.tar.gz', 'type': 'tar'},
  ];

  static Future<bool> extractEmbeddedProot() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final prootDir = Directory('${appDir.path}/bin');
      if (!await prootDir.exists()) await prootDir.create(recursive: true);
      final prootPath = '${prootDir.path}/proot';
      final prootFile = File(prootPath);
      if (await prootFile.exists()) {
        if (await _testProot(prootPath)) {
          _prootPath = prootPath;
          return true;
        }
        await prootFile.delete();
      }
      final byteData = await rootBundle.load('assets/bin/proot');
      await prootFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      final chmod = await Process.run('chmod', ['755', prootPath], runInShell: true);
      if (chmod.exitCode != 0) return false;
      if (!await _testProot(prootPath)) return false;
      _prootPath = prootPath;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _testProot(String prootPath) async {
    try {
      final result = await Process.run(prootPath, ['--version'], runInShell: true);
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> findProot() async {
    if (_prootPath != null && await File(_prootPath!).exists() && await _testProot(_prootPath!)) {
      return _prootPath;
    }
    if (await extractEmbeddedProot()) return _prootPath;
    const candidates = [
      '/data/data/com.termux/files/usr/bin/proot',
      '/usr/bin/proot',
      '/usr/local/bin/proot',
    ];
    for (final path in candidates) {
      if (await File(path).exists() && await _testProot(path)) return path;
    }
    return null;
  }

  static Future<bool> hasRootAccess() async {
    if (_rootChecked) return _hasRootCache;
    _rootChecked = true;
    try {
      final whichSu = await Process.run('which', ['su'], runInShell: true);
      if (whichSu.exitCode != 0) return _hasRootCache = false;
      final result = await Process.run('su', ['-c', 'id -u'], runInShell: true);
      _hasRootCache = result.exitCode == 0 && result.stdout.toString().trim() == '0';
    } catch (_) {
      _hasRootCache = false;
    }
    return _hasRootCache;
  }

  static Future<bool> hasChroot() async => await hasRootAccess() && await Directory(_installPath).exists();

  static Future<String> install() async {
    if (await _isInstalled()) return 'REAL: Kali filesystem is already installed.';
    String? archive;
    String? type;
    for (final source in _sources) {
      if (await File(source['path']!).exists()) {
        archive = source['path'];
        type = source['type'];
        break;
      }
    }
    if (archive == null) return 'UNAVAILABLE: no local Kali bootstrap archive was found.';
    if (!await _extract(archive, type!)) return 'FAILED: Kali archive extraction failed.';
    await _setupEnvironment();
    return 'COMPLETED: Kali filesystem installed; runtime still requires a working PRoot adapter.';
  }

  /// Generic command execution is intentionally restricted to harmless
  /// diagnostics. High-risk tooling is exposed as BLOCKED instead.
  static Future<Map<String, dynamic>> execute(String command) async {
    if (!await _isInstalled()) return {'success': false, 'status': 'UNAVAILABLE', 'error': 'Kali is not installed.'};
    final normalized = command.trim().toLowerCase();
    const blocked = <String>[
      'msfconsole', 'hydra ', 'aircrack', 'john ', 'sqlmap', 'wpscan', 'ettercap',
      'bettercap', 'responder', 'hashcat', 'mitmproxy', 'beef',
    ];
    if (blocked.any(normalized.startsWith)) {
      return {'success': false, 'status': 'BLOCKED', 'error': 'High-risk offensive tool execution is disabled.'};
    }
    if (!_isSafeDiagnosticCommand(normalized)) {
      return {'success': false, 'status': 'BLOCKED', 'error': 'Only defensive diagnostics are allowed through this adapter.'};
    }
    final prootPath = await findProot();
    if (prootPath == null) return {'success': false, 'status': 'UNAVAILABLE', 'error': 'PRoot runtime is unavailable.'};
    return _executeProot(command, prootPath);
  }

  static bool _isSafeDiagnosticCommand(String command) {
    return RegExp(r'^(id|uname|whoami|pwd|date|hostname|cat /etc/os-release|which nmap|nmap\s+-sn\s+[^;&|`]+)$').hasMatch(command);
  }

  static Future<Map<String, dynamic>> _executeProot(String command, String prootPath) async {
    try {
      final result = await Process.run(prootPath, [
        '-r', _installPath,
        '-b', '/dev:/dev',
        '-b', '/proc:/proc',
        '-b', '/sys:/sys',
        '-b', '/sdcard:/sdcard',
        '-b', '/storage/emulated/0:/storage/emulated/0',
        '-w', '/root',
        '/bin/bash', '-c', command,
      ], runInShell: true);
      return {
        'success': result.exitCode == 0,
        'status': result.exitCode == 0 ? 'COMPLETED' : 'FAILED',
        'stdout': result.stdout.toString().trim(),
        'stderr': result.stderr.toString().trim(),
        'exitCode': result.exitCode,
      };
    } catch (e) {
      return {'success': false, 'status': 'FAILED', 'error': e.toString()};
    }
  }

  static Future<String> nmapDiscovery(String target) async {
    if (!RegExp(r'^[A-Za-z0-9.:%/_-]+$').hasMatch(target)) return 'FAILED: invalid target.';
    final result = await execute('nmap -sn $target');
    return result['stdout']?.toString() ?? result['stderr']?.toString() ?? result['error']?.toString() ?? 'FAILED';
  }

  static Future<bool> _isInstalled() async => Directory(_installPath).exists();

  static Future<bool> _extract(String archivePath, String type) async {
    try {
      await Directory(_installPath).create(recursive: true);
      final result = type == 'zip'
          ? await Process.run('unzip', ['-o', archivePath, '-d', _installPath], runInShell: true)
          : await Process.run('tar', ['-xzf', archivePath, '-C', _installPath], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _setupEnvironment() async {
    for (final dir in ['dev', 'proc', 'sys', 'tmp']) {
      await Directory('$_installPath/$dir').create(recursive: true);
    }
  }

  static Future<Map<String, dynamic>> getStatus() async {
    final installed = await _isInstalled();
    final root = await hasRootAccess();
    final chroot = await hasChroot();
    final proot = await findProot();
    return {
      'installed': installed,
      'path': _installPath,
      'has_root': root,
      'use_chroot': chroot,
      'mode': chroot ? 'CHROOT' : (proot != null ? 'PROOT' : 'MISSING'),
      'proot_available': proot != null,
      'proot_path': proot ?? '',
    };
  }

  static Future<bool> isAvailable() async => await _isInstalled();

  static Future<int> getToolCount() async {
    if (!await _isInstalled()) return 0;
    final result = await execute('which nmap');
    return result['success'] == true ? 1 : 0;
  }
}
