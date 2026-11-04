import '../core/agent_models.dart';
import 'tool.dart';

/// Returns device-local time as a factual observation for the agent.
class CurrentDateTimeTool extends AgentTool {
  @override
  String get name => 'get_current_datetime';

  @override
  String get description =>
      'إرجاع التاريخ والوقت المحليين الحاليين بصيغة ISO-8601.';

  @override
  Map<String, dynamic> get parameters => const {};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async {
    if (params.isNotEmpty) {
      return StepResult.failure('هذه الأداة لا تقبل معاملات.');
    }
    final now = DateTime.now();
    return StepResult.success(
      'تم الحصول على الوقت المحلي للجهاز.',
      data: {
        'local': now.toIso8601String(),
        'utc': now.toUtc().toIso8601String(),
        'timeZoneOffsetMinutes': now.timeZoneOffset.inMinutes,
      },
    );
  }
}
