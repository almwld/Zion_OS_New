import 'dart:math' as math;

import '../core/agent_models.dart';
import 'tool.dart';

/// Deterministic, offline arithmetic tool. It never evaluates Dart or shell code.
class CalculatorTool extends AgentTool {
  @override
  String get name => 'calculator';

  @override
  String get description =>
      'حساب تعبيرات رياضية آمنة: + و - و * و / و % و ^ والأقواس.';

  @override
  Map<String, dynamic> get parameters => const {
        'expression': 'string',
      };

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async {
    final expression = params['expression'];
    if (expression is! String || expression.trim().isEmpty) {
      return StepResult.failure('يجب إدخال expression نصي غير فارغ.');
    }
    if (expression.length > 256) {
      return StepResult.failure('التعبير أطول من الحد المسموح.');
    }
    try {
      final value = _ArithmeticParser(expression).parse();
      if (!value.isFinite) {
        return StepResult.failure('الناتج ليس رقماً محدوداً.');
      }
      return StepResult.success('تم الحساب بدقة.', data: value);
    } on FormatException catch (error) {
      return StepResult.failure(error.message.toString());
    }
  }
}

class _ArithmeticParser {
  _ArithmeticParser(String source) {
    var offset = 0;
    while (offset < source.length) {
      final match = RegExp(r'\\s*(\\d+(?:\\.\\d*)?|\\.\\d+|[()+\\-*/%^])')
          .matchAsPrefix(source, offset);
      if (match == null) {
        if (source.substring(offset).trim().isEmpty) break;
        throw FormatException('رمز غير مدعوم قرب: ${source.substring(offset)}');
      }
      _tokens.add(match.group(1)!);
      offset = match.end;
    }
  }

  final List<String> _tokens = <String>[];
  int _position = 0;

  double parse() {
    if (_tokens.isEmpty) throw const FormatException('التعبير فارغ.');
    final value = _expression();
    if (_position != _tokens.length) {
      throw FormatException('رمز غير متوقع: ${_peek()}');
    }
    return value;
  }

  double _expression() {
    var value = _term();
    while (_match('+') || _match('-')) {
      final operator = _previous();
      final right = _term();
      value = operator == '+' ? value + right : value - right;
    }
    return value;
  }

  double _term() {
    var value = _unary();
    while (_match('*') || _match('/') || _match('%')) {
      final operator = _previous();
      final right = _unary();
      if ((operator == '/' || operator == '%') && right == 0) {
        throw const FormatException('القسمة على صفر غير مسموحة.');
      }
      if (operator == '*') {
        value *= right;
      } else if (operator == '/') {
        value /= right;
      } else {
        value %= right;
      }
    }
    return value;
  }

  double _unary() {
    if (_match('+')) return _unary();
    if (_match('-')) return -_unary();
    return _power();
  }

  double _power() {
    final value = _primary();
    if (_match('^')) return math.pow(value, _unary()).toDouble();
    return value;
  }

  double _primary() {
    if (_match('(')) {
      final value = _expression();
      if (!_match(')')) throw const FormatException('قوس الإغلاق مفقود.');
      return value;
    }
    final token = _peek();
    if (token == null) throw const FormatException('انتهى التعبير قبل اكتماله.');
    _position++;
    final value = double.tryParse(token);
    if (value == null) throw FormatException('كان متوقعاً رقماً بدلاً من $token.');
    return value;
  }

  bool _match(String token) {
    if (_peek() != token) return false;
    _position++;
    return true;
  }

  String? _peek() => _position < _tokens.length ? _tokens[_position] : null;
  String _previous() => _tokens[_position - 1];
}
