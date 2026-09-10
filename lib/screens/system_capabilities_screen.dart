import 'package:flutter/material.dart';
import '../core/capabilities/capability_registry.dart';

class SystemCapabilitiesScreen extends StatelessWidget {
  const SystemCapabilitiesScreen({super.key});

  Color _stateColor(CapabilityState state) {
    switch (state) {
      case CapabilityState.available: return Colors.greenAccent;
      case CapabilityState.permissionRequired: return Colors.orangeAccent;
      case CapabilityState.notConfigured: return Colors.amberAccent;
      case CapabilityState.unavailable: return Colors.redAccent;
    }
  }

  String _stateName(CapabilityState state) {
    switch (state) {
      case CapabilityState.available: return 'AVAILABLE';
      case CapabilityState.permissionRequired: return 'PERMISSION_REQUIRED';
      case CapabilityState.notConfigured: return 'NOT_CONFIGURED';
      case CapabilityState.unavailable: return 'UNAVAILABLE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('System Capabilities', style: TextStyle(color: Color(0xFF00BCD4))),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: CapabilityRegistry.capabilities.length,
        itemBuilder: (context, index) {
          final capability = CapabilityRegistry.capabilities[index];
          final color = _stateColor(capability.state);
          return Card(
            color: Colors.white.withOpacity(.04),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(capability.isUsable ? Icons.check_circle : Icons.info_outline, color: color),
              title: Text(capability.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(capability.description, style: const TextStyle(color: Colors.white60))),
              trailing: Text(_stateName(capability.state), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
