import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart';

class CryptoSuite {
  final AesGcm _aes = AesGcm.with256bits();
  final RsaKeyHelper _rsa = RsaKeyHelper();
  final Ecdsa _ecdsa = Ecdsa.p256(Sha256());

  Future<Map<String, String>> aes256Encrypt(String plaintext, {List<int>? aad}) async {
    final key = await _aes.newSecretKey();
    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(utf8.encode(plaintext), secretKey: key, nonce: nonce, aad: aad ?? const []);
    return {'algorithm': 'AES-256-GCM', 'key': base64Encode(await key.extractBytes()), 'nonce': base64Encode(box.nonce), 'ciphertext': base64Encode(box.cipherText), 'mac': base64Encode(box.mac.bytes)};
  }

  Future<String> aes256Decrypt(Map<String, String> payload, {List<int>? aad}) async {
    final key = SecretKey(base64Decode(payload['key']!));
    final box = SecretBox(base64Decode(payload['ciphertext']!), nonce: base64Decode(payload['nonce']!), mac: Mac(base64Decode(payload['mac']!)));
    return utf8.decode(await _aes.decrypt(box, secretKey: key, aad: aad ?? const []));
  }

  String sha512(List<int> data) => hash.sha512.convert(data).toString();
  String sha512Text(String text) => sha512(utf8.encode(text));
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRsa({int bitLength = 2048}) => _rsa.generate(bitLength: bitLength);
  ECDSASigner generateEcdsaSigner() => ECDSASigner(_ecdsa);
}

class ECDSASigner {
  ECDSASigner(this.algorithm);
  final Ecdsa algorithm;
  Future<SimpleKeyPair> generateKeyPair() => algorithm.newKeyPair();
  Future<Signature> sign(List<int> data, SimpleKeyPair keyPair) => algorithm.sign(data, keyPair: keyPair);
  Future<bool> verify(List<int> data, Signature signature, SimplePublicKey publicKey) => algorithm.verify(data, signature: signature, publicKey: publicKey);
}

class RsaKeyHelper {
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generate({int bitLength = 2048}) {
    final secureRandom = FortunaRandom();
    final seed = Uint8List.fromList(List<int>.generate(32, (_) => math.Random.secure().nextInt(256)));
    secureRandom.seed(KeyParameter(seed));
    final params = RSAKeyGeneratorParameters(BigInt.from(65537), bitLength, 64);
    final generator = RSAKeyGenerator()..init(ParametersWithRandom(params, secureRandom));
    final pair = generator.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(pair.publicKey as RSAPublicKey, pair.privateKey as RSAPrivateKey);
  }
}
