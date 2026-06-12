import 'package:flutter/material.dart';

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();
  
  final List<Map<String, dynamic>> _errorLog = [];
  
  void handleError(Object error, StackTrace stackTrace, {String? context}) {
    final errorEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'context': context ?? 'unknown',
    };
    
    _errorLog.add(errorEntry);
    
    // Keep only last 100 errors
    if (_errorLog.length > 100) _errorLog.removeAt(0);
    
    print('❌ Error: $error');
  }
  
  List<Map<String, dynamic>> getErrorLog() => List.from(_errorLog);
  
  void clearErrorLog() => _errorLog.clear();
  
  Widget buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4)),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
