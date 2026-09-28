import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LibrariesService {
  static final LibrariesService _instance = LibrariesService._internal();
  factory LibrariesService() => _instance;
  LibrariesService._internal();
  
  List<Map<String, dynamic>> _installedLibraries = [];
  List<Map<String, dynamic>> _availableLibraries = [];
  
  final List<Map<String, dynamic>> _defaultLibraries = [
    {
      'id': 'nmap',
      'name': 'Nmap',
      'description': 'Network exploration tool and security scanner',
      'version': '7.94',
      'size': '2.5 MB',
      'category': 'Network',
      'installed': true,
    },
    {
      'id': 'hydra',
      'name': 'Hydra',
      'description': 'Network logon cracker',
      'version': '9.5',
      'size': '1.8 MB',
      'category': 'Security',
      'installed': true,
    },
    {
      'id': 'sqlmap',
      'name': 'SQLMap',
      'description': 'Automatic SQL injection tool',
      'version': '1.7',
      'size': '3.2 MB',
      'category': 'Security',
      'installed': true,
    },
    {
      'id': 'metasploit',
      'name': 'Metasploit',
      'description': 'Penetration testing framework',
      'version': '6.3',
      'size': '45 MB',
      'category': 'Framework',
      'installed': false,
    },
    {
      'id': 'aircrack',
      'name': 'Aircrack-ng',
      'description': 'WiFi security auditing',
      'version': '1.7',
      'size': '4.2 MB',
      'category': 'Wireless',
      'installed': false,
    },
    {
      'id': 'john',
      'name': 'John the Ripper',
      'description': 'Password security auditing',
      'version': '1.9',
      'size': '2.1 MB',
      'category': 'Security',
      'installed': false,
    },
    {
      'id': 'burpsuite',
      'name': 'Burp Suite',
      'description': 'Web vulnerability scanner',
      'version': '2023.12',
      'size': '28 MB',
      'category': 'Web',
      'installed': false,
    },
  ];
  
  Future<void> init() async {
    await _loadInstalledLibraries();
    await _loadAvailableLibraries();
  }
  
  Future<void> _loadInstalledLibraries() async {
    final prefs = await SharedPreferences.getInstance();
    final installedJson = prefs.getString('installed_libraries');
    if (installedJson != null) {
      try {
        _installedLibraries = List<Map<String, dynamic>>.from(jsonDecode(installedJson));
      } catch (_) {}
    }
    
    if (_installedLibraries.isEmpty) {
      _installedLibraries = _defaultLibraries.where((lib) => lib['installed'] == true).toList();
      await _saveInstalledLibraries();
    }
  }
  
  Future<void> _loadAvailableLibraries() async {
    _availableLibraries = List.from(_defaultLibraries);
    final prefs = await SharedPreferences.getInstance();
    final availableJson = prefs.getString('available_libraries');
    if (availableJson != null) {
      try {
        _availableLibraries = List<Map<String, dynamic>>.from(jsonDecode(availableJson));
      } catch (_) {}
    } else {
      await _saveAvailableLibraries();
    }
  }
  
  Future<void> _saveInstalledLibraries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('installed_libraries', jsonEncode(_installedLibraries));
  }
  
  Future<void> _saveAvailableLibraries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('available_libraries', jsonEncode(_availableLibraries));
  }
  
  List<Map<String, dynamic>> getInstalledLibraries() => List.from(_installedLibraries);
  List<Map<String, dynamic>> getAvailableLibraries() => List.from(_availableLibraries.where((lib) => !lib['installed']));
  
  Future<void> installLibrary(String libId) async {
    final lib = _defaultLibraries.firstWhere((l) => l['id'] == libId);
    lib['installed'] = true;
    _installedLibraries.add(lib);
    await _saveInstalledLibraries();
    await _saveAvailableLibraries();
  }
  
  Future<void> uninstallLibrary(String libId) async {
    _installedLibraries.removeWhere((lib) => lib['id'] == libId);
    final lib = _defaultLibraries.firstWhere((l) => l['id'] == libId);
    lib['installed'] = false;
    await _saveInstalledLibraries();
    await _saveAvailableLibraries();
  }
  
  List<Map<String, dynamic>> searchLibraries(String query) {
    final results = _defaultLibraries.where((lib) =>
      lib['name'].toLowerCase().contains(query.toLowerCase()) ||
      lib['description'].toLowerCase().contains(query.toLowerCase())
    ).toList();
    return results;
  }
  
  Map<String, dynamic> getLibraryDetails(String libId) {
    return _defaultLibraries.firstWhere((lib) => lib['id'] == libId);
  }
}

// Helper functions
String jsonEncode(List<Map<String, dynamic>> data) {
  return data.toString();
}

List<Map<String, dynamic>> jsonDecode(String data) {
  return [];
}
