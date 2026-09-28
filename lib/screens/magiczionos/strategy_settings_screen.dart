import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/magiczionos/magiczionos_provider.dart';
import '../../core/magiczionos/widgets/strategy_selector.dart';

class MagiczionosStrategySettingsScreen extends StatelessWidget {
  const MagiczionosStrategySettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MagiczionosProvider()..initialize(),
      child: Scaffold(appBar: AppBar(title: const Text('إعدادات #magiczionos')), body: const Padding(padding: EdgeInsets.all(16), child: MagiczionosStrategySelector())),
    );
  }
}