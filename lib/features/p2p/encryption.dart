import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class P2PEncryption {
  static final _algorithm=AesGcm.with256bits();
  Future<SecretKey> key(String secret) async {
    final digest=await Sha256().hash(utf8.encode(secret));
    return SecretKey(digest.bytes);
  }
  Future<String> encrypt(String value,String secret) async {
    final box=await _algorithm.encrypt(utf8.encode(value),secretKey:await key(secret));
    return jsonEncode({'n':base64UrlEncode(box.nonce),'c':base64UrlEncode(box.cipherText),'m':base64UrlEncode(box.mac.bytes)});
  }
  Future<String> decrypt(String payload,String secret) async {
    final map=jsonDecode(payload) as Map;
    final box=SecretBox(base64Url.decode(map['c']),nonce:base64Url.decode(map['n']),mac:Mac(base64Url.decode(map['m'])));
    return utf8.decode(await _algorithm.decrypt(box,secretKey:await key(secret)));
  }
  Future<String> fingerprint(String secret) async {
    final digest=await Sha256().hash(utf8.encode(secret));
    return digest.bytes.map((b)=>b.toRadixString(16).padLeft(2,'0')).join(':');
  }
}
