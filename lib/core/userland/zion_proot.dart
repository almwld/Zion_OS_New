import 'dart:io';

enum ZionDistro { ubuntu, debian, kali, arch, alpine }
enum ProotStatus { available, notConfigured, unavailable }

class ProotRuntimeInfo {
  const ProotRuntimeInfo({required this.status, required this.executable, required this.reason});
  final ProotStatus status; final String? executable; final String reason;
}

class ZionProot {
  static const prefix = '/data/data/com.zion.os/files/usr';
  static const home = '/data/data/com.zion.os/files/home';
  static const distroRoot = home + '/.zion/dists';
  const ZionProot();
  Future<ProotRuntimeInfo> inspect() async {
    final executable = prefix + '/bin/proot';
    if (!await _isExecutable(executable)) return const ProotRuntimeInfo(status: ProotStatus.notConfigured, executable: null, reason: 'PRoot is not installed inside Zion Userland.');
    return ProotRuntimeInfo(status: ProotStatus.available, executable: executable, reason: 'REAL PRoot executable resolved from Zion Userland.');
  }
  Future<bool> rootfsExists(ZionDistro distro) => Directory(rootfsPath(distro)).exists();
  String rootfsPath(ZionDistro distro) => distroRoot + '/' + distro.name + '/rootfs';
  String? validateDistro(String name) { final normalized = name.trim().toLowerCase(); for (final distro in ZionDistro.values) { if (distro.name == normalized) return distro.name; } return null; }
  Future<Process> start(ZionDistro distro, {List<String> command = const ['/bin/sh', '-l']}) async {
    final info = await inspect(); if (info.status != ProotStatus.available || info.executable == null) throw StateError(info.reason);
    final rootfs = rootfsPath(distro); if (!await Directory(rootfs).exists()) throw StateError('Rootfs for ' + distro.name + ' is not installed.');
    if (command.isEmpty || command.any(_unsafeArgument)) throw ArgumentError('Invalid PRoot command arguments.');
    final args = <String>['-0','-r',rootfs,'-b','/dev','-b','/proc','-b','/sys','-b',home + ':' + home,'-w','/root',...command];
    final environment = <String,String>{'HOME':'/root','PATH':'/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin','TERM':Platform.environment['TERM'] ?? 'xterm-256color','LANG':Platform.environment['LANG'] ?? 'C.UTF-8'};
    return Process.start(info.executable!, args, environment: environment, runInShell: false);
  }
  bool _unsafeArgument(String value) => value.contains('\u0000') || value.contains('\n') || value.contains('\r');
  Future<bool> _isExecutable(String path) async { try { final stat = await File(path).stat(); return stat.type == FileSystemEntityType.file && (stat.mode & 0x49) != 0; } catch (_) { return false; } }
}