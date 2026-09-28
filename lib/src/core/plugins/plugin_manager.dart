import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PluginManager {
  static final PluginManager _instance = PluginManager._internal();
  factory PluginManager() => _instance;
  PluginManager._internal();

  final Map<String, ZionPlugin> _plugins = {};
  final List<String> _pluginPaths = [];

  Future<void> loadPlugins() async {
    final dir = await getApplicationDocumentsDirectory();
    final pluginsDir = Directory('${dir.path}/plugins');
    
    if (await pluginsDir.exists()) {
      final files = pluginsDir.listSync();
      for (final file in files) {
        if (file.path.endsWith('.zion')) {
          await _loadPlugin(file.path);
        }
      }
    }
    
    print('📦 Loaded ${_plugins.length} plugins');
  }

  Future<void> _loadPlugin(String path) async {
    try {
      final content = await File(path).readAsString();
      final data = jsonDecode(content);
      
      final plugin = ZionPlugin(
        name: data['name'],
        version: data['version'],
        author: data['author'],
        description: data['description'],
        commands: Map<String, String>.from(data['commands'] ?? {}),
      );
      
      _plugins[plugin.name] = plugin;
      _pluginPaths.add(path);
    } catch (e) {
      print('Failed to load plugin $path: $e');
    }
  }

  Future<void> installPlugin(String pluginUrl) async {
    // تنزيل وتثبيت إضافة جديدة
  }

  Future<dynamic> executePluginCommand(String pluginName, String command, Map<String, dynamic> params) async {
    final plugin = _plugins[pluginName];
    if (plugin == null) throw Exception('Plugin not found: $pluginName');
    
    final commandPath = plugin.commands[command];
    if (commandPath == null) throw Exception('Command not found: $command');
    
    return await _execute(commandPath, params);
  }

  Future<dynamic> _execute(String path, Map<String, dynamic> params) async {
    return {'result': 'executed'};
  }

  List<String> getPluginsList() => _plugins.keys.toList();
}

class ZionPlugin {
  final String name;
  final String version;
  final String author;
  final String description;
  final Map<String, String> commands;

  ZionPlugin({
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.commands,
  });
}
