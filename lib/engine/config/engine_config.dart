import 'engine_mode.dart';
class EngineConfig {
 final EngineMode defaultMode;
 final String? localModelPath,cloudApiKey,cloudBaseUrl,cloudModel,githubToken,githubOwner,githubRepo;
 final int maxStepsPerTask,maxTokensPerStep,maxRepairCycles;
 final Duration maxTaskDuration,buildTimeout,buildPollInterval;
 final bool requireApprovalForWrite,requireApprovalForNetwork;
 const EngineConfig({this.defaultMode=EngineMode.unset,this.localModelPath,this.cloudApiKey,
 this.cloudBaseUrl='https://api.openai.com/v1',this.cloudModel='gpt-4o-mini',
 this.githubToken,this.githubOwner,this.githubRepo,this.maxStepsPerTask=30,this.maxTokensPerStep=1200,
 this.maxRepairCycles=5,this.maxTaskDuration=const Duration(minutes:30),
 this.buildTimeout=const Duration(minutes:30),this.buildPollInterval=const Duration(seconds:30),
 this.requireApprovalForWrite=true,this.requireApprovalForNetwork=false});
 List<String> validate(){
  final e=<String>[];
  if(maxStepsPerTask<1||maxStepsPerTask>100)e.add('maxStepsPerTask خارج النطاق');
  if(maxTokensPerStep<64)e.add('maxTokensPerStep يجب ألا يقل عن 64');
  if(maxRepairCycles<0||maxRepairCycles>5)e.add('maxRepairCycles يجب أن يكون بين 0 و5');
  if(defaultMode==EngineMode.local&&(localModelPath?.isEmpty??true))e.add('مسار النموذج المحلي مطلوب');
  if(defaultMode==EngineMode.cloud&&(cloudApiKey?.isEmpty??true))e.add('مفتاح API السحابي مطلوب');
  if(githubToken!=null&&(githubOwner==null||githubRepo==null))e.add('إعداد GitHub يحتاج owner وrepo');
  return e;
 }
}