import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _themeColors = <Color>[
    Color(0xFF00BCD4),
    Colors.cyan,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        final dark = theme.isDarkMode;
        final foreground = dark ? Colors.white : Colors.black87;
        final secondary = dark ? Colors.white70 : Colors.black54;
        final surface = dark ? const Color(0xFF15191C) : Colors.white;

        return Scaffold(
          backgroundColor: dark ? const Color(0xFF090B0C) : const Color(0xFFF5F7F8),
          appBar: AppBar(
            backgroundColor: dark ? const Color(0xFF090B0C) : Colors.white,
            foregroundColor: theme.primaryColor,
            elevation: 0,
            title: Text('settings'.tr()),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _section(context, 'appearance'.tr(), Icons.palette_outlined, theme, foreground),
                _card(
                  surface,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('dark_mode'.tr(), style: TextStyle(color: foreground)),
                      subtitle: Text(
                        dark ? 'Dark theme' : 'Light theme',
                        style: TextStyle(color: secondary),
                      ),
                      value: dark,
                      activeColor: theme.primaryColor,
                      onChanged: (_) => theme.toggleTheme(),
                    ),
                    const Divider(height: 1),
                    _colorSelector(theme, foreground, secondary),
                    const Divider(height: 1),
                    _slider(
                      context,
                      title: 'font_size'.tr(),
                      value: theme.fontScale,
                      min: 0.8,
                      max: 1.5,
                      divisions: 7,
                      label: theme.fontScale.toStringAsFixed(1),
                      onChanged: theme.setFontScale,
                      theme: theme,
                      foreground: foreground,
                    ),
                    _slider(
                      context,
                      title: 'icon_size'.tr(),
                      value: theme.iconSize,
                      min: 48,
                      max: 78,
                      divisions: 6,
                      label: theme.iconSize.toStringAsFixed(0),
                      onChanged: theme.setIconSize,
                      theme: theme,
                      foreground: foreground,
                    ),
                  ],
                ),
                _section(context, 'security'.tr(), Icons.security_outlined, theme, foreground),
                _card(
                  surface,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline, color: theme.primaryColor),
                      title: Text('change_pin'.tr(), style: TextStyle(color: foreground)),
                      subtitle: Text('update_security_pin'.tr(), style: TextStyle(color: secondary)),
                      trailing: Icon(Icons.chevron_right, color: secondary),
                      onTap: () => _showChangePinDialog(context, theme, foreground),
                    ),
                  ],
                ),
                _section(context, 'language'.tr(), Icons.language_outlined, theme, foreground),
                _card(
                  surface,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.translate, color: theme.primaryColor),
                      title: Text('language'.tr(), style: TextStyle(color: foreground)),
                      subtitle: Text(
                        context.locale.languageCode == 'ar' ? 'العربية' : 'English',
                        style: TextStyle(color: secondary),
                      ),
                      trailing: Icon(Icons.chevron_right, color: secondary),
                      onTap: () => _showLanguageDialog(context, theme, foreground),
                    ),
                  ],
                ),
                _section(context, 'about'.tr(), Icons.info_outline, theme, foreground),
                _card(
                  surface,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.shield_outlined, color: theme.primaryColor),
                      title: Text('Zion OS', style: TextStyle(color: foreground, fontWeight: FontWeight.w600)),
                      subtitle: Text('4.0.0', style: TextStyle(color: secondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    IconData icon,
    ThemeProvider theme,
    Color foreground,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _card(Color surface, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _colorSelector(ThemeProvider theme, Color foreground, Color secondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('theme_color'.tr(), style: TextStyle(color: foreground, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _themeColors.map((color) {
              final selected = theme.primaryColor.value == color.value;
              return Semantics(
                button: true,
                label: 'Theme color',
                child: GestureDetector(
                  onTap: () => theme.setPrimaryColor(color),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected ? Border.all(color: foreground, width: 3) : null,
                    ),
                    child: selected ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text('Choose your accent color', style: TextStyle(color: secondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _slider(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    required ThemeProvider theme,
    required Color foreground,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: TextStyle(color: foreground))),
            Text(label, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: theme.primaryColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _showChangePinDialog(
    BuildContext context,
    ThemeProvider theme,
    Color foreground,
  ) async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('change_pin'.tr()),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'Current PIN'),
                  validator: (value) => value != null && value.length == 4 ? null : 'Enter 4 digits',
                ),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'New PIN'),
                  validator: (value) => value != null && RegExp(r'^\d{4}$').hasMatch(value) ? null : 'Enter 4 digits',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('cancel'.tr())),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await theme.changePin(oldController.text, newController.text);
                if (!dialogContext.mounted) return;
                if (ok) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PIN changed successfully'), backgroundColor: theme.primaryColor),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid PIN'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        );
      },
    );

    oldController.dispose();
    newController.dispose();
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    ThemeProvider theme,
    Color foreground,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية'),
              onTap: () async {
                await context.setLocale(const Locale('ar'));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () async {
                await context.setLocale(const Locale('en'));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}
