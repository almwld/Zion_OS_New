import '../tools/github/github_client.dart';
import 'verifier.dart';
class BuildVerifier implements Verifier {
 final GitHubClient github;final String owner,repo;final int? pullNumber;final String? ref;
 BuildVerifier({required this.github,required this.owner,required this.repo,this.pullNumber,this.ref});
 @override String get name=>'github_check_runs';
 @override Future<VerificationResult> verify(Map<String,dynamic> context)async{
  final pr=(context['pr'] as num?)?.toInt()??pullNumber;
  final sha=context['sha']?.toString()??context['head_sha']?.toString()??ref;
  final data=await github.getCheckRuns(owner,repo,ref:sha,pullNumber:pr);
  final runs=(data['check_runs'] as List? ??const []).whereType<Map>().toList();
  if(runs.isEmpty)return VerificationResult(verifier:name,passed:false,details:'لا توجد فحوص CI للمرجع المحدد',metadata:data);
  final failed=runs.where((r)=>r['status']=='completed'&&r['conclusion']!='success').toList();
  final pending=runs.where((r)=>r['status']!='completed').toList();
  final ok=failed.isEmpty&&pending.isEmpty&&runs.every((r)=>r['conclusion']=='success');
  return VerificationResult(verifier:name,passed:ok,details:ok?'جميع فحوص GitHub نجحت':'فشل: ${failed.map((r)=>r['name']).join(', ')}؛ قيد التشغيل: ${pending.map((r)=>r['name']).join(', ')}',
   metadata:{'total':runs.length,'failed':failed,'pending':pending});
 }
}