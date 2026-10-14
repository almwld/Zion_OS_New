import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../magiczionos/installers/proot_installer.dart';
import 'kali_chroot_service.dart';
import '../magiczionos/installers/rootfs_downloader.dart';

/// Real Kali/PRoot lifecycle manager.
///
/// The runtime is only reported as available after the actual binary and
/// filesystem are detected. High-risk offensive wrappers are deliberately not
/// exposed here; defensive discovery can use the safe Nmap adapter below.
class KaliLoaderService {
  static const String _installPath = '/data/data/com.zion.os/files/home/.zion/dists/kali/rootfs';
  static const String _localRootfsPreferenceKey = 'zion_terminal_kali_rootfs_path_v1';

  static Future<String?> _resolveRootfsPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configured = prefs.getString(_localRootfsPreferenceKey)?.trim();
      if (configured != null && configured.startsWith('/')) {
        if (await File('$configured/bin/sh').exists() &&
            await File('$configured/bin/bash').exists()) {
          return configured;
        }
      }
    } catch (_) {
      // The preference is optional; use the app-private rootfs if available.
    }
    if (await File('$_installPath/bin/sh').exists() &&
        await File('$_installPath/bin/bash').exists() &&
        await File('/data/data/com.zion.os/files/home/.zion/dists/kali/.zion-rootfs.json').exists()) {
      return _installPath;
    }
    return null;
  }

  static String? _prootPath;
  static bool _hasRootCache = false;
  static bool _rootChecked = false;

  static Future<bool> extractEmbeddedProot() async {
    // Install only the verified Zion PRoot build into the canonical Zion Userland prefix.
    try {
      final installed = await ProotInstaller().install();
      final path = installed.path;
      if (!installed.success || path == null || !await _testProot(path)) return false;
      _prootPath = path;
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
    // Resolve PRoot exclusively from the canonical Zion Userland prefix.
    const candidates = [
      '/data/data/com.zion.os/files/usr/bin/proot',
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
    final existingRootfs = await _resolveRootfsPath();
    if (existingRootfs != null) return 'REAL: Kali filesystem is already available at $existingRootfs; no copy performed.';
    try {
      final result = await RootfsDownloader().install(ZionRootfsDistro.kali);
      if (!result.success) return 'FAILED: ' + result.message;
      await _setupEnvironment();
      return 'COMPLETED: Kali rootfs downloaded, checksum-verified and installed in Zion storage.';
    } catch (error) {
      return 'FAILED: Zion Kali rootfs installation failed: $error';
    }
  }

  /// Generic command execution is intentionally restricted to harmless
  /// diagnostics. High-risk tooling is exposed as BLOCKED instead.
  static Future<Map<String, dynamic>> execute(String command) async {
    final rootfsPath = await _resolveRootfsPath();
    if (rootfsPath == null) return {'success': false, 'status': 'UNAVAILABLE', 'error': 'No valid local Kali rootfs was found. Configure the path in Zion Terminal.'};
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
    return _executeProot(command, prootPath, rootfsPath);
  }

  static bool _isSafeDiagnosticCommand(String command) {
    return RegExp(r'^(id|uname|whoami|pwd|date|hostname|cat /etc/os-release|which nmap|nmap\s+-sn\s+[^;&|`]+)$').hasMatch(command);
  }

  static Future<Map<String, dynamic>> _executeProot(String command, String prootPath, String rootfsPath) async {
    try {
      final result = await Process.run(prootPath, [
        '-r', rootfsPath,
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

  static Future<bool> _isInstalled() async => await _resolveRootfsPath() != null;


  static Future<void> _setupEnvironment() async {
    for (final dir in ['dev', 'proc', 'sys', 'tmp']) {
      await Directory('$_installPath/$dir').create(recursive: true);
    }
  }

  static Future<Map<String, dynamic>> getStatus() async {
    final rootfsPath = await _resolveRootfsPath();
    final installed = rootfsPath != null;
    final root = await hasRootAccess();
    final chroot = rootfsPath == _installPath && await hasChroot();
    final proot = await findProot();
    return {
      'installed': installed,
      'path': rootfsPath ?? _installPath,
      'rootfs_source': rootfsPath == null ? 'missing' : (rootfsPath == _installPath ? 'zion-private' : 'configured-local'),
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
