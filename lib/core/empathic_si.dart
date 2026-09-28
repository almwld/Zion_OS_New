import 'si_core.dart';

class EmpathicSi extends SiCore {
  static final EmpathicSi _instance = EmpathicSi._internal();
  factory EmpathicSi() => _instance;
  EmpathicSi._internal();

  final List<String> _commandHistory = [];
  final List<Map<String, dynamic>> _userPatterns = [];

  Future<void> analyzeUserBehavior() async {
    print('🧠 Analyzing user behavior patterns');
    _detectPatterns(_commandHistory);
  }

  void _detectPatterns(List<String> commands) {
    // ✅ إصلاح: قبول List<String>
    final patterns = <String, int>{};
    for (final cmd in commands) {
      final type = cmd.split(' ').first;
      patterns[type] = (patterns[type] ?? 0) + 1;
    }
    
    _userPatterns.add({
      'timestamp': DateTime.now().toIso8601String(),
      'patterns': patterns,
    });
  }

  Future<String> predictNextCommand() async {
    if (_commandHistory.isEmpty) return 'help';
    final lastCmd = _commandHistory.last;
    return lastCmd;
  }

  void recordCommand(String command) {
    _commandHistory.add(command);
    while (_commandHistory.length > 100) {
      _commandHistory.removeAt(0);
    }
  }

  List<Map<String, dynamic>> getPatterns() => List.from(_userPatterns);
}
