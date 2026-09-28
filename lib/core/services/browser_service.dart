import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BrowserService {
  static final BrowserService _instance = BrowserService._internal();
  factory BrowserService() => _instance;
  BrowserService._internal();
  
  List<Map<String, dynamic>> _bookmarks = [];
  List<Map<String, dynamic>> _history = [];
  
  Future<void> init() async {
    await _loadBookmarks();
    await _loadHistory();
  }
  
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString('bookmarks');
    if (bookmarksJson != null) {
      try {
        _bookmarks = List<Map<String, dynamic>>.from(jsonDecode(bookmarksJson));
      } catch (_) {}
    }
  }
  
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('browser_history');
    if (historyJson != null) {
      try {
        _history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      } catch (_) {}
    }
  }
  
  Future<void> addBookmark(String title, String url) async {
    _bookmarks.insert(0, {
      'title': title,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _saveBookmarks();
  }
  
  Future<void> removeBookmark(String url) async {
    _bookmarks.removeWhere((b) => b['url'] == url);
    await _saveBookmarks();
  }
  
  Future<void> addToHistory(String title, String url) async {
    _history.insert(0, {
      'title': title,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (_history.length > 100) {
      _history = _history.sublist(0, 100);
    }
    
    await _saveHistory();
  }
  
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }
  
  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookmarks', jsonEncode(_bookmarks));
  }
  
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('browser_history', jsonEncode(_history));
  }
  
  List<Map<String, dynamic>> getBookmarks() => List.from(_bookmarks);
  List<Map<String, dynamic>> getHistory() => List.from(_history);
}
