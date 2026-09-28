import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// خوارزمية Q-Learning لتحسين قرارات الهجوم
class ReinforcementLearning {
  static final ReinforcementLearning _instance = ReinforcementLearning._internal();
  factory ReinforcementLearning() => _instance;
  ReinforcementLearning._internal();

  Map<String, Map<String, double>> _qTable = {};
  final double _learningRate = 0.1;
  final double _discountFactor = 0.95;
  final double _explorationRate = 0.1;

  /// تحديث Q-Value بعد كل هجوم
  void update(String state, String action, double reward, String nextState) {
    if (!_qTable.containsKey(state)) {
      _qTable[state] = {};
    }
    if (!_qTable.containsKey(nextState)) {
      _qTable[nextState] = {};
    }

    final currentQ = _qTable[state]![action] ?? 0.0;
    final maxNextQ = _qTable[nextState]!.values.isEmpty ? 0.0 : _qTable[nextState]!.values.reduce(max);
    final newQ = currentQ + _learningRate * (reward + _discountFactor * maxNextQ - currentQ);
    
    _qTable[state]![action] = newQ;
  }

  /// اختيار أفضل هجوم (ε-greedy)
  String selectAction(String state, List<String> actions) {
    if (Random().nextDouble() < _explorationRate) {
      // استكشاف: اختيار عشوائي
      return actions[Random().nextInt(actions.length)];
    }
    // استغلال: أفضل هجوم معروف
    final qValues = _qTable[state] ?? {};
    String? bestAction;
    double bestValue = -double.infinity;
    for (final action in actions) {
      final value = qValues[action] ?? 0.0;
      if (value > bestValue) {
        bestValue = value;
        bestAction = action;
      }
    }
    return bestAction ?? actions[0];
  }

  /// حساب المكافأة بناءً على نتيجة الهجوم
  double calculateReward(bool success, int durationMs, int targetValue) {
    if (success) {
      return 100.0 - (durationMs / 1000); // أسرع = مكافأة أكبر
    }
    return -50.0; // عقاب للفشل
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    // حفظ Q-Table
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // تحميل Q-Table
  }
}
