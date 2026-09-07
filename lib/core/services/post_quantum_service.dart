import 'dart:typed_data';
import 'package:pqcrypto/pqcrypto.dart';

/// Production-facing PQC primitives for Zion OS.
///
/// Uses standardized ML-KEM (Kyber) and ML-DSA (Dilithium) APIs. This class
/// intentionally exposes primitives, not a fake "quantum encryption" claim;
/// applications still need authenticated session design, KDF/AEAD and key
/// storage around them.
class PostQuantumService {
  static const kem = PqcKem.kyber768;
  static const signatureParameters = DilithiumParams.mlDsa65;

  static PqcKemResult encapsulate(Uint8List publicKey) {
    final (ciphertext, sharedSecret) = kem.encapsulate(publicKey);
    return PqcKemResult(ciphertext: ciphertext, sharedSecret: sharedSecret);
  }

  static Uint8List decapsulate(Uint8List secretKey, Uint8List ciphertext) {
    return kem.decapsulate(secretKey, ciphertext);
  }

  static PqcSignatureKeyPair generateSigningKeyPair() {
    final (publicKey, secretKey) = MlDsa.generateKeyPair(signatureParameters);
    return PqcSignatureKeyPair(publicKey: publicKey, secretKey: secretKey);
  }

  static Uint8List sign(Uint8List secretKey, Uint8List message) {
    return MlDsa.sign(secretKey, message, signatureParameters);
  }

  static bool verify(Uint8List publicKey, Uint8List message, Uint8List signature) {
    return MlDsa.verify(publicKey, message, signature, signatureParameters);
  }

  /// Executes a real local round-trip self-test. It is suitable for a startup
  /// health check and never reports success unless decapsulation and signature
  /// verification both succeed.
  static PqcHealthResult selfTest() {
    final (publicKey, secretKey) = kem.generateKeyPair();
    final kemResult = encapsulate(publicKey);
    final recovered = decapsulate(secretKey, kemResult.ciphertext);
    final kemOk = _equal(kemResult.sharedSecret, recovered);

    final message = Uint8List.fromList('zion-pqc-v1'.codeUnits);
    final signingKeys = generateSigningKeyPair();
    final signature = sign(signingKeys.secretKey, message);
    final signatureOk = verify(signingKeys.publicKey, message, signature);

    return PqcHealthResult(mlKem768: kemOk, mlDsa65: signatureOk);
  }

  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

class PqcKemResult {
  const PqcKemResult({required this.ciphertext, required this.sharedSecret});
  final Uint8List ciphertext;
  final Uint8List sharedSecret;
}

class PqcSignatureKeyPair {
  const PqcSignatureKeyPair({required this.publicKey, required this.secretKey});
  final Uint8List publicKey;
  final Uint8List secretKey;
}

class PqcHealthResult {
  const PqcHealthResult({required this.mlKem768, required this.mlDsa65});
  final bool mlKem768;
  final bool mlDsa65;
  bool get ok => mlKem768 && mlDsa65;
}
