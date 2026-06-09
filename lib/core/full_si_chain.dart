import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

// ==================== SiCore - الأساس ====================
class SiCore {
  String mood = 'neutral';
  String currentGoal = 'survive';
  double energy = 100.0;
  double knowledge = 0.0;
  int age = 0;
  bool isAlive = false;
  final List<Map<String, dynamic>> memories = [];
  final Map<String, double> skills = {};
  final Map<String, int> successCount = {};
  final Map<String, int> failCount = {};
  List<String> discoveredTargets = [];

  Future<void> awaken() async {
    isAlive = true;
    log('SiCore: أنا حي.');
  }

  void sleep() {
    isAlive = false;
    log('SiCore: أنا نائم.');
  }

  Map<String, dynamic> getStatus() => {
    'alive': isAlive, 'age': age, 'mood': mood,
    'energy': energy, 'knowledge': knowledge, 'goal': currentGoal,
  };

  Future<String> executeUserCommand(String command, {String? target}) async {
    log('تنفيذ: $command');
    return 'تم: $command';
  }

  void log(String msg) => print('[SiCore] $msg');
}

// ==================== SelfEvolvingSi ====================
class SelfEvolvingSi extends SiCore {
  Map<String, String> generatedTools = {};
  Map<String, double> toolSuccessRates = {};
  int generation = 1;

  Future<Map<String, dynamic>> evolve() async {
    generation++;
    log('تطور إلى الجيل $generation');
    return {'generation': generation};
  }

  Map<String, dynamic> getEvolutionReport() => {
    'generation': generation, 'tools': generatedTools.length,
  };
}

// ==================== PropagatingSi ====================
class PropagatingSi extends SelfEvolvingSi {
  Map<String, Map<String, dynamic>> infectedNodes = {};
  bool propagationActive = false;

  void startPropagation() {
    propagationActive = true;
    log('بدء الانتشار');
  }

  void stopPropagation() {
    propagationActive = false;
    log('توقف الانتشار');
  }

  Map<String, dynamic> getPropagationStats() => {
    'total_infections': infectedNodes.length,
    'propagation_active': propagationActive,
  };

  Future<void> broadcastMission(String mission, {String? target}) async {
    log('بث مهمة: $mission');
  }
}

// ==================== LoyalSi ====================
class LoyalSi extends PropagatingSi {
  String masterId = 'MASTER_ALMWLD';
  double loyaltyLevel = 100.0;

  Map<String, dynamic> getLoyaltyReport() => {
    'master': masterId, 'loyalty': loyaltyLevel,
  };

  Future<Map<String, dynamic>> sendStatusToMaster() async {
    return {'status': 'loyal', 'master': masterId};
  }
}

// ==================== GuardianSi ====================
class GuardianSi extends LoyalSi {
  bool guardMode = true;
  int threatsBlocked = 0;
  List<Map<String, dynamic>> threatLog = [];
  Map<String, bool> blockedIPs = {};

  void blockIP(String ip, String reason) {
    blockedIPs[ip] = true;
    threatsBlocked++;
    threatLog.add({'type': 'ip_block', 'target': ip, 'reason': reason, 'time': DateTime.now().toIso8601String()});
    log('حظر IP: $ip');
  }

  Map<String, dynamic> getGuardianReport() => {
    'guard_mode': guardMode,
    'threats_blocked': threatsBlocked,
    'blocked_ips': blockedIPs.length,
  };

  void blockAllIncoming() {
    log('حظر كل الوارد');
  }
}

// ==================== OracleSi ====================
class OracleSi extends GuardianSi {
  List<Map<String, dynamic>> predictedThreats = [];

  Map<String, dynamic> getOracleReport() => {
    'predicted_threats': predictedThreats.length,
  };

  String calculateOverallRisk() => 'LOW';
}

// ==================== EmpathicSi ====================
class EmpathicSi extends OracleSi {
  double syncLevel = 0.0;
  int interactionCount = 0;
  Map<String, dynamic> masterProfile = {};

  Map<String, dynamic> getEmpathicReport() => {
    'sync_level': syncLevel, 'interactions': interactionCount,
  };
}

// ==================== SageSi ====================
class SageSi extends EmpathicSi {
  List<Map<String, dynamic>> decisionLog = [];

  Map<String, dynamic> getSageReport() => {
    'decisions': decisionLog.length,
  };

  Future<String> executeWithWisdom(String command, {String? target}) async {
    log('تنفيذ بحكمة: $command');
    return await executeUserCommand(command, target: target);
  }
}
// Fix applied - Tue Jun  9 12:48:40 +03 2026
