import '../../agent/core/agent_models.dart';
import 'verifier.dart';

class ToolResultVerifier implements Verifier {
  const ToolResultVerifier();

  @override
  String get name => 'tool_result_contract';

  @override
  Future<VerificationResult> verify(Map<String, dynamic> context) async {
    final result = context['result'];
    if (result is! StepResult) {
      return VerificationResult(
        verifier: name,
        passed: false,
        details: 'لم تُقدّم الأداة نتيجة تنفيذ قابلة للتحقق.',
      );
    }
    if (!result.success) {
      return VerificationResult(
        verifier: name,
        passed: false,
        details: result.error ?? result.summary,
      );
    }
    final data = result.data;
    if (data is Map) {
      if (data['success'] == false) {
        return VerificationResult(
          verifier: name,
          passed: false,
          details: 'بيانات الأداة تشير إلى فشل رغم إعلان نجاح الخطوة.',
        );
      }
      final exitCode = data['exitCode'];
      if (exitCode is num && exitCode != 0) {
        return VerificationResult(
          verifier: name,
          passed: false,
          details: 'رمز خروج الأداة غير صفري: $exitCode.',
          metadata: {'exitCode': exitCode},
        );
      }
      if (data['verified'] == false) {
        return VerificationResult(
          verifier: name,
          passed: false,
          details: 'الأداة أفادت بأن المخرجات لم تجتز التحقق.',
        );
      }
    }
    return VerificationResult(
      verifier: name,
      passed: true,
      details: 'نتيجة الأداة متسقة مع عقد النجاح.',
      metadata: {
        'tool': context['tool'],
        'stepId': context['stepId'],
      },
    );
  }
}
