import 'verifier.dart';
class VerificationEngine {
 final List<Verifier> verifiers;VerificationEngine(this.verifiers);
 Future<List<VerificationResult>> verifyAll(Map<String,dynamic> context)=>Future.wait(verifiers.map((v)async{
  try{return await v.verify(context);}catch(e){return VerificationResult(verifier:v.name,passed:false,details:'تعذر التحقق: $e');}
 }));
 Future<bool> allPassed(Map<String,dynamic> context)async{final r=await verifyAll(context);return r.isNotEmpty&&r.every((e)=>e.passed);}
}