import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'features/terminal/terminal_screen.dart';
import 'screens/magiczionos/installer_screen.dart';
import 'screens/magiczionos/root_terminal_screen.dart';
import 'screens/magiczionos/strategy_settings_screen.dart';
import 'screens/apps/file_manager.dart';
import 'screens/apps/web_browser.dart';
import 'screens/apps/settings_app.dart';
import 'screens/apps/calculator.dart';
import 'screens/apps/notes_app.dart';
import 'screens/apps/gallery_app.dart';
import 'screens/apps/weather_app.dart';
import 'widgets/cmatrix_arabic_background.dart';

/// Zion OS Desktop Home — the visual system requested for the main interface.
class DesktopHome extends StatefulWidget {
  const DesktopHome({super.key});

  @override
  State<DesktopHome> createState() => _DesktopHomeState();
}

/// Backwards-compatible name used by the existing lock/app entry points.
typedef ZionDesktop = DesktopHome;

class _DesktopHomeState extends State<DesktopHome> with TickerProviderStateMixin {
  String _currentTime = "";
  String _currentDate = "";
  int _selectedCategory = 0;
  bool _showRadar = true;
  bool _showStartMenu = false;
  Timer? _clockTimer;
  late AnimationController _radarController;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _categories = [
    {"name": "ATTACK", "nameAr": "هجوم", "icon": Icons.flash_on, "color": const Color(0xFFFF4757), "gradient": [const Color(0xFFFF4757), const Color(0xFFD63447)]},
    {"name": "DEFENSE", "nameAr": "دفاع", "icon": Icons.shield, "color": const Color(0xFF2ED573), "gradient": [const Color(0xFF2ED573), const Color(0xFF17A24A)]},
    {"name": "ANALYSIS", "nameAr": "تحليل", "icon": Icons.analytics, "color": const Color(0xFF3742FA), "gradient": [const Color(0xFF3742FA), const Color(0xFF2732D9)]},
    {"name": "TOOLS", "nameAr": "أدوات", "icon": Icons.build, "color": const Color(0xFFFFA502), "gradient": [const Color(0xFFFFA502), const Color(0xFFE68A00)]},
  ];

  final List<Map<String, dynamic>> _apps = [
    {"name":"WIFI","nameAr":"واي فاي","icon":Icons.wifi,"category":"ATTACK","color":const Color(0xFFFF4757)},
    {"name":"EXPLOIT","nameAr":"استغلال","icon":Icons.bug_report,"category":"ATTACK","color":const Color(0xFFE84393)},
    {"name":"CRACKER","nameAr":"كسر","icon":Icons.vpn_key,"category":"ATTACK","color":const Color(0xFFFF6B81)},
    {"name":"DDOS","nameAr":"حجب","icon":Icons.speed,"category":"ATTACK","color":const Color(0xFFFF3838)},
    {"name":"DATABASE","nameAr":"قواعد","icon":Icons.storage,"category":"ATTACK","color":const Color(0xFFC44569)},
    {"name":"CLOUD","nameAr":"سحابة","icon":Icons.cloud,"category":"ATTACK","color":const Color(0xFFFF5252)},
    {"name":"STEALTH","nameAr":"تخفي","icon":Icons.visibility_off,"category":"DEFENSE","color":const Color(0xFF2ED573)},
    {"name":"CRYPTO","nameAr":"تشفير","icon":Icons.lock,"category":"DEFENSE","color":const Color(0xFF26DE81)},
    {"name":"BATTERY","nameAr":"بطارية","icon":Icons.battery_charging_full,"category":"DEFENSE","color":const Color(0xFF20BF6B)},
    {"name":"FIREWALL","nameAr":"جدار","icon":Icons.security,"category":"DEFENSE","color":const Color(0xFF0FB9B1)},
    {"name":"VPN","nameAr":"VPN","icon":Icons.vpn_lock,"category":"DEFENSE","color":const Color(0xFF45AAF2)},
    {"name":"ANTIVIRUS","nameAr":"مضاد","icon":Icons.health_and_safety,"category":"DEFENSE","color":const Color(0xFF2BCBBA)},
    {"name":"NETWORK","nameAr":"شبكة","icon":Icons.network_wifi,"category":"ANALYSIS","color":const Color(0xFF3742FA)},
    {"name":"FORENSICS","nameAr":"جنائي","icon":Icons.search,"category":"ANALYSIS","color":const Color(0xFF5352ED)},
    {"name":"TEXT","nameAr":"نصوص","icon":Icons.analytics,"category":"ANALYSIS","color":const Color(0xFF706FD3)},
    {"name":"CALCULATOR","nameAr":"حاسبة","icon":Icons.calculate,"category":"ANALYSIS","color":const Color(0xFF546DE5)},
    {"name":"UNIT","nameAr":"وحدات","icon":Icons.science,"category":"ANALYSIS","color":const Color(0xFF778BEB)},
    {"name":"PERCENT","nameAr":"نسبة","icon":Icons.percent,"category":"ANALYSIS","color":const Color(0xFF5F27CD)},
    {"name":"DATE","nameAr":"تواريخ","icon":Icons.calendar_month,"category":"ANALYSIS","color":const Color(0xFF341F97)},
    {"name":"CURRENCY","nameAr":"عملات","icon":Icons.attach_money,"category":"ANALYSIS","color":const Color(0xFF1B9CFC)},
    {"name":"TRANSLATOR","nameAr":"مترجم","icon":Icons.translate,"category":"ANALYSIS","color":const Color(0xFF25CCF7)},
    {"name":"TERMINAL","nameAr":"طرفية","icon":Icons.terminal,"category":"TOOLS","color":const Color(0xFFFFA502)},
    {"name":"MAGICZIONOS","nameAr":"بيئة الجذر","icon":Icons.admin_panel_settings,"category":"TOOLS","color":const Color(0xFF00D9A6)},
    {"name":"FILES","nameAr":"ملفات","icon":Icons.folder,"category":"TOOLS","color":const Color(0xFFFFB142)},
    {"name":"BROWSER","nameAr":"متصفح","icon":Icons.public,"category":"TOOLS","color":const Color(0xFFF7B731)},
    {"name":"SETTINGS","nameAr":"إعدادات","icon":Icons.settings,"category":"TOOLS","color":const Color(0xFFFA8231)},
    {"name":"NOTES","nameAr":"ملاحظات","icon":Icons.note,"category":"TOOLS","color":const Color(0xFFFED330)},
    {"name":"WEATHER","nameAr":"طقس","icon":Icons.wb_sunny,"category":"TOOLS","color":const Color(0xFFFFC048)},
    {"name":"MAPS","nameAr":"خرائط","icon":Icons.map,"category":"TOOLS","color":const Color(0xFFFF9F1A)},
    {"name":"RADIO","nameAr":"راديو","icon":Icons.radio,"category":"TOOLS","color":const Color(0xFFFD9644)},
    {"name":"EMAIL","nameAr":"بريد","icon":Icons.email,"category":"TOOLS","color":const Color(0xFFF7B731)},
    {"name":"GALLERY","nameAr":"معرض","icon":Icons.photo_library,"category":"TOOLS","color":const Color(0xFFFF6B6B)},
    {"name":"VIDEO","nameAr":"فيديو","icon":Icons.play_circle_filled,"category":"TOOLS","color":const Color(0xFFFD7272)},
    {"name":"CLOCK","nameAr":"ساعة","icon":Icons.access_time,"category":"TOOLS","color":const Color(0xFFFC427B)},
    {"name":"CALENDAR","nameAr":"تقويم","icon":Icons.calendar_today,"category":"TOOLS","color":const Color(0xFFE84393)},
    {"name":"QR","nameAr":"QR","icon":Icons.qr_code_scanner,"category":"TOOLS","color":const Color(0xFFBDC581)},
    {"name":"DOCUMENTS","nameAr":"مستندات","icon":Icons.description,"category":"TOOLS","color":const Color(0xFFF5CD79)},
    {"name":"BACKUP","nameAr":"نسخ","icon":Icons.backup,"category":"TOOLS","color":const Color(0xFF4B7BEC)},
    {"name":"CLEANER","nameAr":"تنظيف","icon":Icons.cleaning_services,"category":"TOOLS","color":const Color(0xFF26de81)},
    {"name":"APP LOCK","nameAr":"قفل","icon":Icons.lock_outline,"category":"TOOLS","color":const Color(0xFFA55EEA)},
    {"name":"NOTIFY","nameAr":"إشعارات","icon":Icons.notifications,"category":"TOOLS","color":const Color(0xFF8854D0)},
  ];

  @override
  void initState() {
    super.initState();
    _updateTimeAndDate();
    _radarController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat();
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
  }

  void _updateTimeAndDate() {
    void tick() {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        _currentDate = _getArabicDate(now);
      });
    }
    tick();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _getArabicDate(DateTime date) {
    const days = ['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'];
    const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${days[date.weekday % 7]}، ${date.day} ${months[date.month - 1]}';
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _openApp(Map<String, dynamic> app) {
    final name = app['name'] as String;
    final Widget? screen = switch (name) {
      'TERMINAL' => const TerminalScreen(),
      'MAGICZIONOS' => const MagiczionosInstallerScreen(),
      'FILES' => const FileManagerApp(),
      'BROWSER' => const WebBrowserApp(),
      'SETTINGS' => const SettingsApp(),
      'CALCULATOR' => const CalculatorApp(),
      'NOTES' => const NotesApp(),
      'GALLERY' => const GalleryApp(),
      'WEATHER' => const WeatherApp(),
      _ => null,
    };

    if (screen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هذه الوظيفة غير متاحة في نسخة الإنتاج: ${app['nameAr']}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = theme.primaryColor;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      body: Stack(children: [
        _buildBackground(isDark, primaryColor),
        if (theme.cmatrixEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: CMatrixArabicBackground(
                enabled: theme.cmatrixEnabled,
                useMusnad: theme.cmatrixUseMusnad,
                useArabicModern: theme.cmatrixUseArabic,
                color: theme.cmatrixColor,
                opacity: theme.cmatrixOpacity,
                speed: theme.cmatrixSpeed,
                fontSize: theme.cmatrixFontSize,
              ),
            ),
          ),
        SafeArea(child: Column(
          children: [
            _buildTopBar(theme, isDark, primaryColor),
            _buildCategoriesBar(theme, isDark, primaryColor),
            Expanded(child: _buildAppsGrid(theme, isDark, primaryColor)),
            _buildDock(theme, isDark, primaryColor),
          ],
        )),
        if (_showRadar) _buildFloatingRadar(theme, isDark, primaryColor),
        if (_showStartMenu) _buildStartMenu(theme, isDark, primaryColor),
      ]),
    );
  }

  Widget _buildBackground(bool isDark, Color primaryColor) => Container(
    decoration: BoxDecoration(gradient: RadialGradient(
      center: Alignment.topCenter, radius: 1.5,
      colors: isDark ? [const Color(0xFF0A0E1A), const Color(0xFF070B14), Colors.black] : [const Color(0xFFF5F7FA), const Color(0xFFE8ECF1), const Color(0xFFDDE3EA)],
    )),
    child: CustomPaint(painter: GridPatternPainter(isDark: isDark, primaryColor: primaryColor), size: Size.infinite),
  );

  Widget _buildTopBar(ThemeProvider theme, bool isDark, Color primaryColor) => Container(
    height: 64, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: primaryColor.withOpacity(0.15)),
      boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        AnimatedBuilder(animation: _pulseController, builder: (context, child) => Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.6)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3 + (_pulseController.value * 0.3)), blurRadius: 10 + (_pulseController.value * 10), spreadRadius: 2)],
          ),
          child: const Center(child: Text("Z", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
        )),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("ZION OS", style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text(_currentDate, style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 9)),
        ]),
      ]),
      Row(children: [
        _buildStatusIcon(Icons.speed, primaryColor, isDark), const SizedBox(width: 8),
        _buildStatusIcon(Icons.wifi, primaryColor, isDark), const SizedBox(width: 8),
        _buildStatusIcon(Icons.battery_full, Colors.green, isDark), const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryColor.withOpacity(0.3))),
          child: Text(_currentTime, style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ]),
    ]),
  );

  Widget _buildStatusIcon(IconData icon, Color color, bool isDark) => Icon(icon, color: color.withOpacity(0.7), size: 16);

  Widget _buildCategoriesBar(ThemeProvider theme, bool isDark, Color primaryColor) => Container(
    height: 50, margin: const EdgeInsets.symmetric(horizontal: 16),
    child: ListView.builder(
      scrollDirection: Axis.horizontal, itemCount: _categories.length,
      itemBuilder: (context, index) {
        final selected = _selectedCategory == index; final cat = _categories[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? LinearGradient(colors: cat['gradient'], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              color: selected ? null : Colors.transparent, borderRadius: BorderRadius.circular(25),
              border: Border.all(color: selected ? Colors.transparent : cat['color'].withOpacity(0.3), width: 1.5),
              boxShadow: selected ? [BoxShadow(color: cat['color'].withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : null,
            ),
            child: Row(children: [
              Icon(cat['icon'], color: selected ? Colors.white : cat['color'], size: 18),
              const SizedBox(width: 8),
              Text(cat['nameAr'], style: TextStyle(color: selected ? Colors.white : cat['color'], fontWeight: selected ? FontWeight.bold : FontWeight.w600, fontSize: 13)),
            ]),
          ),
        );
      },
    ),
  );

  Widget _buildAppsGrid(ThemeProvider theme, bool isDark, Color primaryColor) {
    final width = MediaQuery.of(context).size.width;
    final columns = width < 600 ? 3 : 4;
    final filtered = _apps.where((app) => app['category'] == _categories[_selectedCategory]['name']).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, childAspectRatio: 0.88, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildAppIcon(filtered[index], theme, isDark, primaryColor),
    );
  }

  Widget _buildAppIcon(Map<String, dynamic> app, ThemeProvider theme, bool isDark, Color primaryColor) {
    final appColor = app['color'] as Color;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0), duration: Duration(milliseconds: 300 + (app['name'].hashCode % 200)), curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: GestureDetector(
          onTap: () => _openApp(app),
          onLongPress: () => setState(() => _showRadar = !_showRadar),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: appColor.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: appColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [appColor, appColor.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: appColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(app['icon'], color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(app['nameAr'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(height: 2),
              Text(app['name'], style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 8, letterSpacing: 0.5), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDock(ThemeProvider theme, bool isDark, Color primaryColor) => Container(
    height: 76, margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(24), border: Border.all(color: primaryColor.withOpacity(0.2)),
      boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _buildDockItem(icon: Icons.apps, label: 'القائمة', color: const Color(0xFF3742FA), isDark: isDark, onTap: () => setState(() => _showStartMenu = true)),
      _buildDockItem(icon: Icons.terminal, label: 'الطرفية', color: const Color(0xFFFFA502), isDark: isDark, onTap: () => _openApp({"name":"TERMINAL","nameAr":"الطرفية","icon":Icons.terminal,"color":const Color(0xFFFFA502)})),
      _buildDockItem(icon: Icons.folder, label: 'الملفات', color: const Color(0xFF4B7BEC), isDark: isDark, onTap: () => _openApp({"name":"FILES","nameAr":"الملفات","icon":Icons.folder,"color":const Color(0xFF4B7BEC)})),
      _buildDockItem(icon: Icons.radar, label: 'الرادار', color: const Color(0xFF2ED573), isDark: isDark, onTap: () => setState(() => _showRadar = !_showRadar)),
      _buildDockItem(icon: Icons.settings, label: 'الإعدادات', color: const Color(0xFF8854D0), isDark: isDark, onTap: () => _openApp({"name":"SETTINGS","nameAr":"الإعدادات","icon":Icons.settings,"color":const Color(0xFF8854D0)})),
    ]),
  );

  Widget _buildDockItem({required IconData icon, required String label, required Color color, required bool isDark, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ), child: Icon(icon, color: Colors.white, size: 22)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 9, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildFloatingRadar(ThemeProvider theme, bool isDark, Color primaryColor) => Positioned(
    right: 20, top: 140,
    child: GestureDetector(
      child: AnimatedBuilder(
        animation: _radarController,
        builder: (context, child) => Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.9),
            border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(children: [
            CustomPaint(painter: RadarPainter(angle: _radarController.value * 2 * 3.14159, color: primaryColor), size: const Size(100, 100)),
            ..._buildRadarPoints(primaryColor),
            Positioned(right: 4, top: 4, child: GestureDetector(onTap: () => setState(() => _showRadar = false), child: Container(
              padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 10),
            ))),
          ]),
        ),
      ),
    ),
  );

  List<Widget> _buildRadarPoints(Color primaryColor) {
    final points = [
      {'x':25.0,'y':30.0,'color':Colors.green},
      {'x':70.0,'y':40.0,'color':Colors.yellow},
      {'x':50.0,'y':70.0,'color':Colors.orange},
      {'x':30.0,'y':60.0,'color':Colors.red},
    ];
    return points.map((point) => Positioned(
      left: point['x'] as double, top: point['y'] as double,
      child: AnimatedBuilder(animation: _pulseController, builder: (context, child) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: point['color'] as Color, boxShadow: [
          BoxShadow(color: (point['color'] as Color).withOpacity(0.5 + (_pulseController.value * 0.5)), blurRadius: 5 + (_pulseController.value * 5), spreadRadius: 1),
        ]),
      )),
    )).toList();
  }

  Widget _buildStartMenu(ThemeProvider theme, bool isDark, Color primaryColor) => GestureDetector(
    onTap: () => setState(() => _showStartMenu = false),
    child: Container(color: Colors.black.withOpacity(0.5), child: Center(child: GestureDetector(
      onTap: () {},
      child: Container(
        width: 340, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1626) : Colors.white,
          borderRadius: BorderRadius.circular(24), border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.7)]), shape: BoxShape.circle), child: const Center(child: Text("Z", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Zion User", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              Text("zion@os", style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
            ])),
            IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black45), onPressed: () => setState(() => _showStartMenu = false)),
          ]),
          const Divider(height: 24),
          _buildStartMenuItem(icon: Icons.terminal, title: 'الطرفية', subtitle: 'تنفيذ الأوامر', color: const Color(0xFFFFA502), isDark: isDark),
          _buildStartMenuItem(icon: Icons.wifi, title: 'الواي فاي', subtitle: 'مسح الشبكات', color: const Color(0xFFFF4757), isDark: isDark),
          _buildStartMenuItem(icon: Icons.settings, title: 'الإعدادات', subtitle: 'تخصيص النظام', color: const Color(0xFF8854D0), isDark: isDark),
          _buildStartMenuItem(icon: Icons.security, title: 'الأمان', subtitle: 'مركز الحماية', color: const Color(0xFF2ED573), isDark: isDark),
        ]),
      ),
    ))),
  );

  Widget _buildStartMenuItem({required IconData icon, required String title, required String subtitle, required Color color, required bool isDark}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
      onTap: () => setState(() => _showStartMenu = false),
    ),
  );
}

class GridPatternPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;
  GridPatternPainter({required this.isDark, required this.primaryColor});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = primaryColor.withOpacity(0.03)..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += spacing) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RadarPainter extends CustomPainter {
  final double angle;
  final Color color;
  RadarPainter({required this.angle, required this.color});

  static const _networkColors = <Color>[
    Color(0xFF00F5FF),
    Color(0xFF2ED573),
    Color(0xFF7C4DFF),
    Color(0xFFFFD32A),
    Color(0xFFFF4757),
    Color(0xFFFFA502),
  ];

  Offset _polar(Offset center, double radius, double radians) {
    return Offset(
      center.dx + math.cos(radians) * radius,
      center.dy + math.sin(radians) * radius,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final phase = angle;
    final spokes = 12;
    final rings = 5;

    // Soft radar atmosphere.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.10),
            color.withOpacity(0.025),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Concentric radar rings.
    for (var i = 1; i <= rings; i++) {
      final r = radius * i / rings;
      final ringColor = _networkColors[(i - 1) % _networkColors.length];
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = ringColor.withOpacity(i == rings ? 0.28 : 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == rings ? 0.9 : 0.55,
      );
    }

    // Animated spider-web spokes.
    for (var i = 0; i < spokes; i++) {
      final a = (i * 2 * math.pi / spokes) + phase * 0.18;
      final end = _polar(center, radius, a);
      final spokeColor = _networkColors[i % _networkColors.length];
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = spokeColor.withOpacity(0.24)
          ..strokeWidth = 0.65,
      );
    }

    // Polygonal spider-web layers: each layer is rotated, creating a live
    // analytical mesh rather than a static crosshair.
    for (var layer = 1; layer <= rings; layer++) {
      final r = radius * layer / rings;
      final path = Path();
      final rotation = phase * (0.10 + layer * 0.018);
      for (var i = 0; i <= spokes; i++) {
        final a = (i * 2 * math.pi / spokes) + rotation;
        final p = _polar(center, r, a);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _networkColors[(layer + 1) % _networkColors.length]
              .withOpacity(0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }

    // Moving analytical connection nodes on the web.
    final nodes = <Offset>[];
    for (var i = 0; i < 8; i++) {
      final a = (i * 2 * math.pi / 8) + phase * (0.28 + (i % 3) * 0.035);
      final orbit = radius * (0.38 + (i % 4) * 0.12);
      nodes.add(_polar(center, orbit, a));
    }
    for (var i = 0; i < nodes.length; i++) {
      final next = nodes[(i + 1) % nodes.length];
      final nodeColor = _networkColors[i % _networkColors.length];
      canvas.drawLine(
        nodes[i],
        next,
        Paint()
          ..color = nodeColor.withOpacity(0.42)
          ..strokeWidth = 0.8,
      );
      canvas.drawCircle(
        nodes[i],
        1.7 + math.sin(phase * 3 + i) * 0.8,
        Paint()
          ..color = nodeColor.withOpacity(0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(nodes[i], 1.2, Paint()..color = nodeColor);
    }

    // Rotating sweep with a bright analytical leading edge.
    final sweepAngle = phase - math.pi / 2;
    final sweepEnd = _polar(center, radius, sweepAngle);
    canvas.drawLine(
      center,
      sweepEnd,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.05), color.withOpacity(0.9)],
        ).createShader(Rect.fromPoints(center, sweepEnd))
        ..strokeWidth = 1.4,
    );

    // Small animated center core.
    final corePulse = 2.2 + (math.sin(phase * 3) + 1) * 1.1;
    canvas.drawCircle(
      center,
      corePulse + 3,
      Paint()
        ..color = color.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(center, corePulse, Paint()..color = color.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.color != color;
}
