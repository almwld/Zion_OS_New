import 'zion_token.dart';
class ZionApiAuth { final ZionToken token; const ZionApiAuth(this.token); Future<String?> value()=>token.read(); Future<bool> ready()=>token.valid(); }