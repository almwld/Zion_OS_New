import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // التحقق من توفر البصمة
  Future<bool> isAvailable() async {
    return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
  }

  // الحصول على أنواع البصمة المتاحة
  Future<List<BiometricType>> getAvailableTypes() async {
    return await _auth.getAvailableBiometrics();
  }

  // طلب البصمة
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // وصف نوع البصمة
  String getBiometricName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.iris)) return 'Iris';
    if (types.contains(BiometricType.fingerprint)) return 'البصمة';
    return 'بصمة الإصبع';
  }
}
