import 'dart:async';
import 'dart:io';
import 'dart:convert';

class WifiScanner {
  /// المسح الكامل للشبكات اللاسلكية (بدون صلاحيات روت)
  /// يستخدم أوامر نظام Android الأصلية
  static Future<List<Map<String, dynamic>>> fullScan() async {
    final networks = <Map<String, dynamic>>[];
    
    try {
      // الطريقة 1: استخدام الأمر الرسمي لـ Android (الأفضل)
      final result = await Process.run(
        'cmd',
        ['wifi', 'scan'],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        // الحصول على نتائج المسح
        final scanResult = await Process.run(
          'cmd',
          ['wifi', 'scan-results'],
          runInShell: true,
        );
        
        if (scanResult.exitCode == 0) {
          final output = scanResult.stdout.toString();
          networks.addAll(_parseAndroidWifiOutput(output));
        }
      }
    } catch (_) {
      // الطريقة 2: محاولة استخدام dumpsys (يتطلب أحيانًا صلاحيات)
      try {
        final result = await Process.run(
          'dumpsys',
          ['wifi'],
          runInShell: true,
        );
        if (result.exitCode == 0) {
          networks.addAll(_parseDumpsysOutput(result.stdout.toString()));
        }
      } catch (_) {
        // الطريقة 3: محاولة استخدام /proc/net (ملفات النظام)
        try {
          final result = await Process.run(
            'cat',
            ['/proc/net/wireless'],
            runInShell: true,
          );
          if (result.exitCode == 0) {
            networks.addAll(_parseProcWireless(result.stdout.toString()));
          }
        } catch (_) {
          // الطريقة 4: استخدام ip link show (أقل تفصيلاً)
          try {
            final result = await Process.run(
              'ip',
              ['link', 'show'],
              runInShell: true,
            );
            if (result.exitCode == 0) {
              networks.addAll(_parseIpLink(result.stdout.toString()));
            }
          } catch (_) {
            // البيانات الاحتياطية (للتطوير فقط)
            networks.addAll(_generateFallbackData());
          }
        }
      }
    }
    
    // إضافة معلومات إضافية لكل شبكة
    return _enrichNetworkData(networks);
  }

  /// تحليل مخرجات أمر Android wifi scan-results
  static List<Map<String, dynamic>> _parseAndroidWifiOutput(String output) {
    final networks = <Map<String, dynamic>>[];
    final lines = output.split('\n');
    
    bool started = false;
    for (final line in lines) {
      if (line.contains('BSSID') || line.contains('bssid')) {
        started = true;
        continue;
      }
      if (!started || line.trim().isEmpty) continue;
      
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        try {
          networks.add({
            'bssid': parts[0],
            'ssid': parts.length > 4 ? parts.sublist(3).join(' ') : parts[3],
            'frequency': parts.length > 1 ? parts[1] : 'Unknown',
            'signal': parts.length > 2 ? int.tryParse(parts[2].replaceAll('-', '')) ?? 0 : 0,
            'capabilities': parts.length > 3 ? parts[2] : '',
            'channel': _frequencyToChannel(parts.length > 1 ? parts[1] : ''),
          });
        } catch (_) {}
      }
    }
    
    return networks;
  }

  /// تحليل مخرجات dumpsys wifi
  static List<Map<String, dynamic>> _parseDumpsysOutput(String output) {
    final networks = <Map<String, dynamic>>[];
    final ssidPattern = RegExp(r'SSID:\s*"([^"]*)"', caseSensitive: false);
    final bssidPattern = RegExp(r'BSSID:\s*([0-9a-fA-F:]{17})', caseSensitive: false);
    final signalPattern = RegExp(r'signal:\s*(-?\d+)', caseSensitive: false);
    final freqPattern = RegExp(r'frequency:\s*(\d+)', caseSensitive: false);
    final securityPattern = RegExp(r'capabilities:\s*\[([^\]]*)\]', caseSensitive: false);
    
    // تقسيم المخرجات إلى كتل لكل شبكة
    final blocks = output.split('SSID:');
    for (final block in blocks.skip(1)) {
      final ssidMatch = RegExp(r'"([^"]*)"').firstMatch(block);
      final bssidMatch = bssidPattern.firstMatch('BSSID:${block.split("BSSID:").length > 1 ? block.split("BSSID:")[1] : ""}');
      final signalMatch = signalPattern.firstMatch(block);
      final freqMatch = freqPattern.firstMatch(block);
      final securityMatch = securityPattern.firstMatch(block);
      
      if (ssidMatch != null) {
        networks.add({
          'ssid': ssidMatch.group(1),
          'bssid': bssidMatch?.group(1) ?? 'Unknown',
          'signal': signalMatch != null ? int.tryParse(signalMatch.group(1)!) ?? 0 : 0,
          'frequency': freqMatch?.group(1) ?? 'Unknown',
          'security': securityMatch?.group(1) ?? 'Unknown',
          'channel': freqMatch != null ? _frequencyToChannel(freqMatch.group(1)!) : 'Unknown',
        });
      }
    }
    
    return networks;
  }

  /// تحليل مخرجات /proc/net/wireless
  static List<Map<String, dynamic>> _parseProcWireless(String output) {
    final networks = <Map<String, dynamic>>[];
    final lines = output.split('\n');
    
    for (final line in lines.skip(2)) { // تخطي العناوين
      if (line.trim().isEmpty) continue;
      
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        networks.add({
          'interface': parts[0].replaceAll(':', ''),
          'status': parts[1],
          'link_quality': parts[2],
          'signal_level': int.tryParse(parts[3]) ?? 0,
          'noise_level': int.tryParse(parts[4]) ?? 0,
        });
      }
    }
    
    return networks;
  }

  /// تحليل مخرجات ip link show
  static List<Map<String, dynamic>> _parseIpLink(String output) {
    final networks = <Map<String, dynamic>>[];
    final lines = output.split('\n');
    
    for (final line in lines) {
      if (line.contains('wlan') || line.contains('wifi')) {
        final parts = line.trim().split(':');
        if (parts.length >= 2) {
          networks.add({
            'interface': parts[1].trim(),
            'status': line.contains('UP') ? 'UP' : 'DOWN',
            'info': parts.length > 2 ? parts[2].trim() : '',
          });
        }
      }
    }
    
    return networks;
  }

  /// إثراء بيانات الشبكة بمعلومات إضافية
  static List<Map<String, dynamic>> _enrichNetworkData(List<Map<String, dynamic>> networks) {
    for (final network in networks) {
      // إضافة تحليل الأمان
      final capabilities = network['security']?.toString() ?? network['capabilities']?.toString() ?? '';
      network['encryption'] = _detectEncryption(capabilities);
      network['is_open'] = capabilities.contains('ESS') && !capabilities.contains('WPA');
      network['wps_enabled'] = capabilities.contains('WPS');
      
      // إضافة قوة الإشارة بالنسبة المئوية
      final signal = network['signal'] ?? 0;
      if (signal is int && signal < 0) {
        network['signal_percent'] = ((100 + (signal > -100 ? signal : -100))).clamp(0, 100);
      } else if (signal is int && signal > 0) {
        network['signal_percent'] = signal.clamp(0, 100);
      }
      
      // إضافة تصنيف المخاطر
      if (network['is_open'] == true) {
        network['risk'] = 'CRITICAL';
        network['risk_color'] = 'Red';
      } else if (capabilities.contains('WEP')) {
        network['risk'] = 'HIGH';
        network['risk_color'] = 'Orange';
      } else if (capabilities.contains('WPA') && !capabilities.contains('WPA2') && !capabilities.contains('WPA3')) {
        network['risk'] = 'Medium';
        network['risk_color'] = 'Yellow';
      } else {
        network['risk'] = 'Low';
        network['risk_color'] = 'Green';
      }
      
      // إضافة نصائح أمنية
      network['recommendation'] = _getSecurityRecommendation(network);
    }
    
    return networks;
  }

  /// فحص شبكة محددة بتفصيل
  static Future<Map<String, dynamic>> detailedScan(String bssid) async {
    try {
      final result = await Process.run('cmd', ['wifi', 'status'], runInShell: true);
      if (result.exitCode == 0) {
        return {'status': 'connected', 'info': result.stdout.toString()};
      }
    } catch (_) {}
    
    return {'status': 'unavailable'};
  }

  /// الحصول على معلومات الجهاز الحالي المتصل
  static Future<Map<String, dynamic>> getCurrentConnection() async {
    try {
      final result = await Process.run('cmd', ['wifi', 'status'], runInShell: true);
      if (result.exitCode == 0) {
        return _parseCurrentConnection(result.stdout.toString());
      }
    } catch (_) {}
    
    return {'connected': false};
  }

  static Map<String, dynamic> _parseCurrentConnection(String output) {
    final info = <String, dynamic>{'connected': false};
    
    final ssidMatch = RegExp(r'SSID: "([^"]*)"', caseSensitive: false).firstMatch(output);
    final bssidMatch = RegExp(r'BSSID: ([0-9a-fA-F:]{17})', caseSensitive: false).firstMatch(output);
    final ipMatch = RegExp(r'IP address: ([0-9.]+)', caseSensitive: false).firstMatch(output);
    final speedMatch = RegExp(r'link speed: (\d+)', caseSensitive: false).firstMatch(output);
    
    if (ssidMatch != null) {
      info['connected'] = true;
      info['ssid'] = ssidMatch.group(1);
      info['bssid'] = bssidMatch?.group(1) ?? 'Unknown';
      info['ip'] = ipMatch?.group(1) ?? 'Unknown';
      info['speed'] = speedMatch != null ? int.parse(speedMatch.group(1)!) : 0;
    }
    
    return info;
  }

  static String _detectEncryption(String capabilities) {
    final lower = capabilities.toLowerCase();
    if (lower.contains('wpa3')) return 'WPA3';
    if (lower.contains('wpa2')) return 'WPA2';
    if (lower.contains('wpa')) return 'WPA';
    if (lower.contains('wep')) return 'WEP (INSECURE)';
    if (lower.contains('ess') && !lower.contains('wpa')) return 'Open (No Encryption!)';
    return 'Unknown';
  }

  static String _frequencyToChannel(String freqStr) {
    final freq = int.tryParse(freqStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (freq >= 2412 && freq <= 2484) {
      return ((freq - 2407) / 5).round().toString();
    } else if (freq >= 5170 && freq <= 5825) {
      return ((freq - 5000) / 5).round().toString();
    }
    return 'Unknown';
  }

  static String _getSecurityRecommendation(Map<String, dynamic> network) {
    if (network['is_open'] == true) {
      return 'Enable WPA2/WPA3 encryption immediately! Anyone can connect.';
    }
    final encryption = network['encryption']?.toString() ?? '';
    if (encryption.contains('WEP')) {
      return 'WEP is completely broken. Upgrade to WPA2/WPA3 now.';
    }
    if (encryption.contains('WPA') && !encryption.contains('WPA2') && !encryption.contains('WPA3')) {
      return 'Upgrade to WPA2 or WPA3 for better security.';
    }
    if (network['wps_enabled'] == true) {
      return 'Disable WPS - it is vulnerable to brute force attacks.';
    }
    return 'Security looks good. Keep router firmware updated.';
  }

  /// بيانات احتياطية للتطوير (في حال فشل كل الطرق)
  static List<Map<String, dynamic>> _generateFallbackData() {
    return [
      {'ssid': 'AndroidWifi (Simulated)', 'bssid': '00:11:22:33:44:55', 'signal': -45, 'encryption': 'WPA2', 'is_open': false},
    ];
  }
}
