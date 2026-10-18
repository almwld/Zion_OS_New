import 'dart:async';
import 'dart:io';


/// Copies a user-selected capture into the app's existing Kali rootfs and
/// runs a read-only PCAP analysis. No injection or password cracking is run.
class KaliPcapAnalyzer {
  static const String _proot =
      '/data/data/com.zion.os/files/usr/bin/proot';
  static const String _rootfs =
      '/data/data/com.zion.os/files/home/.zion/dists/kali/rootfs';
  static const String _appHome = '/data/data/com.zion.os/files/home';

  static bool _validName(String name) =>
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,95}\.pcap$', caseSensitive: false)
          .hasMatch(name) &&
      !name.contains('..');

  static Future<String?> copyPcapToKali(String pcapName) async {
    if (!_validName(pcapName)) {
      throw ArgumentError.value(pcapName, 'pcapName', 'Expected a safe .pcap filename.');
    }
    final src = File('/storage/emulated/0/Download/UsbWifiMonitor/$pcapName');
    if (!await src.exists()) return null;
    final rootfs = Directory(_rootfs);
    if (!await rootfs.exists()) {
      throw FileSystemException('Kali rootfs was not found', _rootfs);
    }
    // The existing PRoot launch binds app HOME onto /root, so place captures
    // in HOME/captures rather than the shadowed rootfs/root directory.
    final dstDir = Directory('$_appHome/captures');
    await dstDir.create(recursive: true);
    final dst = '${dstDir.path}/$pcapName';
    await src.copy(dst);
    return dst;
  }

  /// Runs aircrack-ng in display/analysis mode only (no -w dictionary and no
  /// attack options). The capture path is constrained to /root/captures.
  static Future<String> analyzeInKali(String pcapName) async {
    if (!_validName(pcapName)) {
      throw ArgumentError.value(pcapName, 'pcapName', 'Expected a safe .pcap filename.');
    }
    final copied = await copyPcapToKali(pcapName);
    if (copied == null) {
      throw FileSystemException('PCAP file was not found in Download/UsbWifiMonitor', pcapName);
    }
    if (!await File(_proot).exists()) {
      throw FileSystemException('PRoot executable was not found', _proot);
    }
    if (!await File('$_rootfs/bin/sh').exists()) {
      throw FileSystemException('Kali rootfs is missing /bin/sh', _rootfs);
    }

    final process = await Process.start(_proot, [
      '--link2symlink', '-0', '-r', _rootfs,
      '-b', '/dev', '-b', '/proc', '-b', '/sys',
      '-b', '/storage/emulated/0',
      '-b', '/data/data/com.zion.os/files/home:/root',
      '-w', '/root',
      '/usr/bin/aircrack-ng',
      '/root/captures/$pcapName',
    ], runInShell: false);

    final stdoutFuture = process.stdout.transform(const SystemEncoding().decoder).join();
    final stderrFuture = process.stderr.transform(const SystemEncoding().decoder).join();
    final exitCode = await process.exitCode.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        throw TimeoutException('aircrack-ng analysis timed out after 45 seconds.');
      },
    );
    final stdout = await stdoutFuture;
    final stderr = await stderrFuture;
    return 'PCAP copied to: $copied\nExit code: $exitCode\n'
        '${stdout.trim()}'
        '${stderr.trim().isEmpty ? '' : '\nSTDERR:\n${stderr.trim()}'}';
  }

  static String buildAircrackCommand(String pcapName) {
    if (!_validName(pcapName)) {
      throw ArgumentError.value(pcapName, 'pcapName', 'Expected a safe .pcap filename.');
    }
    return 'aircrack-ng /root/captures/$pcapName';
  }
}
