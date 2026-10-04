import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class VaultCrypto {
  static final _algorithm=AesGcm.with256bits();
  static Future<String> protect(String value,String secret) async {
    final keyBytes=await _key(secret); final box=await _algorithm.encrypt(utf8.encode(value),secretKey:SecretKey(keyBytes));
    return jsonEncode({'n':base64UrlEncode(box.nonce),'c':base64UrlEncode(box.cipherText),'m':base64UrlEncode(box.mac.bytes)});
  }
  static Future<String> unprotect(String value,String secret) async {
    final m=jsonDecode(value) as Map; final box=SecretBox(base64Url.decode(m['c']),nonce:base64Url.decode(m['n']),mac:Mac(base64Url.decode(m['m'])));
    return utf8.decode(await _algorithm.decrypt(box,secretKey:SecretKey(await _key(secret))));
  }
  static Future<List<int>> _key(String secret) async {final h=await Sha256().hash(utf8.encode(secret));return Uint8List.fromList(h.bytes);}
}