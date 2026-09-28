import 'package:flutter/material.dart';

class ZionPlugin {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  bool enabled;
  bool installed;

  ZionPlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    this.enabled = true,
    this.installed = true,
  });
}

class ZionPluginSystem extends ChangeNotifier {
  final List<ZionPlugin> _plugins = [
    ZionPlugin(id: 'wifi_pineapple', name: 'WiFi Pineapple', description: 'محاكاة جهاز WiFi Pineapple', version: '2.1.0', author: 'Hak5'),
    ZionPlugin(id: 'bettercap', name: 'Bettercap', description: 'إطار هجوم MITM متكامل', version: '2.32.0', author: 'Bettercap Team'),
    ZionPlugin(id: 'beef', name: 'BeEF', description: 'إطار استغلال المتصفح', version: '1.0.0', author: 'BeEF Team'),
    ZionPlugin(id: 'covenant', name: 'Covenant', description: 'إطار C2 للفريق الأحمر', version: '0.6.0', author: 'Covenant Team'),
  ];

  final List<ZionPlugin> _availablePlugins = [
    ZionPlugin(id: 'empire', name: 'Empire', description: 'إطار ما بعد الاستغلال', version: '5.0.0', author: 'BC Security', installed: false),
    ZionPlugin(id: 'powershell_empire', name: 'PowerShell Empire', description: 'إطار PowerShell للاختراق', version: '4.8.0', author: 'HarmJ0y', installed: false),
  ];

  List<ZionPlugin> get plugins => _plugins;
  List<ZionPlugin> get availablePlugins => _availablePlugins;

  void togglePlugin(String id) {
    final plugin = _plugins.firstWhere((p) => p.id == id);
    plugin.enabled = !plugin.enabled;
    notifyListeners();
  }

  void installPlugin(String id) {
    final plugin = _availablePlugins.firstWhere((p) => p.id == id);
    plugin.installed = true;
    _plugins.add(plugin);
    _availablePlugins.remove(plugin);
    notifyListeners();
  }

  void uninstallPlugin(String id) {
    final plugin = _plugins.firstWhere((p) => p.id == id);
    plugin.installed = false;
    plugin.enabled = false;
    _availablePlugins.add(plugin);
    _plugins.remove(plugin);
    notifyListeners();
  }
}
