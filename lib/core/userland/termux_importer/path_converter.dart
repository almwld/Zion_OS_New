class TermuxPathConverter {
  const TermuxPathConverter();

  static String normalizeArchitecture(String value) {
    switch (value.trim().toLowerCase()) {
      case 'aarch64':
      case 'arm64-v8a':
        return 'arm64';
      case 'x86_64':
      case 'amd64':
        return 'amd64';
      case 'i686':
      case 'i386':
        return 'i386';
      case 'arm':
      case 'armv7':
      case 'armv7l':
        return 'armhf';
      default:
        return value.trim().toLowerCase();
    }
  }

  static bool isCompatible(String source, String target) {
    final a = normalizeArchitecture(source);
    final b = normalizeArchitecture(target);
    return a == 'all' || b == 'all' || a == b;
  }

  static String explainPrefixIsolation() => 'لا يتم تعديل أو sed على الملفات التنفيذية؛ الاستيراد يعيد تثبيت حزمة Zion مكافئة.';
}
