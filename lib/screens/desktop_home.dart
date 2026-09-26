import 'dart:async';
import 'package:flutter/material.dart';

class ZionDesktop extends StatefulWidget {
  const ZionDesktop({super.key});

  @override
  State<ZionDesktop> createState() => _ZionDesktopState();
}

class _ZionDesktopState extends State<ZionDesktop> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  int _selectedCategory = 0;

  static const _cyan = Color(0xFF00BCD4);
  static const _teal = Color(0xFF006064);
  static const _background = Color(0xFF05080A);

  static const _categories = ['الأدوات', 'الشبكة', 'الأمان', 'التحليل'];

  static const _apps = <_DesktopApp>[
    _DesktopApp('الطرفية', Icons.terminal),
    _DesktopApp('مدير الملفات', Icons.folder_outlined),
    _DesktopApp('المتصفح', Icons.language),
    _DesktopApp('الإعدادات', Icons.settings_outlined),
    _DesktopApp('الآلة الحاسبة', Icons.calculate_outlined),
    _DesktopApp('الملاحظات', Icons.note_alt_outlined),
    _DesktopApp('المعرض', Icons.photo_library_outlined),
    _DesktopApp('الطقس', Icons.wb_sunny_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _GridBackground()),
            Column(
              children: [
                _buildStatusBar(),
                _buildCategories(),
                Expanded(child: _buildWorkspace()),
                _buildDock(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final time = '${_two(_now.hour)}:${_two(_now.minute)}';
    final date = '${_two(_now.day)}/${_two(_now.month)}/${_now.year}';
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.72),
        border: Border(bottom: BorderSide(color: _cyan.withOpacity(.18))),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_cyan, _teal])),
            alignment: Alignment.center,
            child: const Text('Z', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          const Text('ZION OS', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const Spacer(),
          const Icon(Icons.circle, color: Colors.greenAccent, size: 9),
          const SizedBox(width: 6),
          const Text('ONLINE', style: TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(width: 18),
          Text(time, style: const TextStyle(color: _cyan, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Text(date, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final selected = index == _selectedCategory;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Material(
              color: selected ? _cyan : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => setState(() => _selectedCategory = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: selected ? Colors.transparent : _cyan.withOpacity(.28)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _categories[index],
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: selected ? Colors.black : _cyan, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 3 : 2;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text('مرحباً بك في ZION OS', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              const Text('واجهة النظام الرئيسية', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 22),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _apps.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: 1.12,
                ),
                itemBuilder: (context, index) => _buildAppCard(_apps[index]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppCard(_DesktopApp app) {
    return Material(
      color: Colors.white.withOpacity(.045),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showMessage(app.title),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cyan.withOpacity(.16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(colors: [_cyan, _teal]),
                ),
                alignment: Alignment.center,
                child: Icon(app.icon, color: Colors.white, size: 27),
              ),
              const SizedBox(height: 10),
              Text(app.title, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDock() {
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cyan.withOpacity(.17)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _dockItem(Icons.home_outlined, 'الرئيسية'),
          _dockItem(Icons.terminal, 'الطرفية'),
          _dockItem(Icons.folder_outlined, 'الملفات'),
          _dockItem(Icons.settings_outlined, 'الإعدادات'),
        ],
      ),
    );
  }

  Widget _dockItem(IconData icon, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showMessage(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _cyan, size: 23),
            const SizedBox(height: 3),
            Text(label, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white54, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  void _showMessage(String title) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title — الواجهة جاهزة.', textDirection: TextDirection.rtl),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _DesktopApp {
  final String title;
  final IconData icon;
  const _DesktopApp(this.title, this.icon);
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BCD4).withOpacity(.035)
      ..strokeWidth = .6;
    const spacing = 32.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
