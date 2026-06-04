import 'package:flutter/material.dart';

class AppColors {
  // ========== الأخضر الطبي (Primary) ==========
  static const Color primary = Color(0xFF00796B);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFF26A69A);
  
  // ========== الأزرق العصري (Secondary) ==========
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryDark = Color(0xFF1565C0);
  static const Color secondaryLight = Color(0xFF64B5F6);
  
  // ========== ألوان مساعدة ==========
  static const Color accent = Color(0xFF00BCD4);
  static const Color teal = Color(0xFF009688);
  
  // ========== ألوان الحالة ==========
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // ========== ألوان محايدة ==========
  static const Color grey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF616161);
  static const Color lightGrey = Color(0xFFE0E0E0);
  
  // ========== خلفيات ==========
  static const Color scaffoldLight = Color(0xFFF8FAFB);
  static const Color scaffoldDark = Color(0xFF0B1121);
  static const Color cardDark = Color(0xFF1A2540);
  
  // ========== وضع ليلي ==========
  static const Color darkPrimary = Color(0xFF38BDF8);
  static const Color darkSurface = Color(0xFF1A2540);
  static const Color darkBackground = Color(0xFF0B1121);
  
  // ========== تدرجات ==========
  static const List<Color> primaryGradient = [primary, primaryDark];
  static const List<Color> secondaryGradient = [secondary, secondaryDark];
  static const List<Color> medicalGradient = [primary, secondaryLight];
  static const List<Color> successGradient = [success, Color(0xFF81C784)];
  
  // ========== محافظ يمنية ==========
  static const Color flosok = Color(0xFF2196F3);
  static const Color cash = Color(0xFF4CAF50);
  static const Color jawali = Color(0xFFFF9800);
  static const Color jeeb = Color(0xFF9C27B0);
  static const Color easy = Color(0xFF00BCD4);
}

// ألوان إضافية للملفات المحتاجة
static const Color amber = Color(0xFFFFC107);
static const Color outlineVariant = Color(0xFFCAC4D0);
static const Color surfaceContainerLow = Color(0xFFF7F2FA);
