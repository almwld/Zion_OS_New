import 'package:flutter/material.dart';

import '../../core/theme/zion_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = ZionColors.cyan;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(context, 'عام'),
          Card(
            child: Column(children: [
              SwitchListTile(
                secondary: Icon(Icons.dark_mode_outlined, color: iconColor),
                title: const Text('الوضع الليلي'),
                subtitle: const Text('يستخدم مظهر Zion الداكن عند تفعيله'),
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: null,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(Icons.notifications_none, color: iconColor),
                title: const Text('الإشعارات'),
                subtitle: const Text('إعدادات الإشعارات تدار من النظام'),
                value: true,
                onChanged: null,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _section(context, 'الشبكة'),
          Card(
            child: ListTile(
              leading: Icon(Icons.http, color: iconColor),
              title: const Text('وكيل HTTP'),
              subtitle: const Text('لم يتم التعيين'),
              trailing: Icon(Icons.chevron_right, color: iconColor),
            ),
          ),
          const SizedBox(height: 16),
          _section(context, 'حول'),
          Card(
            child: Column(children: [
              ListTile(
                leading: Icon(Icons.info_outline, color: iconColor),
                title: const Text('الإصدار'),
                subtitle: const Text('2.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.description_outlined, color: iconColor),
                title: const Text('الترخيص'),
                subtitle: const Text('MIT License'),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            color: ZionColors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
