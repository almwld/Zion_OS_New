import 'package:flutter/material.dart';

import '../../screens/apps/settings_app.dart';

/// Keeps the legacy settings route while sharing the complete settings UI.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SettingsApp();
}
