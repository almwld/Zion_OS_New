import 'package:local_auth/local_auth.dart';

import '../core/services/biometric_service.dart' as core;

/// Legacy compatibility facade for the canonical biometric service.
///
/// @deprecated Use core.BiometricService from lock-screen and security code.
@Deprecated('Use core.BiometricService instead.')
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final core.BiometricService _delegate = core.BiometricService();

  Future<bool> isBiometricAvailable() => _delegate.isAvailable();

  Future<List<BiometricType>> getAvailableBiometrics() =>
      _delegate.getAvailableBiometrics();

  Future<bool> authenticateWithBiometrics({
    required String reason,
    String? title,
    String? subtitle,
  }) async {
    return (await _delegate.authenticateResult(reason: reason)).success;
  }

  String getBiometricTypeName(BiometricType type) =>
      _typeName(type);

  String _typeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'بصمة الإصبع';
      case BiometricType.face:
        return 'التعرف على الوجه';
      case BiometricType.iris:
        return 'بصمة العين';
      default:
        return 'بيومترية';
    }
  }
}
