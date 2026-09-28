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

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _urlController.text = url;
          },
          onPageFinished: (url) => setState(() => _isLoading = false),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Web Browser', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
                  onPressed: () => _controller.goBack(),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF00BCD4)),
                  onPressed: () => _controller.goForward(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
                  onPressed: () => _controller.reload(),
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Color(0xFF00BCD4)),
                    onSubmitted: (_) => _loadUrl(),
                    decoration: InputDecoration(
                      hintText: 'Enter URL',
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
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
