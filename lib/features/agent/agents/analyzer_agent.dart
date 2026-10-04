class AnalyzerAgent {
  Map<String,dynamic> analyze(Map<String,dynamic> recon)=>{'target':recon['target'],'findings':recon['findings']??const <String>[],'severity':'unknown','status':'analysis_ready'};
}
