import '../zion_pkg.dart';

class VerificationResult {
  const VerificationResult({required this.ok, required this.checked, required this.missing});
  final bool ok;
  final int checked;
  final List<String> missing;
}

class TermuxVerificationRunner {
  const TermuxVerificationRunner(this.pkg);
  final ZionPkg pkg;

  Future<VerificationResult> verify(Iterable<String> packageNames) async {
    var checked = 0;
    final missing = <String>[];
    for (final name in packageNames) {
      checked++;
      if (await pkg.findPackage(name) == null) missing.add(name);
    }
    return VerificationResult(ok: missing.isEmpty, checked: checked, missing: missing);
  }
}
