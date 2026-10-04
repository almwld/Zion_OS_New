import 'zion_token.dart';

class ZionApiAuth {
  final ZionToken token;
  const ZionApiAuth(this.token);

  Future<String> initialize() => token.ensure();
  Future<String?> value() => token.read();
  Future<bool> ready() => token.valid();

  Future<bool> authorize(String presented) async {
    final current = await token.read();
    if (current == null || presented.length != current.length) return false;
    var diff = 0;
    for (var i = 0; i < current.length; i++) {
      diff |= current.codeUnitAt(i) ^ presented.codeUnitAt(i);
    }
    return diff == 0;
  }
}
