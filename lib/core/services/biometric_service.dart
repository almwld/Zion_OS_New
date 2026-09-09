import 'package:local_auth/local_auth.dart';

/// Real device biometric integration for Android.
///
/// This service intentionally delegates authentication to Android's secure
/// biometric prompt through the `local_auth` plugin instead of simulating
/// availability or successful authentication.
class BiometricService {
  BiometricService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'التحقق من هويتك للوصول إلى Zion OS'}) async {
    try {
      if (!await isAvailable()) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const <BiometricType>[];
    }
  }
}
