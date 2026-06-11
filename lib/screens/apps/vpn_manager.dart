import 'package:flutter/material.dart';

class VPNManagerApp extends StatefulWidget {
  const VPNManagerApp({super.key});

  @override
  State<VPNManagerApp> createState() => _VPNManagerAppState();
}

class _VPNManagerAppState extends State<VPNManagerApp> {
  bool _vpnConnected = false;
  String _selectedServer = 'Auto';
  String _vpnStatus = 'Disconnected';
  String _vpnLocation = 'Not connected';
  String _vpnIP = '0.0.0.0';
  double _dataSent = 0;
  double _dataReceived = 0;
  
  final List<Map<String, dynamic>> _servers = [
    {'name': 'Auto (Fastest)', 'country': 'Auto', 'flag': '🌐', 'latency': '25 ms'},
    {'name': 'USA - New York', 'country': 'United States', 'flag': '🇺🇸', 'latency': '45 ms'},
    {'name': 'UK - London', 'country': 'United Kingdom', 'flag': '🇬🇧', 'latency': '52 ms'},
    {'name': 'Germany - Frankfurt', 'country': 'Germany', 'flag': '🇩🇪', 'latency': '48 ms'},
    {'name': 'Japan - Tokyo', 'country': 'Japan', 'flag': '🇯🇵', 'latency': '120 ms'},
    {'name': 'Singapore', 'country': 'Singapore', 'flag': '🇸🇬', 'latency': '95 ms'},
    {'name': 'Canada - Toronto', 'country': 'Canada', 'flag': '🇨🇦', 'latency': '58 ms'},
    {'name': 'Australia - Sydney', 'country': 'Australia', 'flag': '🇦🇺', 'latency': '180 ms'},
    {'name': 'France - Paris', 'country': 'France', 'flag': '🇫🇷', 'latency': '55 ms'},
    {'name': 'Netherlands', 'country': 'Netherlands', 'flag': '🇳🇱', 'latency': '50 ms'},
  ];

  final List<Map<String, dynamic>> _protocols = [
    {'name': 'WireGuard', 'recommended': true, 'speed': 'Fast', 'security': 'High'},
    {'name': 'OpenVPN (UDP)', 'recommended': false, 'speed': 'Medium', 'security': 'High'},
    {'name': 'OpenVPN (TCP)', 'recommended': false, 'speed': 'Medium', 'security': 'High'},
    {'name': 'IKEv2', 'recommended': false, 'speed': 'Fast', 'security': 'Medium'},
  ];
  
  String _selectedProtocol = 'WireGuard';
  bool _killSwitch = true;
  bool _autoConnect = true;

  void _connectVPN() {
    setState(() {
      _vpnConnected = true;
      _vpnStatus = 'Connecting...';
      _vpnLocation = _selectedServer == 'Auto (Fastest)' ? 'USA - New York' : _selectedServer;
      _vpnIP = '185.142.53.24';
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _vpnStatus = 'Connected';
        _vpnConnected = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VPN Connected'), backgroundColor: Color(0xFF00BCD4)),
      );
    });
  }

  void _disconnectVPN() {
    setState(() {
      _vpnConnected = false;
      _vpnStatus = 'Disconnected';
      _vpnLocation = 'Not connected';
      _vpnIP = '0.0.0.0';
      _dataSent = 0;
      _dataReceived = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('VPN Disconnected'), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('VPN Manager', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // VPN Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _vpnConnected 
                      ? [Colors.green, Colors.green.withOpacity(0.7)]
                      : [const Color(0xFF00BCD4), const Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    _vpnConnected ? Icons.vpn_key : Icons.vpn_lock,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _vpnConnected ? 'PROTECTED' : 'NOT PROTECTED',
                    style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _vpnStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _vpnConnected ? _disconnectVPN : _connectVPN,
                      icon: Icon(_vpnConnected ? Icons.power_settings_new : Icons.play_arrow),
                      label: Text(_vpnConnected ? 'DISCONNECT' : 'CONNECT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _vpnConnected ? Colors.red : const Color(0xFF00BCD4),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Connection Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Location', _vpnLocation),
                  _buildInfoRow('IP Address', _vpnIP),
                  _buildInfoRow('Protocol', _selectedProtocol),
                  _buildInfoRow('Data Sent', '${_dataSent.toStringAsFixed(2)} MB'),
                  _buildInfoRow('Data Received', '${_dataReceived.toStringAsFixed(2)} MB'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Server Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Server', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _servers.length,
                      itemBuilder: (context, index) {
                        final server = _servers[index];
                        final isSelected = _selectedServer == server['name'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedServer = server['name']),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF00BCD4).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF00BCD4)
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(server['flag'], style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(server['name'], style: const TextStyle(color: Colors.white)),
                                      Text(server['country'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text(server['latency'], style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Protocol Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Protocol', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _protocols.map((protocol) => GestureDetector(
                      onTap: () => setState(() => _selectedProtocol = protocol['name']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedProtocol == protocol['name']
                              ? const Color(0xFF00BCD4)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          protocol['name'],
                          style: TextStyle(
                            color: _selectedProtocol == protocol['name'] ? Colors.black : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Kill Switch', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Block internet if VPN disconnects', style: TextStyle(color: Colors.white54)),
                    value: _killSwitch,
                    onChanged: (v) => setState(() => _killSwitch = v),
                    activeColor: const Color(0xFF00BCD4),
                  ),
                  SwitchListTile(
                    title: const Text('Auto Connect', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Automatically connect on app start', style: TextStyle(color: Colors.white54)),
                    value: _autoConnect,
                    onChanged: (v) => setState(() => _autoConnect = v),
                    activeColor: const Color(0xFF00BCD4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
