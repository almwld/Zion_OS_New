import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class NetworkToolsApp extends StatefulWidget {
  const NetworkToolsApp({super.key});

  @override
  State<NetworkToolsApp> createState() => _NetworkToolsAppState();
}

class _NetworkToolsAppState extends State<NetworkToolsApp> {
  String _gateway = "";
  String _dnsServers = "";
  int _selectedTool = 0;
  
  // DNS Lookup
  final TextEditingController _dnsController = TextEditingController();
  String _dnsResult = '';
  bool _isDnsLookup = false;
  
  // Traceroute
  final TextEditingController _traceController = TextEditingController();
  String _traceResult = '';
  bool _isTracing = false;
  
  // Whois
  final TextEditingController _whoisController = TextEditingController();
  String _whoisResult = '';
  bool _isWhois = false;
  
  // IP Info
  String _ipInfo = '';
  bool _isIpInfo = false;
  
  final List<String> _tools = ['DNS Lookup', 'Traceroute', 'Whois', 'IP Info'];

  Future<void> _dnsLookup() async {
    final host = _dnsController.text.trim();
    if (host.isEmpty) return;
    
    setState(() {
      _isDnsLookup = true;
      _dnsResult = 'Looking up $host...';
    });
    
    try {
      final result = await Process.run('nslookup', [host], runInShell: true);
      setState(() {
        _dnsResult = result.stdout.toString();
        _isDnsLookup = false;
      });
    } catch (e) {
      setState(() {
        _dnsResult = 'Error: $e';
        _isDnsLookup = false;
      });
    }
  }

  Future<void> _traceroute() async {
    final host = _traceController.text.trim();
    if (host.isEmpty) return;
    
    setState(() {
      _isTracing = true;
      _traceResult = 'Tracing route to $host...\n';
    });
    
    try {
      final result = await Process.run('traceroute', ['-n', '-m', '15', host], runInShell: true);
      setState(() {
        _traceResult = result.stdout.toString();
        _isTracing = false;
      });
    } catch (e) {
      setState(() {
        _traceResult = 'Error: $e\nTry: traceroute not available';
        _isTracing = false;
      });
    }
  }

  Future<void> _whois() async {
    final domain = _whoisController.text.trim();
    if (domain.isEmpty) return;
    
    setState(() {
      _isWhois = true;
      _whoisResult = 'Looking up $domain...';
    });
    
    try {
      final result = await Process.run('whois', [domain], runInShell: true);
      setState(() {
        _whoisResult = result.stdout.toString();
        _isWhois = false;
      });
    } catch (e) {
      setState(() {
        _whoisResult = 'Error: $e';
        _isWhois = false;
      });
    }
  }

  Future<void> _getIpInfo() async {
    setState(() {
      _isIpInfo = true;
      _ipInfo = 'Getting IP information...';
    });
    
    try {
      // Get local IP
      final localIpResult = await Process.run('ip', ['route', 'get', '1'], runInShell: true);
      final localIpMatch = RegExp(r'src (\d+\.\d+\.\d+\.\d+)').firstMatch(localIpResult.stdout.toString());
      final localIp = localIpMatch?.group(1) ?? 'Unknown';
      
      // Get public IP (simulated)
      final publicIp = 'Simulated - Use external API';
      
      setState(() {
        _ipInfo = '''
╔══════════════════════════════════════════════════════════════╗
║                        IP INFORMATION                        ║
╠══════════════════════════════════════════════════════════════╣
║ Local IP: $localIp
║ Public IP: $publicIp
║ Gateway: ${_gateway}
║ DNS Servers: ${_dnsServers}
╚══════════════════════════════════════════════════════════════╝
''';
        _isIpInfo = false;
      });
    } catch (e) {
      setState(() {
        _ipInfo = 'Error: $e';
        _isIpInfo = false;
      });
    }
  }

  Future<String> _getGateway() async {
    try {
      final result = await Process.run('ip', ['route', 'show', 'default'], runInShell: true);
      final match = RegExp(r'via (\d+\.\d+\.\d+\.\d+)').firstMatch(result.stdout.toString());
      return match?.group(1) ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<String> _getDnsServers() async {
    try {
      final result = await Process.run('cat', ['/etc/resolv.conf'], runInShell: true);
      final matches = RegExp(r'nameserver (\d+\.\d+\.\d+\.\d+)').allMatches(result.stdout.toString());
      return matches.map((m) => m.group(1)).join(', ');
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Network Tools', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedTool = index),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: _tools.map((tool) => Tab(text: tool)).toList(),
        ),
      ),
      body: IndexedStack(
        index: _selectedTool,
        children: [
          _buildDnsTab(),
          _buildTracerouteTab(),
          _buildWhoisTab(),
          _buildIpInfoTab(),
        ],
      ),
    );
  }

  Widget _buildDnsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.dns, color: Color(0xFF00BCD4)),
                    SizedBox(width: 8),
                    Text('DNS Lookup', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dnsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter domain (e.g., google.com)',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isDnsLookup ? null : _dnsLookup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                  ),
                  child: _isDnsLookup
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Lookup DNS'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _dnsResult.isEmpty ? 'Enter a domain and click Lookup DNS' : _dnsResult,
                  style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracerouteTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.route, color: Color(0xFF00BCD4)),
                    SizedBox(width: 8),
                    Text('Traceroute', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _traceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter host (e.g., google.com)',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isTracing ? null : _traceroute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                  ),
                  child: _isTracing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Start Trace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _traceResult.isEmpty ? 'Enter a host and click Start Trace' : _traceResult,
                  style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoisTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF00BCD4)),
                    SizedBox(width: 8),
                    Text('Whois Lookup', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _whoisController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter domain (e.g., google.com)',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isWhois ? null : _whois,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                  ),
                  child: _isWhois
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Lookup Whois'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _whoisResult.isEmpty ? 'Enter a domain and click Lookup Whois' : _whoisResult,
                  style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.network_wifi, color: Color(0xFF00BCD4)),
                    SizedBox(width: 8),
                    Text('IP Information', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isIpInfo ? null : _getIpInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                  ),
                  child: _isIpInfo
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Get IP Info'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _ipInfo.isEmpty ? 'Click Get IP Info' : _ipInfo,
                  style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// إضافة المتغيرات المفقودة
String _gateway = '';
String _dnsServers = '';

// في دالة _getIpInfo، قم بتعيين هذه المتغيرات
// نضيف هذا الكود داخل الدالة قبل استخدامها
// يمكن إضافة سطرين في بداية _getIpInfo:
// _gateway = await _getGateway().then((v) => _gateway = v);
// _dnsServers = await _getDnsServers().then((v) => _dnsServers = v);
