import 'dart:async';
import 'dart:io';

class KaliChrootService {
  static const String _chrootPath = '/data/local/kali';
  static const String _shell = '/bin/bash';

  /// تنفيذ أمر داخل بيئة كالي
  static Future<Map<String, dynamic>> execute(String command, {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final escapedCommand = command.replaceAll("'", "'\\''");
      final fullCommand = "su -c 'chroot $_chrootPath $_shell -c \"$escapedCommand\"'";

      final process = await Process.start('/bin/sh', ['-c', fullCommand], runInShell: true);

      final stdout = StringBuffer();
      final stderr = StringBuffer();

      process.stdout.transform(const SystemEncoding().decoder).listen((data) => stdout.write(data));
      process.stderr.transform(const SystemEncoding().decoder).listen((data) => stderr.write(data));

      final exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      });

      return {
        'success': exitCode == 0,
        'stdout': stdout.toString(),
        'stderr': stderr.toString(),
        'exitCode': exitCode,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// فحص إذا كانت بيئة كالي موجودة
  static Future<bool> isKaliAvailable() async {
    try {
      final result = await execute('ls /bin/bash');
      return result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// تنفيذ أمر nmap
  static Future<String> runNmap(String target, {String args = '-sV'}) async {
    final result = await execute('nmap $args $target');
    return result['stdout'] ?? result['stderr'] ?? 'Error running nmap';
  }

  /// تنفيذ أمر sqlmap
  static Future<String> runSqlmap(String url) async {
    final result = await execute('sqlmap -u "$url" --batch --dbs');
    return result['stdout'] ?? result['stderr'] ?? 'Error running sqlmap';
  }

  /// تنفيذ أمر msfconsole
  static Future<String> runMetasploit(String commands) async {
    final result = await execute('msfconsole -q -x "$commands"');
    return result['stdout'] ?? result['stderr'] ?? 'Error running msfconsole';
  }

  /// تنفيذ أمر hydra
  static Future<String> runHydra(String target, String service, String wordlist, String username) async {
    final result = await execute('hydra -l $username -P $wordlist $service://$target');
    return result['stdout'] ?? result['stderr'] ?? 'Error running hydra';
  }

  /// تنفيذ أمر aircrack-ng
  static Future<String> runAircrack(String capFile, String wordlist) async {
    final result = await execute('aircrack-ng $capFile -w $wordlist');
    return result['stdout'] ?? result['stderr'] ?? 'Error running aircrack-ng';
  }
}
