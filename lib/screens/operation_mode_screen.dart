import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../adaptive/adaptive_interface.dart';

class OperationModeScreen extends StatelessWidget {
  const OperationModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Operation Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            Icon(Icons.tune, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Text('Choose the interface mode. This changes presentation only and never grants elevated or offensive capabilities.', style: Theme.of(context).textTheme.bodyMedium)),
          ]))),
          const SizedBox(height: 12),
          ...OperationMode.values.map((mode) => RadioListTile<OperationMode>(
            value: mode,
            groupValue: provider.currentMode,
            title: Text(_name(mode)),
            subtitle: Text(_description(mode)),
            secondary: Icon(_icon(mode)),
            onChanged: (value) { if (value != null) provider.setMode(value); },
          )),
        ],
      ),
    );
  }

  static String _name(OperationMode mode) => switch (mode) {
    OperationMode.defensive => 'Defensive',
    OperationMode.analysis => 'Analysis',
    OperationMode.tools => 'Tools',
    OperationMode.stealth => 'Privacy presentation',
  };

  static String _description(OperationMode mode) => switch (mode) {
    OperationMode.defensive => 'Security monitoring and defensive workflows.',
    OperationMode.analysis => 'Diagnostics, telemetry and system analysis.',
    OperationMode.tools => 'Productivity and available local tools.',
    OperationMode.stealth => 'Reduced-distraction privacy-oriented presentation; no evasion or concealment functions.',
  };

  static IconData _icon(OperationMode mode) => switch (mode) {
    OperationMode.defensive => Icons.shield_outlined,
    OperationMode.analysis => Icons.analytics_outlined,
    OperationMode.tools => Icons.build_outlined,
    OperationMode.stealth => Icons.visibility_off_outlined,
  };
}
