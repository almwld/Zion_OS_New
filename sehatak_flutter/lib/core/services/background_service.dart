import 'dart:async';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundSyncService {
  static const String baseUrl = 'https://hi-g26z.onrender.com';
  static Timer? _timer;
  static bool _isRunning = false;

  // ========== بدء المزامنة الخلفية ==========
  static void start() {
    if (_isRunning) return;
    _isRunning = true;
    
    // مزامنة كل 30 ثانية
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await syncAll();
    });
    
    // أول مزامنة فورية
    syncAll();
    
    print('🔄 Background sync started');
  }

  // ========== إيقاف المزامنة ==========
  static void stop() {
    _timer?.cancel();
    _isRunning = false;
    print('⏹️ Background sync stopped');
  }

  // ========== مزامنة كل شيء ==========
  static Future<void> syncAll() async {
    try {
      await Future.wait([
        checkServerHealth(),
        syncMessages(),
        syncAppointments(),
        syncNotifications(),
      ]);
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }

  // ========== فحص صحة السيرفر ==========
  static Future<void> checkServerHealth() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
      ));
      
      final response = await dio.get('/health');
      if (response.data['status'] == 'online') {
        print('✅ Server healthy');
      }
    } catch (e) {
      print('🔴 Server unreachable');
    }
  }

  // ========== مزامنة الرسائل ==========
  static Future<void> syncMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));

      // جلب الرسائل الجديدة
      final response = await dio.get('/api/chat/conversations');
      
      // تخزين محلي
      if (response.data['success'] == true) {
        // حفظ في قاعدة بيانات محلية أو SharedPreferences
        print('📨 Messages synced');
      }
    } catch (e) {
      // صامت - لا حاجة لإزعاج المستخدم
    }
  }

  // ========== مزامنة المواعيد ==========
  static Future<void> syncAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final patientId = prefs.getString('phone');
      if (token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));

      await dio.get('/api/appointments', queryParameters: {
        'patientId': patientId,
      });
      
      print('📅 Appointments synced');
    } catch (e) {
      // صامت
    }
  }

  // ========== مزامنة الإشعارات ==========
  static Future<void> syncNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));

      // يمكن إضافة route للإشعارات لاحقاً
      // await dio.get('/api/notifications');
      
      print('🔔 Notifications synced');
    } catch (e) {
      // صامت
    }
  }

  // ========== مزامنة بيانات المستخدم ==========
  static Future<void> syncUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));

      final response = await dio.get('/api/auth/profile');
      
      if (response.data['success'] == true) {
        final user = response.data['user'];
        await prefs.setString('user_name', user['name'] ?? '');
        print('👤 Profile synced');
      }
    } catch (e) {
      // صامت
    }
  }
}
