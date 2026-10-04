class ReporterAgent {
  Map<String,dynamic> report(String target,Map<String,dynamic> analysis)=>{'target':target,'generatedAt':DateTime.now().toIso8601String(),'analysis':analysis};
}
