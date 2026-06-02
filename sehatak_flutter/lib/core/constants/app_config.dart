class AppConfig {
  // App Info
  static const String appName = 'منصة صحتك';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String packageName = 'com.sehatak.app';

  // API
  static const int apiTimeout = 30000; // milliseconds
  static const int apiMaxRetries = 3;
  static const String apiContentType = 'application/json';
  static const String apiAccept = 'application/json';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const int cacheMaxAge = 7; // days
  static const int cacheMaxEntries = 1000;

  // Location
  static const double defaultLatitude = 15.3694;
  static const double defaultLongitude = 44.1910;
  static const double defaultRadius = 10.0; // km

  // Notifications
  static const String notificationChannelId = 'sehatak_notifications';
  static const String notificationChannelName = 'منصة صحتك';
  static const String notificationChannelDesc = 'إشعارات صحتك الطبية';

  // Biometric
  static const String biometricReason = 'يرجى المصادقة للوصول إلى التطبيق';
  static const String biometricCancel = 'إلغاء';

  // Timeouts
  static const int splashDelay = 3000; // milliseconds
  static const int otpExpiry = 300; // seconds
  static const int sessionTimeout = 3600; // seconds
  static const int refreshInterval = 300000; // milliseconds

  // Features
  static const bool enableBiometric = true;
  static const bool enableNotifications = true;
  static const bool enableLocation = true;
  static const bool enableDarkMode = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;

  // Yemen Specific
  static const String countryCode = 'YE';
  static const String currencyCode = 'YER';
  static const String currencySymbol = 'ر.ي';
  static const String phoneCode = '+967';
  static const List<String> yemenCities = [
    'صنعاء',
    'عدن',
    'تعز',
    'الحديدة',
    'المكلا',
    'إب',
    'ذمار',
    'البيضاء',
    'سيئون',
    'زبيد',
    'الغيضة',
    'حجة',
    'سقطرى',
    'رداع',
    'عمران',
    'الجوف',
    'صعدة',
    'مارب',
    ' Shabwa',
    'لحج',
    'أبين',
  ];

  // Payment
  static const List<String> supportedPaymentMethods = [
    'yemen_mobile',
    'sabafon',
    'you_cash',
    'cash_on_delivery',
    'bank_transfer',
  ];

  // Social
  static const String facebookUrl = 'https://facebook.com/sehatak';
  static const String twitterUrl = 'https://twitter.com/sehatak';
  static const String instagramUrl = 'https://instagram.com/sehatak';
  static const String youtubeUrl = 'https://youtube.com/sehatak';
  static const String websiteUrl = 'https://sehatak.com';
  static const String supportEmail = 'support@sehatak.com';
  static const String supportPhone = '+967-1-234-567';
}
