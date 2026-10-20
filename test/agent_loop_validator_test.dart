import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/terminal/agent_loop_validator.dart';

void main() {
  const validator = AgentLoopValidator();

  group('AgentLoopValidator.validTarget (task description)', () {
    test('accepts ordinary repair tasks and shell-oriented requests', () {
      expect(validator.validTarget('تشخيص خطأ chdir/getcwd في PRoot'), isTrue);
      expect(validator.validTarget('Find broken Flutter imports; run tests and fix failures'), isTrue);
      expect(validator.validTarget('apt update && inspect package errors'), isTrue);
    });

    test('rejects empty, NUL-containing, and excessively long tasks', () {
      expect(validator.validTarget(''), isFalse);
      expect(validator.validTarget('   '), isFalse);
      expect(validator.validTarget(List.filled(2001, 'x').join()), isFalse);
    });
  });

  group('AgentLoopValidator.validateCommand', () {
    test('allows general shell commands, pipes, redirects and package operations', () {
      expect(validator.validateCommand('pwd && ls -la', 'inspect the environment'), isNull);
      expect(validator.validateCommand('grep -R "chdir" lib | head -20', 'find the implementation'), isNull);
      expect(validator.validateCommand('apt update && apt install -y curl', 'repair packages'), isNull);
      expect(validator.validateCommand('python3 -c "import os; print(os.getcwd())"', 'test getcwd'), isNull);
      expect(validator.validateCommand('git status --short', 'inspect repository'), isNull);
    });

    test('rejects empty, oversized and NUL-containing commands', () {
      expect(validator.validateCommand('', 'task'), isNotNull);
      expect(validator.validateCommand(List.filled(4001, 'x').join(), 'task'), isNotNull);
      expect(validator.validateCommand('echo\u0000bad', 'task'), isNotNull);
    });

    test('blocks catastrophic device and filesystem destruction patterns', () {
      expect(validator.validateCommand('rm -rf /', 'cleanup'), isNotNull);
      expect(validator.validateCommand('mkfs.ext4 /dev/block/mmcblk0', 'format'), isNotNull);
      expect(validator.validateCommand('dd if=/dev/zero of=/dev/block/sda', 'write disk'), isNotNull);
      expect(validator.validateCommand('sudo rm -rf /', 'cleanup'), isNotNull);
    });
  });
}
