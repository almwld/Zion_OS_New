import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/window_manager/core/window_manager.dart';

/// One compact, theme-driven desktop bar for app categories, workspaces and windows.
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
    final scheme = Theme.of(context).colorScheme;
    // Use the active application theme consistently; category-specific hardcoded
    // colors caused the desktop bars to look unrelated to the rest of Zion OS.
    final accent = scheme.primary;
    final surface = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xF20B1220)
        : const Color(0xF7FFFFFF);

    return SafeArea(
      top: false,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: accent.withOpacity(0.35))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 7, end: 3),
              child: Tooltip(
                message: 'قائمة التطبيقات',
                child: Material(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    onTap: onStart,
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      width: 38,
                      height: 36,
                      child: Icon(Icons.apps_rounded, color: accent, size: 20),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                children: [
                  for (var i = 0; i < categories.length; i++)
                    _TaskbarChip(
                      icon: categories[i]['icon'] as IconData? ?? Icons.apps,
                      label: categories[i]['nameAr'] as String? ??
                          categories[i]['name'] as String? ??
                          'تطبيقات',
                      isActive: selectedCategory == i,
                      accent: accent,
                      onTap: () => onCategorySelected?.call(i),
                    ),
                  if (categories.isNotEmpty)
                    Container(
                      width: 1,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                      color: accent.withOpacity(0.2),
                    ),
                  for (var i = 0; i < WindowManager.workspaceCount; i++)
                    _TaskbarChip(
                      icon: Icons.workspaces_outline,
                      label: 'مساحة ${i + 1}',
                      isActive: wm.activeWorkspace == i,
                      accent: accent,
                      onTap: () => wm.switchWorkspace(i),
                    ),
                  for (final window in windows)
                    _TaskbarChip(
                      icon: window.isMinimized
                          ? Icons.remove
                          : Icons.desktop_windows_outlined,
                      label: window.title,
                      isActive: wm.activeWindowId == window.id,
                      accent: accent,
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

class _TaskbarChip extends StatelessWidget {
  const _TaskbarChip({
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
        child: Semantics(
          button: true,
          selected: isActive,
          label: label,
          child: Material(
            color: isActive ? accent.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isActive
                        ? accent.withOpacity(0.6)
                        : accent.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accent, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: schemeOnSurface(context),
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color schemeOnSurface(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface;
