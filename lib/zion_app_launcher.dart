import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/window_manager/core/window_manager.dart';
import 'features/terminal/terminal_screen.dart';
import 'zion_browser.dart';
import 'zion_file_manager.dart';
import 'zion_system_monitor.dart';
import 'src/features/security_center/security_center.dart';
import 'ai/widgets/ai_chat_screen.dart';
import 'src/features/ai/advanced_ai_center.dart';
import 'agent/ui/agent_screen.dart';
import 'agent/ui/system_agents_screen.dart';
import 'services/preferences_service.dart';

class ZionAppLauncher extends StatefulWidget {
  const ZionAppLauncher({
    this.apps,
    this.iconSize = 55,
    this.iconsPerRow = 4,
    this.showAppNames = true,
    this.isDark = true,
    this.accentColor = const Color(0xFF00FF41),
    this.onOpenApp,
    super.key,
  });
  final List<Map<String, dynamic>>? apps;
  final double iconSize;
  final int iconsPerRow;
  final bool showAppNames;
  final bool isDark;
  final Color accentColor;
  final void Function(Map<String, dynamic> app)? onOpenApp;

  @override
  State<ZionAppLauncher> createState() => _ZionAppLauncherState();
}

class _ZionAppLauncherState extends State<ZionAppLauncher> {
  final _search = TextEditingController();
  List<String> _order = <String>[];

  final _legacyApps = <_LauncherApp>[
    _LauncherApp('أدوات النظام','الطرفية',Icons.terminal,'Terminal',600,400),
    _LauncherApp('أدوات النظام','مدير الملفات',Icons.folder,'Files',600,400),
    _LauncherApp('أدوات النظام','محرر النصوص',Icons.edit,'Editor',600,450),
    _LauncherApp('أدوات النظام','متصفح Zion',Icons.language,'Browser',800,500),
    _LauncherApp('أدوات النظام','مراقب النظام',Icons.monitor,'Monitor',350,400),
    _LauncherApp('أدوات النظام','الذكاء المحلي Offline AI',Icons.psychology,'Offline AI',700,600),
    _LauncherApp('أدوات النظام','مركز الوكلاء والذكاء المتقدم',Icons.hub,'Zion AI Center',760,720),
    _LauncherApp('الذكاء والوكلاء','Super Agent',Icons.auto_awesome,'Zion Agent',900,760),
    _LauncherApp('أدوات النظام','وكلاء النظام',Icons.hub,'System Agents',760,650),
    _LauncherApp('الأمان والتشخيص','مركز الأمان',Icons.security,'Security',650,560),
  ];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final apps = widget.apps;
    if (apps == null) return;
    final saved = context.read<PreferencesService>().launcherOrder;
    final available = apps.map((a) => a['name'] as String).toSet();
    final next = <String>[];
    for (final name in saved) { if (available.contains(name)) next.add(name); }
    for (final app in apps) {
      final name = app['name'] as String;
      if (!next.contains(name)) next.add(name);
    }
    if (next.join('|') != _order.join('|')) _order = next;
  }

  Map<String, dynamic>? _app(String name) {
    for (final app in widget.apps ?? const <Map<String, dynamic>>[]) {
      if (app['name'] == name) return app;
    }
    return null;
  }

  Future<void> _persistOrder() async {
    final prefs = context.read<PreferencesService>();
    final currentNames = (widget.apps ?? const <Map<String, dynamic>>[]).map((a) => a['name'] as String).toSet();
    if (currentNames.isEmpty) return;
    final saved = prefs.launcherOrder.where((name) => !currentNames.contains(name)).toList();
    final rebuilt = <String>[];
    var inserted = false;
    for (final name in prefs.launcherOrder) {
      if (currentNames.contains(name)) {
        if (!inserted) { rebuilt.addAll(_order); inserted = true; }
      } else if (!rebuilt.contains(name)) {
        rebuilt.add(name);
      }
    }
    if (!inserted) rebuilt.addAll(_order);
    await prefs.setLauncherOrder(rebuilt.isEmpty ? saved + _order : rebuilt);
  }

  void _moveBefore(String dragged, String target) {
    if (dragged == target) return;
    final from = _order.indexOf(dragged);
    if (from < 0 || !_order.contains(target)) return;
    setState(() {
      _order.removeAt(from);
      final targetIndex = _order.indexOf(target);
      _order.insert(targetIndex < 0 ? _order.length : targetIndex, dragged);
    });
    _persistOrder();
  }

  Future<void> _showDisplaySettings() async {
    final prefs = context.read<PreferencesService>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: widget.isDark ? const Color(0xFF101827) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final size = prefs.iconSize;
          return SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Icon(Icons.tune, color: widget.accentColor), const SizedBox(width: 10),
                Expanded(child: Text('تخصيص المشغّل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87))),
                IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
              ]),
              Align(alignment: Alignment.centerRight, child: Text('حجم الأيقونات: ' + size.round().toString() + '%')),
              Slider(min: prefs.minIconSize, max: prefs.maxIconSize, value: size, onChanged: (v) { setSheetState(() {}); prefs.setIconSize(v); }),
              Align(alignment: Alignment.centerRight, child: Text('الأعمدة: ' + prefs.iconsPerRow.toString())),
              SegmentedButton<int>(
                segments: const [ButtonSegment(value: 3, label: Text('3')), ButtonSegment(value: 4, label: Text('4')), ButtonSegment(value: 5, label: Text('5'))],
                selected: {prefs.iconsPerRow},
                onSelectionChanged: (v) { if (v.isNotEmpty) { prefs.setIconsPerRow(v.first); setSheetState(() {}); } },
              ),
              SwitchListTile.adaptive(title: const Text('إظهار أسماء التطبيقات'), value: prefs.showAppNames, onChanged: (v) { prefs.setShowAppNames(v); setSheetState(() {}); }),
              ListTile(leading: Icon(Icons.restore, color: widget.accentColor), title: const Text('إعادة ترتيب التطبيقات افتراضياً'), onTap: () async {
                setState(() { _order = (widget.apps ?? const <Map<String, dynamic>>[]).map((a) => a['name'] as String).toList(); });
                await _persistOrder();
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              }),
            ]),
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.apps == null) return _buildLegacy(context);
    final ordered = <Map<String, dynamic>>[];
    for (final name in _order) { final app = _app(name); if (app != null) ordered.add(app); }
    return Stack(children: [
      GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 92),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.iconsPerRow, crossAxisSpacing: 10, mainAxisSpacing: 10,
          mainAxisExtent: widget.iconSize + (widget.showAppNames ? 46 : 22),
        ),
        itemCount: ordered.length,
        itemBuilder: (context, index) {
          final app = ordered[index], name = app['name'] as String;
          return DragTarget<String>(
            onWillAcceptWithDetails: (details) => details.data != name,
            onAcceptWithDetails: (details) => _moveBefore(details.data, name),
            builder: (context, candidate, rejected) => LongPressDraggable<String>(
              data: name,
              feedback: Material(color: Colors.transparent, child: _iconTile(app, dragging: true)),
              childWhenDragging: Opacity(opacity: 0.25, child: _iconTile(app)),
              child: _iconTile(app, highlighted: candidate.isNotEmpty),
            ),
          );
        },
      ),
      Positioned(left: 14, bottom: 14, child: Material(
        color: widget.isDark ? const Color(0xDD101827) : const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(18),
        child: IconButton(tooltip: 'تخصيص المشغّل', onPressed: _showDisplaySettings, icon: Icon(Icons.tune, color: widget.accentColor)),
      )),
    ]);
  }

  Widget _iconTile(Map<String, dynamic> app, {bool dragging = false, bool highlighted = false}) {
    final color = widget.accentColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withOpacity(0.045) : Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: highlighted ? color : color.withOpacity(0.18), width: highlighted ? 2 : 1),
        boxShadow: dragging ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 18)] : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => widget.onOpenApp?.call(app),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: widget.iconSize, height: widget.iconSize, decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(widget.iconSize * 0.27), border: Border.all(color: color.withOpacity(0.42))), child: Icon(app['icon'] as IconData, color: color, size: widget.iconSize * 0.5)),
          if (widget.showAppNames) ...[
            const SizedBox(height: 7),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(app['nameAr'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.w600))),
          ],
        ])),
      ),
    );
  }

  Widget _buildLegacy(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = _legacyApps.where((a) => q.isEmpty || a.name.toLowerCase().contains(q) || a.title.toLowerCase().contains(q)).toList();
    return Container(width: 400, height: 500, decoration: BoxDecoration(color: const Color(0xFF0A0E0A), border: Border.all(color: const Color(0xFF00FF41).withOpacity(.5)), borderRadius: BorderRadius.circular(12)), child: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _search, onChanged: (_) => setState(() {}), style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14), decoration: const InputDecoration(hintText: 'ابحث عن تطبيق...', hintStyle: TextStyle(color: Color(0x8000FF41)), prefixIcon: Icon(Icons.search, color: Color(0xFF00FF41)), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)))))),
      Expanded(child: ListView(padding: const EdgeInsets.all(8), children: [
        if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد تطبيقات مطابقة', style: TextStyle(color: Colors.white54)))),
        for (final group in ['أدوات النظام','الأمان والتشخيص'])
          if (filtered.any((a) => a.category == group)) ...[
            _AppCategory(title: group),
            for (final a in filtered.where((a) => a.category == group)) _AppItem(icon: a.icon, name: a.name, onTap: () => _openLegacyApp(context, a)),
          ],
      ])),
    ]));
  }

  void _openLegacyApp(BuildContext context, _LauncherApp app) => context.read<WindowManager>().open(title: app.title, content: _content(app.title), width: app.width, height: app.height, appKey: app.title);

  Widget _content(String title) {
    switch (title) {
      case 'Terminal': return const TerminalScreen();
      case 'Files': return const ZionFileManager();
      case 'Editor': return const _TextEditor();
      case 'Browser': return const ZionBrowser();
      case 'Monitor': return const ZionSystemMonitor();
      case 'Offline AI': return const AIChatScreen();
      case 'Zion AI Center': return const AdvancedAICenter();
      case 'Zion Agent': return const AgentScreen();
      case 'System Agents': return const SystemAgentsScreen();
      case 'Security': return const SecurityCenter();
      default: return const SizedBox.shrink();
    }
  }
}

class _LauncherApp { const _LauncherApp(this.category, this.name, this.icon, this.title, this.width, this.height); final String category, name, title; final IconData icon; final double width, height; }
class _AppCategory extends StatelessWidget { const _AppCategory({required this.title}); final String title; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(title, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 14, fontWeight: FontWeight.bold))); }
class _AppItem extends StatelessWidget { const _AppItem({required this.icon, required this.name, required this.onTap}); final IconData icon; final String name; final VoidCallback onTap; @override Widget build(BuildContext context) => ListTile(leading: Icon(icon, color: const Color(0xFF00FF41), size: 22), title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)), dense: true, onTap: onTap); }
class _TextEditor extends StatefulWidget { const _TextEditor(); @override State<_TextEditor> createState() => _TextEditorState(); }
class _TextEditorState extends State<_TextEditor> { final _controller = TextEditingController(); @override void dispose() { _controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _controller, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'اكتب النص هنا...'))); }
