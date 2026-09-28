import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/services/browser_service.dart';

class AdvancedBrowser extends StatefulWidget {
  const AdvancedBrowser({super.key});

  @override
  State<AdvancedBrowser> createState() => _AdvancedBrowserState();
}

class _AdvancedBrowserState extends State<AdvancedBrowser> with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://www.google.com');
  late TabController _tabController;
  
  bool _isLoading = true;
  String _currentUrl = 'https://www.google.com';
  String _pageTitle = 'Browser';
  List<Map<String, dynamic>> _tabs = [];
  int _currentTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initWebView();
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
                final service = Provider.of<BrowserService>(context, listen: false);
                service.addToHistory(title, url);
              }
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.google.com'));
  }
  
  void _loadUrl() {
    String url = _urlController.text.trim();
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    _controller.loadRequest(Uri.parse(url));
    FocusScope.of(context).unfocus();
  }
  
  void _addTab() {
    setState(() {
      _tabs.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': 'New Tab',
        'url': 'https://www.google.com',
      });
      _currentTabIndex = _tabs.length - 1;
    });
  }
  
  void _closeTab(int index) {
    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
      if (_tabs.isEmpty) {
        _addTab();
      }
    });
  }
  
  void _showBookmarks() {
    final service = Provider.of<BrowserService>(context, listen: false);
    final bookmarks = service.getBookmarks();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Bookmarks', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: bookmarks.isEmpty
                  ? const Center(child: Text('No bookmarks', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark = bookmarks[index];
                        return ListTile(
                          leading: const Icon(Icons.bookmark, color: Color(0xFF00BCD4)),
                          title: Text(bookmark['title'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(bookmark['url'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          onTap: () {
                            _urlController.text = bookmark['url'];
                            _loadUrl();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showHistory() {
    final service = Provider.of<BrowserService>(context, listen: false);
    final history = service.getHistory();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('History', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () async {
                    await service.clearHistory();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History cleared'), backgroundColor: Color(0xFF00BCD4)),
                    );
                  },
                  child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('No history', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return ListTile(
                          leading: const Icon(Icons.history, color: Color(0xFF00BCD4)),
                          title: Text(item['title'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(item['url'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          onTap: () {
                            _urlController.text = item['url'];
                            _loadUrl();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _addBookmark() {
    final service = Provider.of<BrowserService>(context, listen: false);
    service.addBookmark(_pageTitle, _currentUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark added'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_pageTitle, style: const TextStyle(color: Color(0xFF00BCD4))),
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
            onPressed: _showBookmarks,
            tooltip: 'Bookmarks',
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF00BCD4)),
            onPressed: _showHistory,
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.tab, color: Color(0xFF00BCD4)),
            onPressed: _addTab,
            tooltip: 'New tab',
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
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4), size: 20),
                      onPressed: () => _controller.reload(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14),
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
              // Tabs Bar
              if (_tabs.isNotEmpty)
                Container(
                  height: 35,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final isSelected = _currentTabIndex == index;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF00BCD4).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              tab['title'].length > 15 ? '${tab['title'].substring(0, 15)}...' : tab['title'],
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF00BCD4) : Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _closeTab(index),
                              child: const Icon(Icons.close, size: 14, color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
