import 'package:flutter/material.dart';
import '../core/services/zion_platform_service.dart';
import '../services/preferences_service.dart';
import 'package:provider/provider.dart';

class BatteryPopup extends StatefulWidget {
  final VoidCallback onClose;
  const BatteryPopup({super.key, required this.onClose});

  @override
  State<BatteryPopup> createState() => _BatteryPopupState();
}

class _BatteryPopupState extends State<BatteryPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late Future<Map<String, Object?>> _batteryFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _batteryFuture = ZionPlatformService.instance.getBatteryInfo();
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
          width: 280,
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
                  Text('معلومات البطارية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: prefs.isDarkMode ? Colors.white : Colors.black)),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, Object?>>(
                future: _batteryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final data = snapshot.data ?? const <String, Object?>{};
                  final level = data['level'];
                  final voltage = data['voltageV'];
                  final temperature = data['temperatureC'];
                  final charging = data['charging'] == true;
                  final available = data['available'] == true && level is num;

                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          charging ? Icons.battery_charging_full : Icons.battery_full,
                          size: 60,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          available ? '${(level as num).round()}%' : 'غير متاح',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voltage is num && temperature is num
                              ? 'الجهد: ${voltage.toStringAsFixed(2)}V • الحرارة: ${temperature.toStringAsFixed(1)}°C'
                              : charging
                                  ? 'الجهاز متصل بالشاحن'
                                  : 'بيانات البطارية غير مكتملة',
                        ),
                        if (snapshot.hasError) ...[
                          const SizedBox(height: 8),
                          const Text('تعذر الوصول إلى بيانات الجهاز', style: TextStyle(color: Colors.orange)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
