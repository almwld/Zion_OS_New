import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});
}

class ApiService {
  static const String baseUrl = 'https://hi-g26z.onrender.com';
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  static String? _accessToken;
  static String? _refreshToken;

  // ========== تهيئة ==========
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    
    if (_accessToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
    }
  }

  // ========== Auth ==========
  static Future<ApiResponse> login(String phone, String otp) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'phone': phone,
        'otp': otp,
      });
      
      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        _accessToken = data['token'] as String?;
        
        // حفظ التوكن
        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('accessToken', _accessToken!);
          _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        
        return ApiResponse(success: true, data: data);
      }
      
      return ApiResponse(success: false, error: data['error'] as String?);
    } catch (e) {
      return ApiResponse(success: false, error: 'خطأ في الاتصال');
    }
  }

  static Future<ApiResponse> register({
    required String fullName,
    required String phone,
    String? email,
  }) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'name': fullName,
        'phone': phone,
        'email': email ?? '',
      });
      
      final data = response.data as Map<String, dynamic>;
      return ApiResponse(success: data['success'] == true, data: data);
    } catch (e) {
      return ApiResponse(success: false, error: 'خطأ في الاتصال');
    }
  }

  // ========== OTP ==========
  static Future<ApiResponse> sendOTP(String phone) async {
    try {
      final response = await _dio.post('/api/otp/send', data: {'phone': phone});
      final data = response.data as Map<String, dynamic>;
      return ApiResponse(success: data['success'] == true, data: data);
    } catch (e) {
      return ApiResponse(success: false, error: 'خطأ في الاتصال');
    }
  }

  // ========== Profile ==========
  static Future<ApiResponse> getProfile() async {
    try {
      final response = await _dio.get('/api/auth/profile');
      final data = response.data as Map<String, dynamic>;
      return ApiResponse(success: data['success'] == true, data: data);
    } catch (e) {
      return ApiResponse(success: false, error: 'خطأ في الاتصال');
    }
  }

  // ========== Appointments ==========
  static Future<ApiResponse> getAppointments(String patientId) async {
    try {
      final response = await _dio.get('/api/appointments', queryParameters: {
        'patientId': patientId,
      });
      final data = response.data as Map<String, dynamic>;
      return ApiResponse(success: data['success'] == true, data: data);
    } catch (e) {
      return ApiResponse(success: false, error: 'خطأ في الاتصال');
    }
  }

  // ========== Health Check ==========
  static Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data['status'] == 'online';
    } catch (e) {
      return false;
    }
  }

  // ========== Token Management ==========
  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static bool get isLoggedIn => _accessToken != null;
}
