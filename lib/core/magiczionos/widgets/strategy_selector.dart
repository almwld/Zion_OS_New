import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../magiczionos_config.dart';
import '../magiczionos_provider.dart';
import '../strategies/strategy.dart';

class MagiczionosStrategySelector extends StatelessWidget {
  const MagiczionosStrategySelector({super.key});
  String _label(RootStrategy s) => switch (s) { RootStrategy.magiczionos => '#magiczionos / Magisk', RootStrategy.proot => 'PRoot', RootStrategy.chroot => 'Chroot', RootStrategy.auto => 'تلقائي' };
  StrategyStatus? _status(MagiczionosProvider p, RootStrategy s) => p.statuses[s.name];
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MagiczionosProvider>();
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('استراتيجية البيئة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (final strategy in RootStrategy.values.where((e) => e != RootStrategy.auto))
        ListTile(
          title: Text(_label(strategy)),
          subtitle: Text((_status(provider, strategy) ?? StrategyStatus.notConfigured).name),
          leading: Icon((_status(provider, strategy) == StrategyStatus.available) ? Icons.check_circle : Icons.circle_outlined),
          trailing: provider.selectedStrategy == strategy ? const Icon(Icons.radio_button_checked) : null,
          onTap: _status(provider, strategy) == StrategyStatus.available ? () => provider.switchStrategy(strategy) : null,
        ),
    ])));
  }
}