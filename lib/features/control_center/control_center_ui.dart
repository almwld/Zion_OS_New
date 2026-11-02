import 'package:flutter/material.dart';

import '../../src/features/control/zion_control_center.dart';

/// Compatibility entry point shared by legacy routes and the desktop center.
class ControlCenterUI extends StatelessWidget {
  const ControlCenterUI({super.key});

  @override
  Widget build(BuildContext context) => const ZionControlCenter();
}
