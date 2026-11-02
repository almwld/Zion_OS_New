import 'package:flutter/material.dart';

import 'screens/apps/system_monitor.dart';

/// Compatibility entry point for the legacy launcher.
///
/// The old implementation displayed fabricated CPU/RAM/disk values. Keep the
/// launcher route stable while sharing the real procfs/sysfs monitor used by
/// the main desktop.
class ZionSystemMonitor extends StatelessWidget {
  const ZionSystemMonitor({super.key});

  @override
  Widget build(BuildContext context) => const SystemMonitorApp();
}
