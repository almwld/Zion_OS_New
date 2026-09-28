import 'package:flutter/material.dart';
import 'dart:math';

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  String _expression = '';
  String _result = '';
  String _history = '';
  bool _isScientific = false;
  
  // Scientific mode variables
  double _memory = 0;
  String _angleMode = 'DEG'; // DEG, RAD, GRAD
  
  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
        _history = '';
      } else if (value == 'CE') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        try {
          _history = _expression;
          _result = _calculate(_expression);
          _expression = _result;
        } catch (e) {
          _result = 'Error';
          _expression = '';
        }
      } else if (value == 'sin') {
        _expression += 'sin(';
      } else if (value == 'cos') {
        _expression += 'cos(';
      } else if (value == 'tan') {
        _expression += 'tan(';
      } else if (value == 'log') {
        _expression += 'log(';
      } else if (value == 'ln') {
        _expression += 'ln(';
      } else if (value == 'sqrt') {
        _expression += 'sqrt(';
      } else if (value == '^') {
        _expression += '^';
      } else if (value == 'π') {
        _expression += pi.toStringAsFixed(8);
      } else if (value == 'e') {
        _expression += exp(1).toStringAsFixed(8);
      } else if (value == 'M+') {
        _memory += double.tryParse(_result.isNotEmpty ? _result : '0') ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to memory'), backgroundColor: Color(0xFF00BCD4)),
        );
      } else if (value == 'M-') {
        _memory -= double.tryParse(_result.isNotEmpty ? _result : '0') ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subtracted from memory'), backgroundColor: Color(0xFF00BCD4)),
        );
      } else if (value == 'MR') {
        _expression += _memory.toString();
      } else if (value == 'MC') {
        _memory = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory cleared'), backgroundColor: Color(0xFF00BCD4)),
        );
      } else {
        _expression += value;
      }
    });
  }
  
  String _calculate(String expression) {
    // Replace mathematical functions
    String expr = expression
        .replaceAll('sin(', 'sin(')
        .replaceAll('cos(', 'cos(')
        .replaceAll('tan(', 'tan(')
        .replaceAll('log(', 'log(')
        .replaceAll('ln(', 'ln(')
        .replaceAll('sqrt(', 'sqrt(')
        .replaceAll('^', '**');
    
    // Simple evaluation (for demo)
    try {
      final result = _evaluateExpression(expr);
      return result.toString();
    } catch (e) {
      return 'Error';
    }
  }
  
  double _evaluateExpression(String expression) {
    // Handle scientific functions
    if (expression.contains('sin(')) {
      final start = expression.indexOf('sin(') + 4;
      final end = expression.indexOf(')', start);
      final value = double.parse(expression.substring(start, end));
      final angle = _angleMode == 'DEG' ? value * pi / 180 : (_angleMode == 'GRAD' ? value * pi / 200 : value);
      final result = sin(angle);
      return result;
    } else if (expression.contains('cos(')) {
      final start = expression.indexOf('cos(') + 4;
      final end = expression.indexOf(')', start);
      final value = double.parse(expression.substring(start, end));
      final angle = _angleMode == 'DEG' ? value * pi / 180 : (_angleMode == 'GRAD' ? value * pi / 200 : value);
      final result = cos(angle);
      return result;
    } else if (expression.contains('tan(')) {
      final start = expression.indexOf('tan(') + 4;
      final end = expression.indexOf(')', start);
      final value = double.parse(expression.substring(start, end));
      final angle = _angleMode == 'DEG' ? value * pi / 180 : (_angleMode == 'GRAD' ? value * pi / 200 : value);
      final result = tan(angle);
      return result;
    } else if (expression.contains('sqrt(')) {
      final start = expression.indexOf('sqrt(') + 5;
      final end = expression.indexOf(')', start);
      final value = double.parse(expression.substring(start, end));
      return sqrt(value);
    } else if (expression.contains('log(')) {
      final start = expression.indexOf('log(') + 4;
      final end = expression.indexOf(')', start);
      final value = double.parse(expression.substring(start, end));
      return log(value);
    } else if (expression.contains('ln(')) {
      final start = expression.indexOf('ln(') + 3;
      final end = expression.indexOf(')', start);
      final value = double.parse(expression.substring(start, end));
      return log(value);
    }
    
    // Simple arithmetic
    final parts = expression.split(RegExp(r'[+\-*/]'));
    if (parts.length == 2) {
      final a = double.parse(parts[0]);
      final b = double.parse(parts[1]);
      if (expression.contains('+')) return a + b;
      if (expression.contains('-')) return a - b;
      if (expression.contains('*')) return a * b;
      if (expression.contains('/')) return a / b;
    }
    
    return double.parse(expression);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Calculator', style: TextStyle(color: Color(0xFF00BCD4))),
            const Spacer(),
            Switch(
              value: _isScientific,
              onChanged: (v) => setState(() => _isScientific = v),
              activeColor: const Color(0xFF00BCD4),
            ),
            const Text('Sci', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF00BCD4)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('History: $_history'), backgroundColor: const Color(0xFF00BCD4)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_history.isNotEmpty)
                    Text(
                      _history,
                      style: const TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _expression.isEmpty ? '0' : _expression,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
                    ),
                  ),
                  if (_result.isNotEmpty)
                    Text(
                      '= $_result',
                      style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Memory Row
            if (_isScientific)
              Row(
                children: [
                  _buildButton('MC', Colors.grey[700]!),
                  const SizedBox(width: 8),
                  _buildButton('MR', Colors.grey[700]!),
                  const SizedBox(width: 8),
                  _buildButton('M+', Colors.grey[700]!),
                  const SizedBox(width: 8),
                  _buildButton('M-', Colors.grey[700]!),
                  const SizedBox(width: 8),
                  _buildButton('C', Colors.red),
                ],
              ),
            
            const SizedBox(height: 8),
            
            // Scientific Functions Row
            if (_isScientific)
              Row(
                children: [
                  _buildButton('sin', Colors.purple),
                  const SizedBox(width: 8),
                  _buildButton('cos', Colors.purple),
                  const SizedBox(width: 8),
                  _buildButton('tan', Colors.purple),
                  const SizedBox(width: 8),
                  _buildButton('log', Colors.purple),
                  const SizedBox(width: 8),
                  _buildButton('ln', Colors.purple),
                ],
              ),
            
            if (_isScientific) const SizedBox(height: 8),
            
            if (_isScientific)
              Row(
                children: [
                  _buildButton('sqrt', Colors.purple),
                  const SizedBox(width: 8),
                  _buildButton('^', Colors.purple),
                  const SizedBox(width: 8),
                  _buildButton('π', Colors.purple),
                  const SizedBox(width: 8),
                  _buildButton('e', Colors.purple),
                  const SizedBox(width: 8),
                  _buildButton('CE', Colors.orange),
                ],
              ),
            
            if (_isScientific) const SizedBox(height: 8),
            
            // Angle Mode
            if (_isScientific)
              Row(
                children: [
                  _buildAngleButton('DEG'),
                  const SizedBox(width: 8),
                  _buildAngleButton('RAD'),
                  const SizedBox(width: 8),
                  _buildAngleButton('GRAD'),
                  const Spacer(),
                ],
              ),
            
            const SizedBox(height: 8),
            
            // Number Pad
            Row(
              children: [
                _buildButton('7', Colors.white),
                const SizedBox(width: 8),
                _buildButton('8', Colors.white),
                const SizedBox(width: 8),
                _buildButton('9', Colors.white),
                const SizedBox(width: 8),
                _buildButton('/', Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildButton('4', Colors.white),
                const SizedBox(width: 8),
                _buildButton('5', Colors.white),
                const SizedBox(width: 8),
                _buildButton('6', Colors.white),
                const SizedBox(width: 8),
                _buildButton('*', Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildButton('1', Colors.white),
                const SizedBox(width: 8),
                _buildButton('2', Colors.white),
                const SizedBox(width: 8),
                _buildButton('3', Colors.white),
                const SizedBox(width: 8),
                _buildButton('-', Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildButton('0', Colors.white),
                const SizedBox(width: 8),
                _buildButton('.', Colors.white),
                const SizedBox(width: 8),
                _buildButton('=', const Color(0xFF00BCD4)),
                const SizedBox(width: 8),
                _buildButton('+', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildButton(String text, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onButtonPressed(text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAngleButton(String mode) {
    final isSelected = _angleMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _angleMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00BCD4) : Colors.white24,
            ),
          ),
          child: Center(
            child: Text(
              mode,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00BCD4) : Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
