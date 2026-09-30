import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutomationCenter extends StatefulWidget {
  const AutomationCenter({super.key});
  @override
  State<AutomationCenter> createState() => _AutomationCenterState();
}

class _AutomationCenterState extends State<AutomationCenter> {
  static const _key = 'zion_automation_enabled';
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool(_key) ?? false;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    if (mounted) setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B10),
      appBar: AppBar(
        title: const Text('مركز الأتمتة'),
        backgroundColor: const Color(0xFF101923),
        foregroundColor: const Color(0xFF00BCD4),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFF101923),
                  child: SwitchListTile(
                    title: const Text('الأتمتة المحلية', style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                      'حفظ تفضيل التشغيل محليًا. تنفيذ المهام يحتاج Scheduler/worker مخصصًا.',
                      style: TextStyle(color: Colors.white60),
                    ),
                    value: _enabled,
                    onChanged: _toggle,
                    activeColor: const Color(0xFF00BCD4),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  color: Color(0xFF101923),
                  child: ListTile(
                    leading: Icon(Icons.schedule, color: Color(0xFF00BCD4)),
                    title: Text('Task Scheduler', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'إدارة المهام المجدولة متاحة من شاشة Scheduler. '
                      'لا يتم الادعاء بتنفيذ مهام في الخلفية ما لم يكن العامل متصلًا.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
