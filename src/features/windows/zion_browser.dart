import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ZionBrowser extends StatefulWidget {
  const ZionBrowser({super.key});

  @override
  State<ZionBrowser> createState() => _ZionBrowserState();
}

class _ZionBrowserState extends State<ZionBrowser> {
  final TextEditingController _urlController = TextEditingController();
  final List<String> _history = [];
  String _currentUrl = 'https://www.google.com';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = _currentUrl;
  }

  Future<void> _loadUrl(String url) async {
    var finalUrl = url;
    if (!url.startsWith('http')) {
      finalUrl = 'https://$url';
    }
    
    setState(() {
      _currentUrl = finalUrl;
      _isLoading = true;
    });
    
    _urlController.text = finalUrl;
    _history.add(finalUrl);
    
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Zion Browser'),
        backgroundColor: Colors.teal.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUrl(_currentUrl),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (_history.length > 1) {
                      _history.removeLast();
                      _loadUrl(_history.last);
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter URL',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.black,
                    ),
                    onSubmitted: _loadUrl,
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.public, color: Colors.teal, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Zion Browser',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter a URL above to browse',
                    style: TextStyle(color: Colors.grey.shade400),
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
