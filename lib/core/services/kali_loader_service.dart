import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'kali_chroot_service.dart';

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

  // ============ إدارة proot المدمج ============
  
  /// استخراج proot من assets إلى مجلد التطبيق
  static Future<bool> extractEmbeddedProot() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final prootDir = Directory('${appDir.path}/bin');
      if (!await prootDir.exists()) {
        await prootDir.create(recursive: true);
      }
      
      final prootPath = '${prootDir.path}/proot';
      final prootFile = File(prootPath);
      
      // إذا كان الملف موجودًا بالفعل، تحقق من أنه يعمل
      if (await prootFile.exists()) {
        final testResult = await _testProot(prootPath);
        if (testResult) {
          _prootPath = prootPath;
          print('✅ Existing proot found and working: $prootPath');
          return true;
        }
        // إذا كان تالفًا، احذفه وأعد استخراجه
        await prootFile.delete();
      }
      
      // استخراج proot من assets
      print('📦 Extracting proot from assets...');
      final byteData = await rootBundle.load('assets/bin/proot');
      await prootFile.writeAsBytes(byteData.buffer.asUint8List());
      
      // منح صلاحية التنفيذ
      await Process.run('chmod', ['755', prootPath]);
      
      // التحقق من أنه يعمل
      final testResult = await _testProot(prootPath);
      if (testResult) {
        _prootPath = prootPath;
        print('✅ Embedded proot extracted successfully: $prootPath');
        return true;
      } else {
        print('❌ Extracted proot failed test');
        return false;
      }
    } catch (e) {
      print('❌ Failed to extract proot: $e');
      return false;
    }
  }
  
  /// اختبار proot ليتأكد من أنه يعمل
  static Future<bool> _testProot(String prootPath) async {
    try {
      final result = await Process.run(prootPath, ['--version'], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
  
  /// البحث عن proot في المسارات المتاحة
  static Future<String?> findProot() async {
    // 1. استخدام المدمج أولاً
    if (_prootPath != null && await File(_prootPath!).exists()) {
      return _prootPath;
    }
    
    // 2. محاولة استخراج المدمج
    final extracted = await extractEmbeddedProot();
    if (extracted) return _prootPath;
    
    // 3. البحث في Termux
    final termuxPaths = [
      '/data/data/com.termux/files/usr/bin/proot',
      '/data/data/com.termux/files/usr/bin/proot',
    ];
    for (final path in termuxPaths) {
      if (await File(path).exists()) {
        final test = await _testProot(path);
        if (test) return path;
      }
    }
    
    // 4. البحث في النظام
    final systemPaths = ['/usr/bin/proot', '/usr/local/bin/proot'];
    for (final path in systemPaths) {
      if (await File(path).exists()) {
        final test = await _testProot(path);
        if (test) return path;
      }
    }
    
    return null;
  }

  // ============ فحص صلاحيات الجذر ============
  
  static Future<bool> hasRootAccess() async {
    if (_rootChecked) return _hasRootCache;
    _rootChecked = true;
    
    try {
      final whichSu = await Process.run('which', ['su'], runInShell: true);
      if (whichSu.exitCode != 0) {
        _hasRootCache = false;
        return false;
      }
      
      final result = await Process.run('su', ['-c', 'id -u'], runInShell: true);
      final uid = result.stdout.toString().trim();
      _hasRootCache = result.exitCode == 0 && uid == '0';
      return _hasRootCache;
    } catch (_) {
      _hasRootCache = false;
      return false;
    }
  }
  
  static Future<bool> hasChroot() async {
    return await hasRootAccess() && await Directory(_installPath).exists();
  }

  // ============ التثبيت ============
  
  static Future<String> install() async {
    if (await _isInstalled()) {
      return '✅ Kali Linux مثبت مسبقًا وجاهز.';
    }
    
    String? bestSource;
    String? sourceType;
    for (final source in _sources) {
      if (await File(source['path']!).exists()) {
        bestSource = source['path'];
        sourceType = source['type'];
        break;
      }
    }

    if (bestSource == null) {
      return '❌ لم يتم العثور على أي توزيعة في $_zionFolder\n\nالرجاء وضع أحد الملفات التالية:\n- bootstrap-aarch64.zip\n- kali-bootstrap.tar.gz';
    }

    final success = await _extract(bestSource, sourceType!);
    if (!success) return '❌ فشل فك الضغط. تأكد من وجود مساحة كافية.';

    await _setupEnvironment();
    return '✅ تم تثبيت Kali Linux بنجاح (600+ أداة جاهزة)';
  }

  // ============ التنفيذ ============
  
  static Future<Map<String, dynamic>> execute(String command) async {
    // التحقق من التثبيت
    if (!await _isInstalled()) {
      return {'success': false, 'error': 'Kali غير مثبت. استخدم أمر kali_install للتثبيت.'};
    }
    
    // محاولة استخدام chroot إذا كان متاحًا (أسرع)
    if (await hasChroot()) {
      print('🚀 Using CHROOT mode (root + faster)');
      return await KaliChrootService.execute(command);
    }
    
    // البحث عن proot
    final prootPath = await findProot();
    if (prootPath == null) {
      return {
        'success': false, 
        'error': 'proot غير متوفر.\n\nلحل المشكلة:\n1. ثبّت Termux من F-Droid\n2. نفّذ: pkg install proot\n3. أو استخدم وضع chroot (يتطلب روت)'
      };
    }
    
    print('🐢 Using PROOT mode (no root required) - $prootPath');
    return await _executeProot(command, prootPath);
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
        'stdout': result.stdout.toString().trim(),
        'stderr': result.stderr.toString().trim(),
        'exitCode': result.exitCode,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ دوال مساعدة ============
  
  static Future<bool> _isInstalled() async {
    return await Directory(_installPath).exists();
  }
  
  static Future<bool> _extract(String archivePath, String type) async {
    try {
      await Process.run('mkdir', ['-p', _installPath], runInShell: true);
      ProcessResult result;
      if (type == 'zip') {
        result = await Process.run('unzip', ['-o', archivePath, '-d', _installPath], runInShell: true);
      } else {
        result = await Process.run('tar', ['-xzf', archivePath, '-C', _installPath], runInShell: true);
      }
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
  
  static Future<void> _setupEnvironment() async {
    final dirs = ['$_installPath/dev', '$_installPath/proc', '$_installPath/sys', '$_installPath/tmp'];
    for (final dir in dirs) {
      await Process.run('mkdir', ['-p', dir], runInShell: true);
    }
  }
  
  static Future<Map<String, dynamic>> getStatus() async {
    final installed = await _isInstalled();
    final hasRoot = await hasRootAccess();
    final useChroot = await hasChroot();
    final prootPath = await findProot();
    
    return {
      'installed': installed,
      'path': _installPath,
      'has_root': hasRoot,
      'use_chroot': useChroot,
      'mode': useChroot ? 'CHROOT (fastest)' : (prootPath != null ? 'PROOT (no root)' : 'MISSING'),
      'proot_available': prootPath != null,
      'proot_path': prootPath ?? '',
    };
  }
  
  static Future<bool> isAvailable() async { return await _isInstalled(); }
  static Future<int> getToolCount() async {
    final result = await execute('ls /usr/bin /usr/sbin /usr/local/bin 2>/dev/null | wc -l');
    return int.tryParse(result['stdout']?.trim() ?? '0') ?? 0;
  }

  // ============ أوامر جاهزة ============
  
  static Future<String> nmap(String target, {String args = '-sV -O'}) async {
    final result = await execute('nmap $args $target');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
  
  static Future<String> msfconsole(String commands) async {
    final result = await execute('msfconsole -q -x "$commands"');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
  
  static Future<String> sqlmap(String url) async {
    final result = await execute('sqlmap -u "$url" --batch --dbs');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
  
  static Future<String> hydra(String target, String service, String user, String wordlist) async {
    final result = await execute('hydra -l $user -P $wordlist $service://$target');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
  
  static Future<String> aircrack(String capFile, String wordlist) async {
    final result = await execute('aircrack-ng $capFile -w $wordlist');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
  
  static Future<String> john(String hashFile, {String wordlist = '/usr/share/wordlists/rockyou.txt'}) async {
    final result = await execute('john $hashFile --wordlist=$wordlist');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
  
  static Future<String> nikto(String url) async {
    final result = await execute('nikto -h $url');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
  
  static Future<String> dirb(String url) async {
    final result = await execute('dirb $url');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
  
  static Future<String> wpscan(String url) async {
    final result = await execute('wpscan --url $url --enumerate');
    return result['stdout'] ?? result['stderr'] ?? 'Error';
  }
}

  static Future<bool> isAvailable() async {
    return await _isInstalled();
  }
