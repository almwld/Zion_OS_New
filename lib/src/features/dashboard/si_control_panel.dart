import 'package:flutter/material.dart';
import '../../core/si/zion_si_agent.dart';
import '../../core/si/reinforcement_learning.dart';

class SIControlPanel extends StatefulWidget {
  const SIControlPanel({super.key});

  @override
  State<SIControlPanel> createState() => _SIControlPanelState();
}

class _SIControlPanelState extends State<SIControlPanel> {
  final ZionSIAgent _siAgent = ZionSIAgent();
  final ReinforcementLearning _rl = ReinforcementLearning();
  Map<String, dynamic> _status = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    _status = await _siAgent.getStatus();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🧠 SI Agent Control Panel'),
        backgroundColor: Colors.purple.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_status['active'] == true ? Icons.play_circle : Icons.stop_circle,
                  color: _status['active'] == true ? Colors.green : Colors.red),
              const SizedBox(width: 12),
              Text(
                _status['active'] == true ? '🟢 ACTIVE' : '🔴 INACTIVE',
                style: TextStyle(
                  color: _status['active'] == true ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(),
          _buildInfoRow('Known Targets', '${_status['known_targets']}'),
          _buildInfoRow('Total Attacks', '${_status['total_attacks']}'),
          _buildInfoRow('Success Rate', '${(_status['success_rate'] as double? ?? 0).toStringAsFixed(2)}%'),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _status['learning_stats'] as Map<String, dynamic>?;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('📊 Learning Statistics',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          const Divider(),
          _buildInfoRow('Samples Trained', '${stats?['samples_trained'] ?? 0}'),
          _buildInfoRow('Network Layers', '${stats?['network_layers'] ?? 0}'),
          _buildInfoRow('Total Neurons', '${stats?['total_neurons'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('⚡ Actions',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _siAgent.activate();
                    _loadStatus();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('ACTIVATE'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    _siAgent.deactivate();
                    _loadStatus();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('DEACTIVATE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
