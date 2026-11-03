enum EngineMode { local, cloud, unset }
extension EngineModeX on EngineMode {
 String get displayName => switch(this) { EngineMode.local=>'محلي', EngineMode.cloud=>'سحابي', EngineMode.unset=>'غير محدد' };
}