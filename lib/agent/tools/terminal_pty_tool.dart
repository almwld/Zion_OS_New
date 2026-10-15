import 'dart:async';
import '../core/agent_models.dart';
import '../core/cancellation_token.dart';
import '../../features/terminal/terminal_service.dart';
import 'tool.dart';

/// Routes Super Agent shell steps through Zion's native PTY runtime.
class TerminalPtyTool extends AgentTool {
  TerminalPtyTool(this.terminal);
  final TerminalService terminal;

  @override
  String get name => 'shell';
  @override
  String get description =>
      'تنفيذ أمر في Zion Terminal عبر native PTY مع المخرجات ورمز الخروج الحقيقي.';
  @override
  Map<String, dynamic> get parameters => const {
        'command': 'string',
        'timeout': 'int',
      };
  @override
  Set<AgentPermission> get permissions => const {AgentPermission.readOnly};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) =>
      _execute(params, null);
  @override
  Future<StepResult> executeCancellable(
    Map<String, dynamic> params,
    CancellationToken? cancellationToken,
  ) => _execute(params, cancellationToken);

  Future<StepResult> _execute(
    Map<String, dynamic> params,
    CancellationToken? cancellationToken,
  ) async {
    final command = params['command']?.toString().trim() ?? '';
    if (command.isEmpty) return StepResult.failure('command مطلوب.');
    final seconds = ((params['timeout'] as num?)?.toInt() ?? 30).clamp(1, 120);
    final subscription = cancellationToken?.onCancel.listen((_) {
      unawaited(terminal.interruptInteractive());
    });
    final started = DateTime.now();
    try {
      cancellationToken?.throwIfCancelled();
      final result = await terminal.executeInInteractive(
        command, timeout: Duration(seconds: seconds));
      cancellationToken?.throwIfCancelled();
      final data = <String, dynamic>{
        'command': command,
        'stdout': result.stdout,
        'stderr': result.stderr,
        'exitCode': result.exitCode,
        'shell': result.shell,
        'pty': true,
      };
      if (!result.succeeded) {
        return StepResult(
          success: false,
          summary: 'فشل أمر Zion PTY (exit ${result.exitCode}).',
          error: result.stderr.isNotEmpty
              ? result.stderr
              : (result.stdout.isNotEmpty ? result.stdout : 'رمز الخروج ${result.exitCode}.'),
          data: data,
          duration: result.duration,
        );
      }
      return StepResult.success(
        result.stdout.isEmpty ? 'اكتمل الأمر عبر Zion native PTY دون مخرجات.' : result.stdout,
        data: data,
        duration: result.duration,
      );
    } catch (error) {
      return StepResult.failure('تعذر تنفيذ الأمر عبر Zion PTY: $error',
        duration: DateTime.now().difference(started));
    } finally {
      await subscription?.cancel();
    }
  }
}
