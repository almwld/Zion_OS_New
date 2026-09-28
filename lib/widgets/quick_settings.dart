import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';

class QuickSettings extends StatefulWidget {
  final VoidCallback onClose;
  const QuickSettings({super.key, required this.onClose});

  @override
  State<QuickSettings> createState() => _QuickSettingsState();
}

class _QuickSettingsState extends State<QuickSettings> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: prefs.isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الإعدادات السريعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: prefs.isDarkMode ? Colors.white : Colors.black)),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: const [
                  QuickToggle(icon: Icons.wifi, label: 'WiFi'),
                  QuickToggle(icon: Icons.bluetooth, label: 'Bluetooth'),
                  QuickToggle(icon: Icons.flash_on, label: 'إضاءة'),
                  QuickToggle(icon: Icons.volume_up, label: 'صوت'),
                  QuickToggle(icon: Icons.brightness_medium, label: 'سطوع'),
                  QuickToggle(icon: Icons.airplanemode_active, label: 'طيران'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  const QuickToggle({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.cyan),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
