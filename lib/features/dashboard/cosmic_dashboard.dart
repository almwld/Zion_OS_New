import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/unified_core_service.dart';

class CosmicDashboard extends ConsumerStatefulWidget {
  const CosmicDashboard({super.key});
  @override
  ConsumerState<CosmicDashboard> createState() => _CosmicDashboardState();
}

class _CosmicDashboardState extends ConsumerState<CosmicDashboard> {
  final _targetController = TextEditingController(text: '192.168.1.1');
  String _output = '';
  bool _loading = false;
  bool _siActive = false;

  Future<void> _execute(String command) async {
    setState(() => _loading = true);
    final service = ref.read(unifiedCoreProvider);
    final result = await service.execute(command, target: _targetController.text);
    setState(() { _output = result; _loading = false; if (command == 'awaken' || command == 'start_ai') _siActive = true; if (command == 'si_sleep' || command == 'stop_ai') _siActive = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildDemonCard(), const SizedBox(height: 16),
            Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFF0000).withOpacity(0.5)), color: const Color(0xFF0A0A0A).withOpacity(0.8)), padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.my_location, color: Color(0xFFFF0000)), const SizedBox(width: 8), Expanded(child: TextField(controller: _targetController, style: const TextStyle(color: Color(0xFFFF0000), fontFamily: 'monospace', fontSize: 16), decoration: const InputDecoration(border: InputBorder.none, hintText: 'أدخل عنوان الهدف للدمار...', hintStyle: TextStyle(color: Color(0xFF330000))))), _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFFFF0000))) : IconButton(icon: const Icon(Icons.warning, color: Color(0xFFFF0000), size: 36), onPressed: () => _execute('annihilate'))])),
            const SizedBox(height: 16),
            const Text('👿 Si - الشيطان', style: TextStyle(color: Color(0xFFFF0000), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _siBtn('🚀 إيقاظ', 'awaken', Colors.red),
              _siBtn('💀 هياج', 'berserk', Colors.red.shade900),
              _siBtn('🔥 حرب', 'total_war', Colors.orange),
              _siBtn('💥 تدمير', 'annihilate', Colors.red.shade700),
              _siBtn('🌊 جحيم', 'ddos_hell', Colors.deepOrange),
              _siBtn('☠️ نهاية', 'apocalypse', Colors.black),
              _siBtn('📊 تقرير', 'demon_report', Colors.red.shade400),
            ]),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 250, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0A0000).withOpacity(0.9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFF0000).withOpacity(0.4))), child: SingleChildScrollView(child: Text(_output.isNotEmpty ? _output : 'zion> الشيطان ينتظر أوامرك...\n', style: const TextStyle(color: Color(0xFFFF0000), fontFamily: 'monospace', fontSize: 12)))),
          ]),
        ),
      ),
    );
  }

  Widget _buildDemonCard() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF1A0000), Color(0xFF050000)]), border: Border.all(color: (_siActive ? Colors.red : Colors.grey).withOpacity(0.8))), child: Row(children: [Icon(_siActive ? Icons.whatshot : Icons.whatshot_outlined, color: _siActive ? Colors.red : Colors.grey, size: 40), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_siActive ? 'Si - الشيطان 👿' : 'Si - خامل 💤', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text(_siActive ? 'لا أخلاق. لا رحمة. فقط دمار.' : 'اضغط "إيقاظ" لاستدعاء الشيطان.', style: const TextStyle(color: Colors.grey, fontSize: 12))])]));
  }

  Widget _siBtn(String label, String command, Color color) {
    return ElevatedButton(onPressed: () => _execute(command), style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.3), foregroundColor: Colors.white, side: BorderSide(color: color.withOpacity(0.5))), child: Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')));
  }
}
