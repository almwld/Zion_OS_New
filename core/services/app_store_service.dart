import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStoreService {
  static final AppStoreService _instance = AppStoreService._internal();
  factory AppStoreService() => _instance;
  AppStoreService._internal();
  
  List<Map<String, dynamic>> _installedApps = [];
  List<Map<String, dynamic>> _availableApps = [];
  
  final List<Map<String, dynamic>> _defaultApps = [
    {
      'id': 'terminal',
      'name': 'Terminal',
      'icon': 'terminal',
      'description': 'Advanced terminal emulator with full command support',
      'version': '2.0.0',
      'size': '2.5 MB',
      'category': 'Tools',
      'rating': 4.8,
      'downloads': '15K+',
      'installed': true,
    },
    {
      'id': 'network_scanner',
      'name': 'Network Scanner',
      'icon': 'network_wifi',
      'description': 'Scan networks, ports and discover devices',
      'version': '1.5.0',
      'size': '1.8 MB',
      'category': 'Security',
      'rating': 4.9,
      'downloads': '12K+',
      'installed': true,
    },
    {
      'id': 'wifi_scanner',
      'name': 'WiFi Scanner',
      'icon': 'wifi',
      'description': 'Scan and analyze WiFi networks',
      'version': '1.3.0',
      'size': '1.2 MB',
      'category': 'Security',
      'rating': 4.7,
      'downloads': '10K+',
      'installed': true,
    },
    {
      'id': 'crypto_tool',
      'name': 'Crypto Tool',
      'icon': 'lock',
      'description': 'Encryption and hashing tools',
      'version': '1.2.0',
      'size': '1.5 MB',
      'category': 'Security',
      'rating': 4.8,
      'downloads': '8K+',
      'installed': true,
    },
    {
      'id': 'password_cracker',
      'name': 'Password Cracker',
      'icon': 'vpn_key',
      'description': 'Advanced password recovery tool',
      'version': '1.1.0',
      'size': '2.1 MB',
      'category': 'Security',
      'rating': 4.6,
      'downloads': '7K+',
      'installed': true,
    },
    {
      'id': 'ddos_tool',
      'name': 'DDoS Tool',
      'icon': 'speed',
      'description': 'Network stress testing tool',
      'version': '1.0.0',
      'size': '1.9 MB',
      'category': 'Security',
      'rating': 4.5,
      'downloads': '5K+',
      'installed': true,
    },
    {
      'id': 'forensics',
      'name': 'Forensics Tool',
      'icon': 'search',
      'description': 'Digital forensics and analysis',
      'version': '1.0.0',
      'size': '2.3 MB',
      'category': 'Security',
      'rating': 4.7,
      'downloads': '4K+',
      'installed': true,
    },
    {
      'id': 'database_hacker',
      'name': 'Database Hacker',
      'icon': 'storage',
      'description': 'Database security testing',
      'version': '1.0.0',
      'size': '1.6 MB',
      'category': 'Security',
      'rating': 4.4,
      'downloads': '3K+',
      'installed': true,
    },
    {
      'id': 'cloud_attacker',
      'name': 'Cloud Attacker',
      'icon': 'cloud',
      'description': 'Cloud security assessment',
      'version': '1.0.0',
      'size': '1.7 MB',
      'category': 'Security',
      'rating': 4.3,
      'downloads': '2K+',
      'installed': true,
    },
    {
      'id': 'stealth_mode',
      'name': 'Stealth Mode',
      'icon': 'visibility_off',
      'description': 'Hide your activities',
      'version': '1.1.0',
      'size': '1.1 MB',
      'category': 'Privacy',
      'rating': 4.9,
      'downloads': '11K+',
      'installed': true,
    },
  ];
  
  Future<void> init() async {
    await _loadInstalledApps();
    await _loadAvailableApps();
  }
  
  Future<void> _loadInstalledApps() async {
    final prefs = await SharedPreferences.getInstance();
    final installedJson = prefs.getString('installed_apps');
    if (installedJson != null) {
      try {
        _installedApps = List<Map<String, dynamic>>.from(jsonDecode(installedJson));
      } catch (_) {}
    }
    
    if (_installedApps.isEmpty) {
      _installedApps = List.from(_defaultApps.where((app) => app['installed'] == true));
      await _saveInstalledApps();
    }
  }
  
  Future<void> _loadAvailableApps() async {
    _availableApps = List.from(_defaultApps);
    final prefs = await SharedPreferences.getInstance();
    final availableJson = prefs.getString('available_apps');
    if (availableJson != null) {
      try {
        _availableApps = List<Map<String, dynamic>>.from(jsonDecode(availableJson));
      } catch (_) {}
    } else {
      await _saveAvailableApps();
    }
  }
  
  Future<void> _saveInstalledApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('installed_apps', jsonEncode(_installedApps));
  }
  
  Future<void> _saveAvailableApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('available_apps', jsonEncode(_availableApps));
  }
  
  List<Map<String, dynamic>> getInstalledApps() => List.from(_installedApps);
  
  List<Map<String, dynamic>> getAvailableApps() => List.from(_availableApps.where((app) => !app['installed']));
  
  Future<void> installApp(String appId) async {
    final app = _defaultApps.firstWhere((a) => a['id'] == appId);
    app['installed'] = true;
    _installedApps.add(app);
    await _saveInstalledApps();
    await _saveAvailableApps();
  }
  
  Future<void> uninstallApp(String appId) async {
    _installedApps.removeWhere((app) => app['id'] == appId);
    final app = _defaultApps.firstWhere((a) => a['id'] == appId);
    app['installed'] = false;
    await _saveInstalledApps();
    await _saveAvailableApps();
  }
  
  List<Map<String, dynamic>> searchApps(String query) {
    final results = _defaultApps.where((app) =>
      app['name'].toLowerCase().contains(query.toLowerCase()) ||
      app['description'].toLowerCase().contains(query.toLowerCase()) ||
      app['category'].toLowerCase().contains(query.toLowerCase())
    ).toList();
    return results;
  }
  
  Map<String, dynamic> getAppDetails(String appId) {
    return _defaultApps.firstWhere((app) => app['id'] == appId);
  }
}
