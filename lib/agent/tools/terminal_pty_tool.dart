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
      'تنفيذ أمر عبر جلسة Zion Terminal native PTY. runtime=auto يستخدم الجلسة الحالية، runtime=zion يختار Zion Userland، وruntime=kali يشغّل Kali rootfs المحلي المتحقق منه دون تنزيل.';
  @override
  Map<String, dynamic> get parameters => const {
        'command': 'string',
        'timeout': 'int',
        'runtime': 'auto | zion | kali',
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
    final seconds = ((params['timeout'] as num?)?.toInt() ?? 900).clamp(1, 1800);
    final runtime = (params['runtime']?.toString() ?? 'auto').trim().toLowerCase();
    final subscription = cancellationToken?.onCancel.listen((_) {
      unawaited(terminal.interruptInteractive());
    });
    final started = DateTime.now();
    try {
      cancellationToken?.throwIfCancelled();
      final result = await terminal.executeInInteractive(
        command, timeout: Duration(seconds: seconds), runtime: runtime);
      cancellationToken?.throwIfCancelled();
      // A PTY merges stdout/stderr by design. Keep the raw stream honest and
      // expose a diagnostic field for non-zero exits instead of pretending the
      // PTY has separate file descriptors.
      final combinedOutput = result.stdout;
      final diagnostic = result.stderr.isNotEmpty
          ? result.stderr
          : (!result.succeeded && combinedOutput.isNotEmpty
              ? combinedOutput
              : '');
      final data = <String, dynamic>{
        'command': command,
        'stdout': combinedOutput,
        'combinedOutput': combinedOutput,
        'stderr': diagnostic,
        'outputStream': 'pty-combined',
        'exitCode': result.exitCode,
        'durationMs': result.duration.inMilliseconds,
        'shell': result.shell,
        'runtime': runtime,
        'pty': true,
      };
      if (!result.succeeded) {
        return StepResult(
          success: false,
          summary: result.exitCode == 124
              ? 'انتهت مهلة أمر Zion PTY (exit 124).'
              : 'فشل أمر Zion PTY (exit ${result.exitCode}).',
          error: diagnostic.isNotEmpty
              ? diagnostic
              : 'رمز الخروج ${result.exitCode}.',
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
