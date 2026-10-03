import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';

class ZionAppLauncher extends StatefulWidget {
  const ZionAppLauncher({
    required this.apps, required this.iconSize, required this.iconsPerRow,
    required this.showAppNames, required this.isDark, required this.accentColor,
    required this.onOpenApp, super.key,
  });
  final List<Map<String, dynamic>> apps;
  final double iconSize;
  final int iconsPerRow;
  final bool showAppNames;
  final bool isDark;
  final Color accentColor;
  final void Function(Map<String, dynamic> app) onOpenApp;

  @override
  State<ZionAppLauncher> createState() => _ZionAppLauncherState();
}

class _ZionAppLauncherState extends State<ZionAppLauncher> {
  List<String> _order = <String>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final saved = context.read<PreferencesService>().launcherOrder;
    final available = widget.apps.map((a) => a['name'] as String).toSet();
    final next = <String>[];
    for (final name in saved) { if (available.contains(name)) next.add(name); }
    for (final app in widget.apps) {
      final name = app['name'] as String;
      if (!next.contains(name)) next.add(name);
    }
    if (next.join('|') != _order.join('|')) _order = next;
  }

  Map<String, dynamic>? _app(String name) {
    for (final app in widget.apps) { if (app['name'] == name) return app; }
    return null;
  }

  Future<void> _persistOrder() => context.read<PreferencesService>().setLauncherOrder(_order);

  void _moveBefore(String dragged, String target) {
    if (dragged == target) return;
    final from = _order.indexOf(dragged), to = _order.indexOf(target);
    if (from < 0 || to < 0) return;
    setState(() {
      _order.removeAt(from);
      final adjusted = _order.indexOf(target);
      _order.insert(adjusted < 0 ? _order.length : adjusted, dragged);
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
              ListTile(leading: Icon(Icons.restore, color: widget.accentColor), title: const Text('إعادة ترتيب التطبيقات افتراضياً'), onTap: () async { setState(() { _order = widget.apps.map((a) => a['name'] as String).toList(); }); await _persistOrder(); if (sheetContext.mounted) Navigator.pop(sheetContext); }),
            ]),
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      Positioned(
        left: 14, bottom: 14,
        child: Material(
          color: widget.isDark ? const Color(0xDD101827) : const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(18),
          child: IconButton(tooltip: 'تخصيص المشغّل', onPressed: _showDisplaySettings, icon: Icon(Icons.tune, color: widget.accentColor)),
        ),
      ),
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
        onTap: () => widget.onOpenApp(app),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: widget.iconSize, height: widget.iconSize,
            decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(widget.iconSize * 0.27), border: Border.all(color: color.withOpacity(0.42))),
            child: Icon(app['icon'] as IconData, color: color, size: widget.iconSize * 0.5),
          ),
          if (widget.showAppNames) ...[
            const SizedBox(height: 7),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(app['nameAr'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.w600))),
          ],
        ])),
      ),
    );
  }
}
