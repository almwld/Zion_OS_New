class VerificationResult {
 final String verifier,details;final bool passed;final Map<String,dynamic> metadata;
 const VerificationResult({required this.verifier,required this.passed,required this.details,this.metadata=const {}});
}
abstract interface class Verifier {String get name;Future<VerificationResult> verify(Map<String,dynamic> context);}
class VerificationException implements Exception {final String message;const VerificationException(this.message);@override String toString()=>message;}