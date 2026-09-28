import 'package:flutter/material.dart';

class FirewallApp extends StatefulWidget {
  const FirewallApp({super.key});

  @override
  State<FirewallApp> createState() => _FirewallAppState();
}

class _FirewallAppState extends State<FirewallApp> {
  bool _firewallEnabled = true;
  bool _blockAllIncoming = true;
  bool _logAttacks = true;
  bool _notifyOnBlock = true;
  int _selectedMode = 0; // 0=Normal, 1=Strict, 2=Stealth
  
  final List<Map<String, dynamic>> _rules = [
    {'id': '1', 'name': 'Allow SSH', 'port': '22', 'protocol': 'TCP', 'action': 'Allow', 'enabled': true},
    {'id': '2', 'name': 'Allow HTTP', 'port': '80', 'protocol': 'TCP', 'action': 'Allow', 'enabled': true},
    {'id': '3', 'name': 'Allow HTTPS', 'port': '443', 'protocol': 'TCP', 'action': 'Allow', 'enabled': true},
    {'id': '4', 'name': 'Block Telnet', 'port': '23', 'protocol': 'TCP', 'action': 'Block', 'enabled': true},
    {'id': '5', 'name': 'Block FTP', 'port': '21', 'protocol': 'TCP', 'action': 'Block', 'enabled': true},
  ];
  
  final List<Map<String, dynamic>> _recentBlocks = [
    {'ip': '192.168.1.105', 'port': '445', 'time': '2 min ago', 'reason': 'SMB Exploit'},
    {'ip': '45.33.22.11', 'port': '22', 'time': '15 min ago', 'reason': 'Brute Force'},
    {'ip': '185.142.53.24', 'port': '3389', 'time': '1 hour ago', 'reason': 'Port Scan'},
    {'ip': '10.0.0.45', 'port': '1433', 'time': '2 hours ago', 'reason': 'SQL Injection'},
  ];

  void _toggleFirewall() {
    setState(() {
      _firewallEnabled = !_firewallEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_firewallEnabled ? 'Firewall enabled' : 'Firewall disabled'),
        backgroundColor: _firewallEnabled ? Colors.green : Colors.red,
      ),
    );
  }

  void _toggleRule(int index) {
    setState(() {
      _rules[index]['enabled'] = !_rules[index]['enabled'];
    });
  }

  void _addRule() {
    final nameController = TextEditingController();
    final portController = TextEditingController();
    String selectedProtocol = 'TCP';
    String selectedAction = 'Allow';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Firewall Rule', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Rule Name',
                    labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: portController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port Number',
                    labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedProtocol,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Color(0xFF00BCD4)),
                  decoration: const InputDecoration(
                    labelText: 'Protocol',
                    labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'TCP', child: Text('TCP')),
                    DropdownMenuItem(value: 'UDP', child: Text('UDP')),
                    DropdownMenuItem(value: 'Both', child: Text('Both')),
                  ],
                  onChanged: (v) => setStateDialog(() => selectedProtocol = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedAction,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Color(0xFF00BCD4)),
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Allow', child: Text('Allow')),
                    DropdownMenuItem(value: 'Block', child: Text('Block')),
                  ],
                  onChanged: (v) => setStateDialog(() => selectedAction = v!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && portController.text.isNotEmpty) {
                setState(() {
                  _rules.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameController.text,
                    'port': portController.text,
                    'protocol': selectedProtocol,
                    'action': selectedAction,
                    'enabled': true,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rule added'), backgroundColor: Color(0xFF00BCD4)),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _deleteRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rule deleted'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Firewall', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF00BCD4)),
            onPressed: _addRule,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Firewall Status Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _firewallEnabled 
                      ? [Colors.green, Colors.green.withOpacity(0.7)]
                      : [Colors.red, Colors.red.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Firewall', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(_firewallEnabled ? 'Protection active' : 'Protection disabled', style: const TextStyle(color: Colors.white70)),
                    value: _firewallEnabled,
                    onChanged: (_) => _toggleFirewall(),
                    activeColor: Colors.white,
                  ),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Rules', _rules.length.toString()),
                      _buildStatItem('Blocks', _recentBlocks.length.toString()),
                      _buildStatItem('Mode', ['Normal', 'Strict', 'Stealth'][_selectedMode]),
                    ],
                  ),
                ],
              ),
            ),
            
            // Security Mode
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeButton('Normal', 0),
                  _buildModeButton('Strict', 1),
                  _buildModeButton('Stealth', 2),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tabs
            const TabBar(
              labelColor: Color(0xFF00BCD4),
              unselectedLabelColor: Colors.white54,
              indicatorColor: Color(0xFF00BCD4),
              tabs: [
                Tab(icon: Icon(Icons.list), text: 'Rules'),
                Tab(icon: Icon(Icons.warning), text: 'Recent Blocks'),
              ],
            ),
            
            Expanded(
              child: TabBarView(
                children: [
                  _buildRulesTab(),
                  _buildRecentBlocksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rules.length,
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rule['action'] == 'Allow' 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rule['action'] == 'Allow' 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  rule['action'] == 'Allow' ? Icons.check : Icons.block,
                  color: rule['action'] == 'Allow' ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Port ${rule['port']} • ${rule['protocol']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: rule['enabled'],
                onChanged: (_) => _toggleRule(index),
                activeColor: rule['action'] == 'Allow' ? Colors.green : Colors.red,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () => _deleteRule(index),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentBlocksTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentBlocks.length,
      itemBuilder: (context, index) {
        final block = _recentBlocks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.block, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(block['ip'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Port ${block['port']} • ${block['reason']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(block['time'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildModeButton(String label, int mode) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF00BCD4).withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF00BCD4),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
