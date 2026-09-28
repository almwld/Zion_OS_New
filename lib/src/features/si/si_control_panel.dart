import 'package:flutter/material.dart';

class SIControlPanel extends StatefulWidget {
  const SIControlPanel({super.key});

  @override
  State<SIControlPanel> createState() => _SIControlPanelState();
}

class _SIControlPanelState extends State<SIControlPanel> {
  bool _siActive = false;
  final List<Map<String, dynamic>> _attackLog = [];
  final List<String> _discoveredTargets = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _discoveredTargets.addAll([
      '192.168.1.1 (Gateway)',
      '192.168.1.100 (PC-John)',
      '192.168.1.101 (Phone-Sarah)',
      '192.168.1.102 (Smart-TV)',
    ]);
  }

  void _toggleSI() {
    setState(() {
      _siActive = !_siActive;
      if (_siActive) {
        _attackLog.insert(0, {
          'time': DateTime.now(),
          'action': 'SI Agent Activated',
          'status': 'success',
        });
      } else {
        _attackLog.insert(0, {
          'time': DateTime.now(),
          'action': 'SI Agent Deactivated',
          'status': 'info',
        });
      }
    });
  }

  void _startAutoAttack() {
    setState(() => _isScanning = true);
    
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isScanning = false);
      _attackLog.insert(0, {
        'time': DateTime.now(),
        'action': 'Auto-scan completed: 4 targets found',
        'status': 'success',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SI Agent Control Panel'),
        backgroundColor: Colors.purple.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildTargetsCard(),
            const SizedBox(height: 16),
            _buildAttackLogCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_siActive ? Icons.play_circle : Icons.stop_circle,
                  color: _siActive ? Colors.green : Colors.red, size: 32),
              const SizedBox(width: 12),
              Text(
                _siActive ? 'SI AGENT ACTIVE' : 'SI AGENT INACTIVE',
                style: TextStyle(
                  color: _siActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Switch(
                value: _siActive,
                onChanged: (_) => _toggleSI(),
                activeColor: Colors.purple,
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('98%', 'Success Rate'),
              _buildStatItem('1,247', 'Total Attacks'),
              _buildStatItem('4', 'Active Targets'),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _startAutoAttack,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: _isScanning
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('START AUTO ATTACK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTargetsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.devices, color: Colors.blue),
              SizedBox(width: 8),
              Text('Discovered Targets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ..._discoveredTargets.map((target) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.green),
                const SizedBox(width: 8),
                Text(target, style: const TextStyle(color: Colors.white)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(80, 30),
                  ),
                  child: const Text('Attack', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAttackLogCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.green),
                SizedBox(width: 8),
                Text('Attack Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _attackLog.length,
                itemBuilder: (ctx, i) {
                  final log = _attackLog[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          log['status'] == 'success' ? Icons.check_circle :
                          log['status'] == 'error' ? Icons.error : Icons.info,
                          color: log['status'] == 'success' ? Colors.green :
                                 log['status'] == 'error' ? Colors.red : Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_formatTime(log['time'])} - ${log['action']}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
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
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
