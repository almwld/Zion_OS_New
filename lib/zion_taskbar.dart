import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/window_manager/core/window_manager.dart';

class ZionTaskbar extends StatelessWidget {
  const ZionTaskbar({super.key, this.onOpenApp, this.categories = const [], this.selectedCategory = 0, this.onCategorySelected, this.onStart});
  final void Function(String appKey)? onOpenApp;
  final List<Map<String, dynamic>> categories;
  final int selectedCategory;
  final ValueChanged<int>? onCategorySelected;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final wm = context.watch<WindowManager>();
    final windows = wm.windows.where((w) => w.workspace == wm.activeWorkspace).toList();
    return Container(
      height: 86,
      decoration: BoxDecoration(color: const Color(0xFF09051A).withOpacity(0.96), border: const Border(top: BorderSide(color: Color(0xFF7C4DFF)))),
      child: Column(children: [
        SizedBox(height: 40, child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), scrollDirection: Axis.horizontal,
          itemCount: categories.length, separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final cat = categories[index], color = cat['color'] as Color, active = selectedCategory == index;
            return GestureDetector(onTap: () => onCategorySelected?.call(index), child: AnimatedContainer(
              duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: active ? color.withOpacity(0.22) : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? color : color.withOpacity(0.28))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(cat['icon'] as IconData, color: color, size: 15), const SizedBox(width: 5), Text(cat['nameAr'] as String, style: TextStyle(color: color, fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.w600))]),
            ));
          },
        )),
        Expanded(child: Row(children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4, top: 5, bottom: 2),
            child: GestureDetector(
              onTap: onStart,
              child: Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(color: const Color(0xFF7C4DFF).withOpacity(0.18), borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.7))),
                child: const Icon(Icons.apps_rounded, color: Color(0xFFB388FF), size: 19),
              ),
            ),
          ),
          ...List.generate(WindowManager.workspaceCount, (i) => _TaskbarButton(icon: Icons.workspaces, label: 'W' + (i + 1).toString(), isActive: wm.activeWorkspace == i, onTap: () => wm.switchWorkspace(i))),
          const SizedBox(width: 4),
          Expanded(child: ListView(scrollDirection: Axis.horizontal, children: windows.map((window) {
            final active = wm.activeWindowId == window.id;
            return _TaskbarButton(icon: window.isMinimized ? Icons.remove : Icons.desktop_windows, label: window.title, isActive: active, onTap: () { if (window.isMinimized) wm.restore(window.id); else if (active) wm.minimize(window.id); else wm.focus(window.id); });
          }).toList())),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(_time(), style: const TextStyle(color: Color(0xFF7C4DFF), fontSize: 11))),
        ])),
      ]),
    );
  }

  String _time() { final n = DateTime.now(); return n.hour.toString().padLeft(2, '0') + ':' + n.minute.toString().padLeft(2, '0'); }
}

class _TaskbarButton extends StatelessWidget {
  final IconData icon; final String label; final bool isActive; final VoidCallback onTap;
  const _TaskbarButton({required this.icon, required this.label, this.isActive = false, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 9), margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
    decoration: BoxDecoration(color: isActive ? const Color(0xFF7C4DFF).withOpacity(0.14) : Colors.transparent, borderRadius: BorderRadius.circular(7)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFF7C4DFF), size: 13), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Color(0xFF7C4DFF), fontSize: 10))]),
  ));
}
