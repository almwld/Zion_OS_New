import 'agents/recon_agent.dart';
import 'agents/analyzer_agent.dart';
import 'agents/exploiter_agent.dart';
import 'agents/cracker_agent.dart';
import 'agents/reporter_agent.dart';

class AgentOrchestrator {
  final ReconAgent recon;
  final AnalyzerAgent analyzer;
  final ExploiterAgent exploiter;
  final CrackerAgent cracker;
  final ReporterAgent reporter;
  AgentOrchestrator({ReconAgent? recon,AnalyzerAgent? analyzer,ExploiterAgent? exploiter,CrackerAgent? cracker,ReporterAgent? reporter})
      : recon=recon??ReconAgent(),analyzer=analyzer??AnalyzerAgent(),exploiter=exploiter??ExploiterAgent(),cracker=cracker??CrackerAgent(),reporter=reporter??ReporterAgent();

  Future<Map<String,dynamic>> run(String target,{required bool authorized}) async {
    if(!authorized) return {'status':'blocked','reason':'Explicit authorization is required before security assessment actions.','target':target};
    final r=await recon.collect(target);
    final a=analyzer.analyze(r);
    final e=exploiter.plan(a);
    final c=cracker.plan(a);
    return {'status':'planned','recon':r,'analysis':a,'exploitation':e,'credential_testing':c,'report':reporter.report(target,a)};
  }
}
