import 'role_handoff.dart';
import 'role_profile.dart';

class RoleSequencer {
  static const List<AgentRole> defaultSequence = [
    AgentRole.planner,
    AgentRole.researcher,
    AgentRole.analyst,
    AgentRole.coder,
    AgentRole.executor,
    AgentRole.verifier,
    AgentRole.reporter,
  ];

  RoleSequencer({List<AgentRole> sequence = defaultSequence})
      : sequence = List.unmodifiable(sequence) {
    if (sequence.isEmpty || sequence.toSet().length != sequence.length) {
      throw ArgumentError('تسلسل الأدوار يجب أن يكون غير فارغ وبدون تكرار.');
    }
  }

  final List<AgentRole> sequence;
  int _index = -1;
  RoleHandoff? _lastHandoff;
  int get index => _index;
  RoleProfile? get current => _index >= 0 && _index < sequence.length ? RoleProfile.forRole(sequence[_index]) : null;
  RoleHandoff? get lastHandoff => _lastHandoff;
  bool get isComplete => _index >= sequence.length - 1;

  RoleProfile begin() {
    _index = 0;
    _lastHandoff = null;
    return RoleProfile.forRole(sequence.first);
  }

  RoleHandoff advance({required Map<String, dynamic> context, required String reason}) {
    if (_index < 0 || isComplete) throw StateError('لا يوجد دور حالي يمكن تسليمه.');
    final from = RoleProfile.forRole(sequence[_index]);
    final to = RoleProfile.forRole(sequence[_index + 1]);
    _index++;
    _lastHandoff = RoleHandoff(from: from, to: to, context: context, reason: reason);
    return _lastHandoff!;
  }

  void reset() {
    _index = -1;
    _lastHandoff = null;
  }
}
