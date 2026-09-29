import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/zion_colors.dart';
import '../../providers/theme_provider.dart';
import '../system_capabilities_screen.dart';
import 'runtime_intelligence.dart';

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tp = context.watch<ThemeProvider>();
    final dark = tp.isDarkMode;
    final scheme = theme.colorScheme;
    final surface = dark ? ZionColors.darkSurface : ZionColors.lightSurface;
    final card = dark ? ZionColors.darkCard : ZionColors.lightCard;
    final text = dark ? ZionColors.darkTextPrimary : ZionColors.lightTextPrimary;
    final secondary =
        dark ? ZionColors.darkTextSecondary : ZionColors.lightTextSecondary;

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor:
            dark ? ZionColors.darkBackground : ZionColors.lightBackground,
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          foregroundColor: text,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _section('المظهر'),
            _card(
              child: Column(
                children: [
                  _switchTile(
                    'الوضع الليلي',
                    'تطبيق مظهر Zion الداكن',
                    tp.isDarkMode,
                    (_) => tp.toggleTheme(),
                  ),
                  _divider(),
                  _sliderTile(
                    'حجم النص',
                    tp.fontScale,
                    0.8,
                    1.5,
                    tp.setFontScale,
                  ),
                  _sliderTile(
                    'حجم الأيقونات',
                    tp.iconSize,
                    48,
                    78,
                    tp.setIconSize,
                  ),
                ],
              ),
            ),
            _section('CMatrix / المسند'),
            _card(
              child: Column(
                children: [
                  _switchTile(
                    'خلفية Matrix',
                    'خلفية متحركة منخفضة الاستهلاك',
                    tp.cmatrixEnabled,
                    tp.setCMatrixEnabled,
                  ),
                  if (tp.cmatrixEnabled) ...[
                    _divider(),
                    _matrixMode(tp, secondary),
                    _sliderTile(
                      'الشفافية',
                      tp.cmatrixOpacity,
                      0.05,
                      0.5,
                      tp.setCMatrixOpacity,
                    ),
                    _sliderTile(
                      'السرعة',
                      tp.cmatrixSpeed,
                      0.1,
                      3.0,
                      tp.setCMatrixSpeed,
                    ),
                    _sliderTile(
                      'حجم الحروف',
                      tp.cmatrixFontSize,
                      12,
                      32,
                      tp.setCMatrixFontSize,
                    ),
                    _matrixColors(tp),
                  ],
                ],
              ),
            ),
            _section('النظام'),
            _card(
              child: Column(
                children: [
                  _navigationTile(
                    Icons.dashboard_customize_outlined,
                    'قدرات النظام',
                    'حالة كل قدرة: AVAILABLE / PERMISSION_REQUIRED / NOT_CONFIGURED / UNAVAILABLE',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SystemCapabilitiesScreen(),
                      ),
                    ),
                  ),
                  _divider(),
                  _navigationTile(
                    Icons.auto_awesome_outlined,
                    'ذكاء وقت التشغيل',
                    'محلل محلي وتوقع أوامر دون خدمة سحابية',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RuntimeIntelligenceApp(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _section('الأمان'),
            _card(
              child: _navigationTile(
                Icons.pin_outlined,
                'تغيير رمز PIN',
                'تغيير رمز الدخول المحفوظ بشكل آمن',
                () => _showChangePinDialog(tp),
              ),
            ),
            _section('اللغة'),
            _card(child: _languageSelector(context, context.locale.languageCode)),
            _section('عن Zion OS'),
            _card(
              child: Column(
                children: [
                  _infoTile(Icons.info_outline, 'الإصدار', '2.0.0'),
                  _divider(),
                  _infoTile(Icons.description_outlined, 'الترخيص', 'MIT License'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Text(
          title,
          style: const TextStyle(
            color: ZionColors.cyan,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _card({required Widget child}) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: child,
        ),
      );

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _switchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      SwitchListTile(
        secondary: const Icon(Icons.tune_outlined, color: ZionColors.cyan),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: ZionColors.cyan,
      );

  Widget _sliderTile(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) =>
      ListTile(
        title: Text(title),
        subtitle: Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: ZionColors.cyan,
        ),
        trailing: SizedBox(
          width: 42,
          child: Text(value.toStringAsFixed(1), textAlign: TextAlign.end),
        ),
      );

  Widget _matrixMode(ThemeProvider tp, Color secondary) => ListTile(
        leading: const Icon(Icons.translate, color: ZionColors.cyan),
        title: const Text('نوع الحروف'),
        subtitle: Text(
          tp.cmatrixUseMusnad
              ? 'المسند — Old South Arabian'
              : 'العربية الحديثة',
          style: TextStyle(color: secondary),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: tp.cmatrixUseMusnad ? 'musnad' : 'modern',
            items: const [
              DropdownMenuItem(value: 'musnad', child: Text('المسند')),
              DropdownMenuItem(value: 'modern', child: Text('عربي حديث')),
            ],
            onChanged: (value) {
              if (value == 'musnad') tp.setCMatrixUseMusnad(true);
              if (value == 'modern') tp.setCMatrixUseArabic(true);
            },
          ),
        ),
      );

  Widget _matrixColors(ThemeProvider tp) => ListTile(
        leading: const Icon(Icons.palette_outlined, color: ZionColors.cyan),
        title: const Text('لون الحروف'),
        subtitle: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: const [
            Color(0xFF00FF41),
            ZionColors.cyan,
            Color(0xFFFFD700),
            Color(0xFFFF4757),
            Color(0xFF8854D0),
          ].map((color) {
            return _MatrixColorButton(color: color);
          }).toList(),
        ),
      );

  Widget _navigationTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) =>
      ListTile(
        leading: Icon(icon, color: ZionColors.cyan),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  Widget _infoTile(IconData icon, String title, String subtitle) => ListTile(
        leading: const Icon(Icons.info_outline, color: ZionColors.cyan),
        title: Text(title),
        subtitle: Text(subtitle),
      );

  Widget _languageSelector(BuildContext context, String currentLocale) =>
      ListTile(
        leading: const Icon(Icons.language, color: ZionColors.cyan),
        title: Text('language'.tr()),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentLocale == 'ar' ? 'ar' : 'en',
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
            ],
            onChanged: (value) {
              if (value == null) return;
              context.setLocale(Locale(value));
            },
          ),
        ),
      );

  void _showChangePinDialog(ThemeProvider tp) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('change_pin'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Old PIN'),
            ),
            TextField(
              controller: newCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New PIN (4 digits)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await tp.changePin(oldCtrl.text, newCtrl.text);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'PIN changed successfully' : 'Invalid PIN',
                  ),
                ),
              );
              if (ok) Navigator.pop(dialogContext);
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }
}

class _MatrixColorButton extends StatelessWidget {
  const _MatrixColorButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ThemeProvider>().setCMatrixColor(color),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
    );
  }
}
