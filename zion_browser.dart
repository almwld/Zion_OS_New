import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ZionBrowser extends StatefulWidget {
  const ZionBrowser({super.key});

  @override
  State<ZionBrowser> createState() => _ZionBrowserState();
}

class _ZionBrowserState extends State<ZionBrowser> {
  late final WebViewController _controller;
  final TextEditingController _urlCtrl = TextEditingController();
  String _currentUrl = 'https://www.google.com';
  bool _isSecure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() {
            _loading = true;
            _currentUrl = url;
            _isSecure = url.startsWith('https://');
            _urlCtrl.text = url;
          }),
          onPageFinished: (url) => setState(() {
            _loading = false;
            _currentUrl = url;
            _isSecure = url.startsWith('https://');
            _urlCtrl.text = url;
          }),
          onWebResourceError: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
    _urlCtrl.text = _currentUrl;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    var url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return;
    await _controller.loadRequest(uri);
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) await _controller.goBack();
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) await _controller.goForward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E0A),
            border: Border(bottom: BorderSide(color: Color(0xFF1A3A1A))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41), size: 18),
                onPressed: _goBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Color(0xFF00FF41), size: 18),
                onPressed: _goForward,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF00FF41), size: 18),
                onPressed: () => _controller.reload(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              Icon(
                _isSecure ? Icons.lock : Icons.lock_open,
                color: _isSecure ? Colors.green : Colors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onSubmitted: (_) => _navigate(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF00FF41), size: 18),
                onPressed: _navigate,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: WebViewWidget(controller: _controller)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E0A),
            border: Border(top: BorderSide(color: Color(0xFF1A3A1A))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _currentUrl,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF00FF41), fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
              const Text('Zion Browser', style: TextStyle(color: Color(0xFF00FF41), fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
