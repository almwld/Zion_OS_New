import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Real device biometric integration for the Zion OS lock screen.
/// Authentication is delegated to Android's secure biometric/device-credential
/// prompt. No biometric material is stored or transmitted by the app.
class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<BiometricAuthResult> authenticateResult({
    String reason = 'التحقق من هويتك للوصول إلى Zion OS',
  }) async {
    try {
      if (!await isAvailable()) {
        return const BiometricAuthResult(
          success: false,
          error: 'البصمة غير متاحة أو لم يتم تسجيلها على هذا الجهاز',
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      return authenticated
          ? const BiometricAuthResult(success: true)
          : const BiometricAuthResult(
              success: false,
              error: 'لم يتم التحقق من الهوية',
            );
    } on PlatformException catch (e) {
      return BiometricAuthResult(success: false, error: _errorMessage(e));
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        error: 'تعذر استخدام المصادقة البيومترية: $e',
      );
    }
  }

  Future<bool> authenticate({
    String reason = 'التحقق من هويتك للوصول إلى Zion OS',
  }) async {
    final result = await authenticateResult(reason: reason);
    return result.success;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const <BiometricType>[];
    }
  }

  String _errorMessage(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
      case 'notAvailable':
        return 'البصمة غير متاحة على هذا الجهاز';
      case 'NotEnrolled':
      case 'notEnrolled':
        return 'لم يتم تسجيل بصمة على هذا الجهاز';
      case 'LockedOut':
      case 'lockedOut':
        return 'تم قفل المصادقة البيومترية مؤقتاً. استخدم PIN أو حاول لاحقاً';
      case 'PermanentlyLockedOut':
      case 'permanentlyLockedOut':
        return 'تم قفل المصادقة البيومترية. استخدم PIN';
      case 'UserCanceled':
      case 'userCanceled':
        return 'تم إلغاء المصادقة';
      default:
        return e.message?.isNotEmpty == true
            ? 'فشل التحقق: ${e.message}'
            : 'فشل التحقق البيومتري';
    }
  }
}

class BiometricAuthResult {
  const BiometricAuthResult({required this.success, this.error});
  final bool success;
  final String? error;
}