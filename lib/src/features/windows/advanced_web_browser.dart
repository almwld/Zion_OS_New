import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdvancedWebBrowser extends StatefulWidget {
  const AdvancedWebBrowser({super.key});

  @override
  State<AdvancedWebBrowser> createState() => _AdvancedWebBrowserState();
}

class _AdvancedWebBrowserState extends State<AdvancedWebBrowser> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://www.google.com');

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Web Browser', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
                  onPressed: () => _controller.goBack(),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF00FF41)),
                  onPressed: () => _controller.goForward(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00FF41)),
                  onPressed: () => _controller.reload(),
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Color(0xFF00FF41)),
                    decoration: const InputDecoration(
                      hintText: 'Enter URL',
                      hintStyle: TextStyle(color: Color(0xFF00FF41)),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (url) {
                      _controller.loadRequest(Uri.parse(url));
                    },
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
