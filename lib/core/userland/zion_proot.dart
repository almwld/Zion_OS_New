import 'dart:io';

enum ZionDistro { ubuntu, debian, kali, alpine }
enum ProotStatus { available, notConfigured, unavailable }

class ProotRuntimeInfo {
  const ProotRuntimeInfo({
    required this.status,
    required this.executable,
    required this.reason,
  });

  final ProotStatus status;
  final String? executable;
  final String reason;
}

class ZionProot {
  static const prefix = '/data/data/com.zion.os/files/usr';
  static const home = '/data/data/com.zion.os/files/home';
  static const distroRoot = home + '/.zion/dists';

  const ZionProot();

  Future<ProotRuntimeInfo> inspect() async {
    final executable = prefix + '/bin/proot';
    if (!await _isExecutable(executable)) {
      return const ProotRuntimeInfo(
        status: ProotStatus.notConfigured,
        executable: null,
        reason: 'PRoot is not installed as an executable inside Zion Userland.',
      );
    }

    try {
      final result = await Process.run(
        executable,
        const <String>['--version'],
        runInShell: false,
        environment: <String, String>{
          ...Platform.environment,
          'HOME': home,
          'PREFIX': prefix,
          'PATH': prefix + '/bin:' + prefix + '/sbin:/system/bin:/system/xbin',
          'LD_LIBRARY_PATH': prefix + '/lib:' + prefix + '/lib64',
        },
      ).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) {
        return ProotRuntimeInfo(
          status: ProotStatus.unavailable,
          executable: executable,
          reason: 'PRoot exists but failed --version with exit code ${result.exitCode}.',
        );
      }
      return ProotRuntimeInfo(
        status: ProotStatus.available,
        executable: executable,
        reason: 'PRoot passed the executable and --version checks.',
      );
    } catch (error) {
      return ProotRuntimeInfo(
        status: ProotStatus.unavailable,
        executable: executable,
        reason: 'PRoot could not be executed: $error',
      );
    }
  }

  Future<bool> rootfsExists(ZionDistro distro) =>
      File(rootfsPath(distro) + '/bin/sh').exists();

  String rootfsPath(ZionDistro distro) =>
      distroRoot + '/' + distro.name + '/rootfs';

  String? validateDistro(String name) {
    final normalized = name.trim().toLowerCase();
    for (final distro in ZionDistro.values) {
      if (distro.name == normalized) return distro.name;
    }
    return null;
  }

  Future<Process> start(
    ZionDistro distro, {
    List<String> command = const <String>['/bin/sh', '-l'],
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final info = await inspect();
    if (info.status != ProotStatus.available || info.executable == null) {
      throw StateError(info.reason);
    }

    final rootfs = rootfsPath(distro);
    if (!await File(rootfs + '/bin/sh').exists()) {
      throw StateError('Rootfs for ${distro.name} is missing /bin/sh.');
    }
    if (command.isEmpty || command.any(_unsafeArgument)) {
      throw ArgumentError('Invalid PRoot command arguments.');
    }

    final cwd = workingDirectory?.trim().isNotEmpty == true
        ? workingDirectory!.trim()
        : '/root';
    if (!_safeGuestPath(cwd)) {
      throw ArgumentError('Invalid Linux working directory.');
    }

    final args = <String>[
      '-0',
      '-r',
      rootfs,
      '--link2symlink',
      '-b',
      '/dev',
      '-b',
      '/proc',
      '-b',
      '/sys',
      '-b',
      '/storage/emulated/0',
      '-b',
      home + ':/root',
      '-w',
      cwd,
      ...command,
    ];
    final processEnvironment = <String, String>{
      ...Platform.environment,
      'HOME': '/root',
      'PATH': '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      'TERM': Platform.environment['TERM'] ?? 'xterm-256color',
      'LANG': Platform.environment['LANG'] ?? 'C.UTF-8',
      'LC_ALL': Platform.environment['LC_ALL'] ?? 'C.UTF-8',
      'TMPDIR': '/tmp',
      'SHELL': '/bin/bash',
    };
    if (environment != null) processEnvironment.addAll(environment);

    return Process.start(
      info.executable!,
      args,
      environment: processEnvironment,
      runInShell: false,
    );
  }

  bool _unsafeArgument(String value) =>
      value.contains('\u0000') || value.contains('\n') || value.contains('\r');

  bool _safeGuestPath(String value) =>
      value.startsWith('/') &&
      !value.contains('\u0000') &&
      !value.contains('\n') &&
      !value.contains('\r') &&
      !value.split('/').contains('..');

  Future<bool> _isExecutable(String path) async {
    try {
      final stat = await File(path).stat();
      return stat.type == FileSystemEntityType.file && (stat.mode & 0x49) != 0;
    } catch (_) {
      return false;
    }
  }
}
