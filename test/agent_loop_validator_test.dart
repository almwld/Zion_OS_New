import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/terminal/agent_loop_validator.dart';

void main() {
  const validator = AgentLoopValidator();

  group('AgentLoopValidator.validTarget', () {
    test('accepts IPv4 and DNS hostnames', () {
      expect(validator.validTarget('192.168.1.10'), isTrue);
      expect(validator.validTarget('example.org'), isTrue);
      expect(validator.validTarget('scan.example.org.'), isTrue);
    });

    test('rejects malformed or command-shaped targets', () {
      expect(validator.validTarget('999.1.1.1'), isFalse);
      expect(validator.validTarget('example.org/path'), isFalse);
      expect(validator.validTarget('example.org;whoami'), isFalse);
      expect(validator.validTarget(''), isFalse);
      expect(validator.validTarget('user@example.org'), isFalse);
    });
  });

  group('AgentLoopValidator.validateCommand', () {
    test('accepts bounded reconnaissance for the exact target', () {
      expect(
        validator.validateCommand(
          'nmap -sV -p 22,53,80,443 example.org',
          'example.org',
        ),
        isNull,
      );
      expect(
        validator.validateCommand('curl -I https://example.org/status', 'example.org'),
        isNull,
      );
      expect(
        validator.validateCommand('dig example.org', 'example.org'),
        isNull,
      );
    });

    test('rejects hostnames that only contain or extend the target', () {
      expect(
        validator.validateCommand('nmap -sV example.org.attacker.test', 'example.org'),
        isNotNull,
      );
      expect(
        validator.validateCommand('nmap -sV attacker-example.org', 'example.org'),
        isNotNull,
      );
    });

    test('rejects shell chaining and unrestricted options', () {
      expect(
        validator.validateCommand('nmap example.org; whoami', 'example.org'),
        isNotNull,
      );
      expect(
        validator.validateCommand('nmap -p- example.org', 'example.org'),
        isNotNull,
      );
      expect(
        validator.validateCommand('curl -X POST https://example.org', 'example.org'),
        isNotNull,
      );
      expect(
        validator.validateCommand('hydra -l admin example.org', 'example.org'),
        isNotNull,
      );
    });

    test('matches URL host exactly, not URL text', () {
      expect(
        validator.validateCommand('curl -I https://attacker.test/?next=example.org', 'example.org'),
        isNotNull,
      );
      expect(
        validator.validateCommand('curl -I https://example.org/path', 'example.org'),
        isNull,
      );
    });
  });
}
