import 'package:flutter/material.dart';

/// ToolCategory - Enum representing different categories of tools
enum ToolCategory {
  network('أدوات الشبكة', Icons.network_check, Color(0xFF00E676)),
  crypto('أدوات التشفير', Icons.security, Color(0xFFFFAB70)),
  web('أدوات الويب', Icons.web, Color(0xFF79C0FF)),
  forensics('أدوات الطب الشرعي', Icons.search, Color(0xFFF778BA)),
  exploitation('أدوات الاختراق', Icons.bug_report, Color(0xFFF85149)),
  sniffing('أدوات التنصت', Icons.wifi_tethering, Color(0xFFD2A8FF)),
  system('أدوات النظام', Icons.computer, Color(0xFF56D4DD));

  final String arabicName;
  final IconData icon;
  final Color color;

  const ToolCategory(this.arabicName, this.icon, this.color);
}

/// Tool - Model representing a single tool in the system
/// Each tool has a unique ID, name, description, category, and execution metadata
class Tool {
  final String id;
  final String name;
  final String arabicName;
  final String description;
  final String arabicDescription;
  final ToolCategory category;
  final IconData icon;
  final String route;
  final Map<String, dynamic>? parameters;
  final bool requiresRoot;
  final bool isImplemented;

  const Tool({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.description,
    required this.arabicDescription,
    required this.category,
    required this.icon,
    required this.route,
    this.parameters,
    this.requiresRoot = false,
    this.isImplemented = true,
  });

  /// Creates a copy of this tool with modified fields
  Tool copyWith({
    String? id,
    String? name,
    String? arabicName,
    String? description,
    String? arabicDescription,
    ToolCategory? category,
    IconData? icon,
    String? route,
    Map<String, dynamic>? parameters,
    bool? requiresRoot,
    bool? isImplemented,
  }) {
    return Tool(
      id: id ?? this.id,
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      description: description ?? this.description,
      arabicDescription: arabicDescription ?? this.arabicDescription,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      parameters: parameters ?? this.parameters,
      requiresRoot: requiresRoot ?? this.requiresRoot,
      isImplemented: isImplemented ?? this.isImplemented,
    );
  }

  @override
  String toString() => 'Tool(id: $id, name: $name, category: ${category.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Tool && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// ToolResult - Model representing the result of a tool execution
class ToolResult {
  final String toolId;
  final DateTime timestamp;
  final bool success;
  final String output;
  final String? error;
  final Duration executionTime;
  final Map<String, dynamic>? metadata;

  ToolResult({
    required this.toolId,
    required this.timestamp,
    required this.success,
    required this.output,
    this.error,
    required this.executionTime,
    this.metadata,
  });

  /// Converts the result to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'tool_id': toolId,
      'timestamp': timestamp.toIso8601String(),
      'success': success ? 1 : 0,
      'output': output,
      'error': error,
      'execution_time_ms': executionTime.inMilliseconds,
      'metadata': metadata?.toString(),
    };
  }

  /// Creates a ToolResult from a database map
  factory ToolResult.fromMap(Map<String, dynamic> map) {
    return ToolResult(
      toolId: map['tool_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      success: map['success'] == 1,
      output: map['output'] as String,
      error: map['error'] as String?,
      executionTime: Duration(milliseconds: map['execution_time_ms'] as int),
    );
  }
}
