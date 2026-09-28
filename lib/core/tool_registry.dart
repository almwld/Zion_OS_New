import 'package:flutter/material.dart';

class ToolRegistry {
  static final ToolRegistry _instance = ToolRegistry._internal();
  factory ToolRegistry() => _instance;
  ToolRegistry._internal();

  final Map<String, ToolEntry> _tools = {};

  void registerTool(String name, ToolEntry tool) {
    _tools[name] = tool;
  }

  ToolEntry? getTool(String name) {
    return _tools[name];
  }

  List<String> getToolNames() {
    return _tools.keys.toList();
  }

  Map<String, ToolEntry> getAllTools() {
    return Map.from(_tools);
  }
}

class ToolEntry {
  final String name;
  final String description;
  final IconData icon;
  final Function execute;

  ToolEntry({
    required this.name,
    required this.description,
    required this.icon,
    required this.execute,
  });
}
