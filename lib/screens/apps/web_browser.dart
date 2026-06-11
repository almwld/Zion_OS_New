import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebBrowserApp extends StatefulWidget {
  const WebBrowserApp({super.key});

  @override
  State<WebBrowserApp> createState() => _WebBrowserAppState();
}

class _WebBrowserAppState extends State<WebBrowserApp> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://www.google.com');
  bool _isLoading = true;
  String _currentUrl = 'https://www.google.com';
  String _pageTitle = 'Browser';
  
  // Bookmark and History
  List<Map<String, String>> _bookmarks = [];
  List<Map<String, String>> _history = [];
  bool _showBookmarks = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _initWebView();
  }

  void _loadSavedData() {
    // Load bookmarks and history from shared preferences (simplified)
    _bookmarks = [
      {'title': 'Google', 'url': 'https://www.google.com'},
      {'title': 'GitHub', 'url': 'https://github.com'},
      {'title': 'Zion OS', 'url': 'https://zion-os.com'},
    ];
    _history = [
      {'title': 'Google', 'url': 'https://www.google.com', 'time': 'Just now'},
      {'title': 'Flutter', 'url': 'https://flutter.dev', 'time': '5 min ago'},
    ];
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
              _urlController.text = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            _controller.getTitle().then((title) {
              if (title != null && mounted) {
                setState(() => _pageTitle = title);
                // Add to history
                _addToHistory(title, url);
              }
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  void _addToHistory(String title, String url) {
    _history.insert(0, {
      'title': title,
      'url': url,
      'time': 'Just now',
    });
    if (_history.length > 50) _history = _history.sublist(0, 50);
  }

  void _loadUrl() {
    String url = _urlController.text.trim();
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    _controller.loadRequest(Uri.parse(url));
    FocusScope.of(context).unfocus();
  }

  void _addBookmark() {
    setState(() {
      _bookmarks.add({
        'title': _pageTitle,
        'url': _currentUrl,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark added'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  void _removeBookmark(int index) {
    setState(() {
      _bookmarks.removeAt(index);
    });
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_pageTitle, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Color(0xFF00BCD4)),
            onPressed: _addBookmark,
            tooltip: 'Add bookmark',
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks, color: Color(0xFF00BCD4)),
            onPressed: () => setState(() {
              _showBookmarks = !_showBookmarks;
              _showHistory = false;
            }),
            tooltip: 'Bookmarks',
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF00BCD4)),
            onPressed: () => setState(() {
              _showHistory = !_showHistory;
              _showBookmarks = false;
            }),
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              // Address Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4), size: 20),
                      onPressed: () => _controller.goBack(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Color(0xFF00BCD4), size: 20),
                      onPressed: () => _controller.goForward(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 13),
                        onSubmitted: (_) => _loadUrl(),
                        decoration: InputDecoration(
                          hintText: 'Enter URL...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00BCD4)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          
          // Bookmarks Panel
          if (_showBookmarks)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 300,
              child: Container(
                color: Colors.black.withOpacity(0.95),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: const Color(0xFF00BCD4).withOpacity(0.3))),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bookmarks', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _bookmarks.isEmpty
                          ? const Center(child: Text('No bookmarks', style: TextStyle(color: Colors.white38)))
                          : ListView.builder(
                              itemCount: _bookmarks.length,
                              itemBuilder: (context, index) {
                                final bookmark = _bookmarks[index];
                                return ListTile(
                                  leading: const Icon(Icons.bookmark, color: Color(0xFF00BCD4), size: 20),
                                  title: Text(bookmark['title']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  subtitle: Text(bookmark['url']!, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                    onPressed: () => _removeBookmark(index),
                                  ),
                                  onTap: () {
                                    _urlController.text = bookmark['url']!;
                                    _loadUrl();
                                    setState(() => _showBookmarks = false);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          
          // History Panel
          if (_showHistory)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 300,
              child: Container(
                color: Colors.black.withOpacity(0.95),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: const Color(0xFF00BCD4).withOpacity(0.3))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('History', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: _clearHistory,
                            child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _history.isEmpty
                          ? const Center(child: Text('No history', style: TextStyle(color: Colors.white38)))
                          : ListView.builder(
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final item = _history[index];
                                return ListTile(
                                  leading: const Icon(Icons.history, color: Color(0xFF00BCD4), size: 20),
                                  title: Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  subtitle: Text(item['url']!, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                  trailing: Text(item['time']!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  onTap: () {
                                    _urlController.text = item['url']!;
                                    _loadUrl();
                                    setState(() => _showHistory = false);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
