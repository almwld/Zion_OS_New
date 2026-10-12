import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/window_manager/core/window_manager.dart';

/// A single compact desktop bar: launcher, categories, workspaces and open apps.
/// Keep the clock in the desktop header only to avoid duplicate time displays.
class ZionTaskbar extends StatelessWidget {
  const ZionTaskbar({
    super.key,
    this.onOpenApp,
    this.categories = const [],
    this.selectedCategory = 0,
    this.onCategorySelected,
    this.onStart,
  });

  final void Function(String appKey)? onOpenApp;
  final List<Map<String, dynamic>> categories;
  final int selectedCategory;
  final ValueChanged<int>? onCategorySelected;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final wm = context.watch<WindowManager>();
    final windows =
        wm.windows.where((w) => w.workspace == wm.activeWorkspace).toList();
    final fallbackAccent = Theme.of(context).colorScheme.primary;
    final selectedAccent = categories.isNotEmpty &&
            selectedCategory >= 0 &&
            selectedCategory < categories.length
        ? categories[selectedCategory]['color'] as Color? ?? fallbackAccent
        : fallbackAccent;

    return SafeArea(
      top: false,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xF20B1220)
              : const Color(0xF7FFFFFF),
          border: Border(
            top: BorderSide(color: selectedAccent.withOpacity(0.42)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.06,
              ),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
              child: Tooltip(
                message: 'قائمة التطبيقات',
                child: Material(
                  color: selectedAccent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onStart,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 40,
                      height: 38,
                      child: Icon(Icons.apps_rounded,
                          color: selectedAccent, size: 21),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
                children: [
                  for (var i = 0; i < categories.length; i++)
                    _CategoryButton(
                      category: categories[i],
                      isActive: selectedCategory == i,
                      onTap: () => onCategorySelected?.call(i),
                      fallbackColor: fallbackAccent,
                    ),
                  if (categories.isNotEmpty)
                    Container(
                      width: 1,
                      height: 26,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 8),
                      color: selectedAccent.withOpacity(0.22),
                    ),
                  for (var i = 0; i < WindowManager.workspaceCount; i++)
                    _TaskbarButton(
                      icon: Icons.workspaces_outline,
                      label: 'مساحة ${i + 1}',
                      isActive: wm.activeWorkspace == i,
                      accent: selectedAccent,
                      onTap: () => wm.switchWorkspace(i),
                    ),
                  for (final window in windows)
                    _TaskbarButton(
                      icon: window.isMinimized
                          ? Icons.remove
                          : Icons.desktop_windows_outlined,
                      label: window.title,
                      isActive: wm.activeWindowId == window.id,
                      accent: selectedAccent,
                      onTap: () {
                        if (window.isMinimized) {
                          wm.restore(window.id);
                        } else if (wm.activeWindowId == window.id) {
                          wm.minimize(window.id);
                        } else {
                          wm.focus(window.id);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.isActive,
    required this.onTap,
    required this.fallbackColor,
  });

  final Map<String, dynamic> category;
  final bool isActive;
  final VoidCallback onTap;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final color = category['color'] as Color? ?? fallbackColor;
    final icon = category['icon'] as IconData? ?? Icons.apps;
    final label = category['nameAr'] as String? ??
        category['name'] as String? ??
        'تطبيقات';

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Tooltip(
        message: label,
        child: Material(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? color.withOpacity(0.75) : color.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskbarButton extends StatelessWidget {
  const _TaskbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 3),
      child: Tooltip(
        message: label,
        child: Material(
          color: isActive ? accent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              constraints: const BoxConstraints(minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isActive ? accent.withOpacity(0.55) : accent.withOpacity(0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: accent, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
