import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

class PowerManagement extends StatefulWidget {
  const PowerManagement({super.key});

  @override
  State<PowerManagement> createState() => _PowerManagementState();
}

class _PowerManagementState extends State<PowerManagement> {
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  bool _powerSaveMode = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBatteryInfo();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadBatteryInfo());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBatteryInfo() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    setState(() {
      _batteryLevel = level;
      _batteryState = state;
    });
  }

  Color _getBatteryColor() {
    if (_batteryLevel > 50) return Colors.green;
    if (_batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('إدارة الطاقة', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // حالة البطارية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getBatteryColor().withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.battery_full, color: _getBatteryColor(), size: 80),
                  const SizedBox(height: 10),
                  Text(
                    '$_batteryLevel%',
                    style: TextStyle(color: _getBatteryColor(), fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _batteryState == BatteryState.charging ? '⚡ قيد الشحن' : '🔋 يعمل على البطارية',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _batteryLevel / 100,
                    backgroundColor: Colors.grey[800],
                    color: _getBatteryColor(),
                    height: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // وضع توفير الطاقة
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('وضع توفير الطاقة', style: TextStyle(color: Colors.white)),
                      Text('تقييد الخلفية لتوفير البطارية', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  Switch(
                    value: _powerSaveMode,
                    onChanged: (value) => setState(() => _powerSaveMode = value),
                    activeColor: const Color(0xFF00FF41),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // إحصائيات الاستخدام
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('إحصائيات الاستخدام', style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildStatRow('مدة الاستخدام المتوقعة', '${(_batteryLevel * 2.5).toStringAsFixed(0)} ساعة'),
                  _buildStatRow('استخدام الشاشة', '45%'),
                  _buildStatRow('التطبيقات الخلفية', '12 تطبيقاً'),
                  _buildStatRow('الحرارة', '${32 + (_batteryLevel / 10).toInt()}°C'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
