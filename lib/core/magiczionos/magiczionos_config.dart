enum RootStrategy { magiczionos, proot, chroot, auto }

class MagiczionosConfig {
  const MagiczionosConfig({
    this.preferredStrategy = RootStrategy.auto,
    this.autoFallback = true,
    this.enableAudit = true,
    this.enableNotifications = true,
    this.defaultDistro = 'ubuntu',
    this.defaultShell = '/bin/bash',
    this.commandTimeoutSeconds = 60,
    this.allowDangerousCommands = false,
    this.logAllCommands = true,
    this.keepSessionAlive = true,
  });
  final RootStrategy preferredStrategy;
  final bool autoFallback, enableAudit, enableNotifications, allowDangerousCommands, logAllCommands, keepSessionAlive;
  final String defaultDistro, defaultShell;
  final int commandTimeoutSeconds;
  Map<String,dynamic> toJson()=>{'preferredStrategy':preferredStrategy.name,'autoFallback':autoFallback,'enableAudit':enableAudit,'enableNotifications':enableNotifications,'defaultDistro':defaultDistro,'defaultShell':defaultShell,'commandTimeoutSeconds':commandTimeoutSeconds,'allowDangerousCommands':allowDangerousCommands,'logAllCommands':logAllCommands,'keepSessionAlive':keepSessionAlive};
  factory MagiczionosConfig.fromJson(Map<String,dynamic> j)=>MagiczionosConfig(
    preferredStrategy: RootStrategy.values.where((e)=>e.name==j['preferredStrategy']).firstOrNull ?? RootStrategy.auto,
    autoFallback: j['autoFallback'] is bool ? j['autoFallback'] as bool : true,
    enableAudit: j['enableAudit'] is bool ? j['enableAudit'] as bool : true,
    enableNotifications: j['enableNotifications'] is bool ? j['enableNotifications'] as bool : true,
    defaultDistro: j['defaultDistro'] as String? ?? 'ubuntu',
    defaultShell: j['defaultShell'] as String? ?? '/bin/bash',
    commandTimeoutSeconds: j['commandTimeoutSeconds'] is int ? j['commandTimeoutSeconds'] as int : 60,
    allowDangerousCommands: false,
    logAllCommands: j['logAllCommands'] is bool ? j['logAllCommands'] as bool : true,
    keepSessionAlive: j['keepSessionAlive'] is bool ? j['keepSessionAlive'] as bool : true,
  );
  MagiczionosConfig copyWith({RootStrategy? preferredStrategy,bool? autoFallback,bool? enableAudit,bool? enableNotifications,String? defaultDistro,String? defaultShell,int? commandTimeoutSeconds,bool? allowDangerousCommands,bool? logAllCommands,bool? keepSessionAlive})=>MagiczionosConfig(
    preferredStrategy:preferredStrategy??this.preferredStrategy,autoFallback:autoFallback??this.autoFallback,enableAudit:enableAudit??this.enableAudit,enableNotifications:enableNotifications??this.enableNotifications,defaultDistro:defaultDistro??this.defaultDistro,defaultShell:defaultShell??this.defaultShell,commandTimeoutSeconds:commandTimeoutSeconds??this.commandTimeoutSeconds,allowDangerousCommands:allowDangerousCommands??this.allowDangerousCommands,logAllCommands:logAllCommands??this.logAllCommands,keepSessionAlive:keepSessionAlive??this.keepSessionAlive);
}