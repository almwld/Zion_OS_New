import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:pointycastle/export.dart' as pc;

class CryptoSuite {
  final crypto.AesGcm _aes = crypto.AesGcm.with256bits();
  final RsaKeyHelper _rsa = RsaKeyHelper();
  final crypto.Ecdsa _ecdsa = crypto.Ecdsa.p256(crypto.Sha256());

  Future<Map<String, String>> aes256Encrypt(String plaintext, {List<int>? aad}) async {
    final key = await _aes.newSecretKey();
    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
      aad: aad ?? const <int>[],
    );
    return {
      'algorithm': 'AES-256-GCM',
      'key': base64Encode(await key.extractBytes()),
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  Future<String> aes256Decrypt(Map<String, String> payload, {List<int>? aad}) async {
    final key = crypto.SecretKey(base64Decode(payload['key']!));
    final box = crypto.SecretBox(
      base64Decode(payload['ciphertext']!),
      nonce: base64Decode(payload['nonce']!),
      mac: crypto.Mac(base64Decode(payload['mac']!)),
    );
    return utf8.decode(await _aes.decrypt(box, secretKey: key, aad: aad ?? const <int>[]));
  }

  String sha512(List<int> data) => hash.sha512.convert(data).toString();
  String sha512Text(String text) => sha512(utf8.encode(text));

  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey> generateRsa({int bitLength = 2048}) => _rsa.generate(bitLength: bitLength);

  ECDSASigner generateEcdsaSigner() => ECDSASigner(_ecdsa);
}

class ECDSASigner {
  ECDSASigner(this.algorithm);
  final crypto.Ecdsa algorithm;

  Future<crypto.SimpleKeyPair> generateKeyPair() => algorithm.newKeyPair();

  Future<crypto.Signature> sign(List<int> data, crypto.SimpleKeyPair keyPair) => algorithm.sign(data, keyPair: keyPair);

  Future<bool> verify(List<int> data, crypto.Signature signature, crypto.SimplePublicKey publicKey) => algorithm.verify(data, signature: signature, publicKey: publicKey);
}

class RsaKeyHelper {
  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey> generate({int bitLength = 2048}) {
    final secureRandom = pc.FortunaRandom();
    final seed = Uint8List.fromList(List<int>.generate(32, (_) => math.Random.secure().nextInt(256)));
    secureRandom.seed(pc.KeyParameter(seed));
    final params = pc.RSAKeyGeneratorParameters(BigInt.from(65537), bitLength, 64);
    final generator = pc.RSAKeyGenerator()..init(pc.ParametersWithRandom(params, secureRandom));
    final pair = generator.generateKeyPair();
    return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(
      pair.publicKey as pc.RSAPublicKey,
      pair.privateKey as pc.RSAPrivateKey,
    );
  }
}
