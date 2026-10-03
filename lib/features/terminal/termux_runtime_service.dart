import 'dart:io';

enum RuntimeStatus {
  available,
  permissionRequired,
  notConfigured,
  unavailable,
}

class RuntimeCapability {
  const RuntimeCapability({required this.id, required this.status, required this.detail, this.path});
  final String id;
  final RuntimeStatus status;
  final String detail;
  final String? path;
  Map<String, Object?> toJson() => <String, Object?>{'id': id, 'status': status.name.toUpperCase(), 'detail': detail, 'path': path};
}

class TermuxRuntimeService {
  static const home = '/data/data/com.zion.os/files/home';
  static const prefix = '/data/data/com.zion.os/files/usr';
  const TermuxRuntimeService();

  Future<RuntimeCapability> probeExecutable(String id, List<String> candidates) async {
    for (final candidate in candidates) {
      try {
        final stat = await File(candidate).stat();
        if (stat.type == FileSystemEntityType.file) return RuntimeCapability(id: id, status: RuntimeStatus.available, detail: 'REAL executable detected.', path: candidate);
      } catch (_) {}
    }
    return RuntimeCapability(id: id, status: RuntimeStatus.notConfigured, detail: 'No executable is installed in the Zion userland.');
  }

  Future<RuntimeCapability> storageStatus() async {
    final shared = Directory('/storage/emulated/0');
    if (!await shared.exists()) return const RuntimeCapability(id: 'shared-storage', status: RuntimeStatus.unavailable, detail: '/storage/emulated/0 is not present on this device.');
    try { await shared.list(followLinks: false).first; return const RuntimeCapability(id: 'shared-storage', status: RuntimeStatus.available, detail: 'Shared storage is readable by the terminal UID.', path: '/storage/emulated/0'); }
    catch (_) { return const RuntimeCapability(id: 'shared-storage', status: RuntimeStatus.permissionRequired, detail: 'Android denied shared-storage access; grant storage access before setup.', path: '/storage/emulated/0'); }
  }

  Future<RuntimeCapability> setupStorage() async {
    final access = await storageStatus();
    if (access.status != RuntimeStatus.available) return access;
    final storageHome = Directory(home + '/storage');
    try {
      if (await storageHome.exists()) { await for (final entity in storageHome.list(followLinks: false)) { if (entity is Link) await entity.delete(); } }
      else { await storageHome.create(recursive: true); }
      const targets = <String, String>{
        'shared': '/storage/emulated/0',
        'downloads': '/storage/emulated/0/Download',
        'dcim': '/storage/emulated/0/DCIM',
        'pictures': '/storage/emulated/0/Pictures',
        'music': '/storage/emulated/0/Music',
        'movies': '/storage/emulated/0/Movies',
        'documents': '/storage/emulated/0/Documents',
      };
      for (final entry in targets.entries) {
        final link = Link(storageHome.path + '/' + entry.key);
        if (await link.exists()) await link.delete();
        await link.create(entry.value, recursive: false);
      }
      return RuntimeCapability(id: 'termux-setup-storage', status: RuntimeStatus.available, detail: 'REAL storage links created under ~/storage.', path: storageHome.path);
    } on FileSystemException catch (e) {
      return RuntimeCapability(id: 'termux-setup-storage', status: RuntimeStatus.permissionRequired, detail: e.message, path: storageHome.path);
    }
  }

  Future<Map<String, RuntimeCapability>> probeCore() async {
    const executables = <String, List<String>>{
      'sh': <String>[prefix + '/bin/sh'],
      'bash': <String>[prefix + '/bin/bash'], 'zsh': <String>[prefix + '/bin/zsh'], 'fish': <String>[prefix + '/bin/fish'],
      'pkg': <String>[prefix + '/bin/pkg'], 'apt': <String>[prefix + '/bin/apt'], 'dpkg': <String>[prefix + '/bin/dpkg'],
      'proot': <String>[prefix + '/bin/proot'], 'proot-distro': <String>[prefix + '/bin/proot-distro'],
      'ssh': <String>[prefix + '/bin/ssh'], 'scp': <String>[prefix + '/bin/scp'], 'sftp': <String>[prefix + '/bin/sftp'], 'ssh-keygen': <String>[prefix + '/bin/ssh-keygen'],
      'curl': <String>[prefix + '/bin/curl'], 'wget': <String>[prefix + '/bin/wget'], 'ping': <String>[prefix + '/bin/ping'], 'traceroute': <String>[prefix + '/bin/traceroute'],
      'dig': <String>[prefix + '/bin/dig'], 'nslookup': <String>[prefix + '/bin/nslookup'], 'host': <String>[prefix + '/bin/host'], 'whois': <String>[prefix + '/bin/whois'],
      'netstat': <String>[prefix + '/bin/netstat'], 'ss': <String>[prefix + '/bin/ss'], 'ifconfig': <String>[prefix + '/bin/ifconfig'], 'ip': <String>[prefix + '/bin/ip'],
      'nc': <String>[prefix + '/bin/nc'], 'socat': <String>[prefix + '/bin/socat'],
      'termux-battery-status': <String>[prefix + '/bin/termux-battery-status'], 'termux-clipboard-get': <String>[prefix + '/bin/termux-clipboard-get'],
      'termux-clipboard-set': <String>[prefix + '/bin/termux-clipboard-set'], 'termux-notification': <String>[prefix + '/bin/termux-notification'],
      'termux-toast': <String>[prefix + '/bin/termux-toast'], 'termux-vibrate': <String>[prefix + '/bin/termux-vibrate'], 'termux-tts-speak': <String>[prefix + '/bin/termux-tts-speak'],
    };
    final results = <String, RuntimeCapability>{};
    results['shared-storage'] = await storageStatus();
    for (final entry in executables.entries) {
      results[entry.key] = await probeExecutable(entry.key, entry.value);
    }
    return results;
  }

  Future<String> describe() async {
    final results = await probeCore();
    final buffer = StringBuffer('ZION TERMUX RUNTIME\n');
    buffer.writeln('HOME=' + home); buffer.writeln('PREFIX=' + prefix);
    for (final result in results.values) buffer.writeln('[' + result.status.name.toUpperCase() + '] ' + result.id + ': ' + result.detail);
    return buffer.toString().trimRight();
  }
}