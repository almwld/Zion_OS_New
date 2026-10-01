import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/window_manager/core/window_manager.dart';
import 'zion_desktop_icons.dart';
import 'zion_system_monitor.dart';

class ZionTaskbar extends StatelessWidget {
  const ZionTaskbar({super.key, this.onOpenApp});
  final void Function(String appKey)? onOpenApp;

  @override
  Widget build(BuildContext context) {
    final wm = context.watch<WindowManager>();
    final workspaceWindows = wm.windows.where((w) => w.workspace == wm.activeWorkspace).toList();
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E0A),
        border: Border(top: BorderSide(color: Color(0xFF1A3A1A))),
      ),
      child: Row(
        children: [
          _TaskbarButton(icon: Icons.menu, label: 'ابدأ', onTap: () => _showStartMenu(context)),
          const SizedBox(width: 6),
          ...List.generate(WindowManager.workspaceCount, (i) => _TaskbarButton(icon: Icons.workspaces, label: 'W${i + 1}', isActive: wm.activeWorkspace == i, onTap: () => wm.switchWorkspace(i))),
          const SizedBox(width: 6),
          Expanded(child: ListView(scrollDirection: Axis.horizontal, children: workspaceWindows.map((window) {
            final active = wm.activeWindowId == window.id;
            return _TaskbarButton(
              icon: window.isMinimized ? Icons.remove : Icons.desktop_windows,
              label: window.title,
              isActive: active,
              onTap: () { if (window.isMinimized) { wm.restore(window.id); } else if (active) { wm.minimize(window.id); } else { wm.focus(window.id); } },
            );
          }).toList())),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(time, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 12))),
        ],
      ),
    );
  }

  void _showStartMenu(BuildContext context) {
    final wm = context.read<WindowManager>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFF00FF41))),
        title: const Text('Zion Linux', style: TextStyle(color: Color(0xFF00FF41))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StartMenuItem(icon: Icons.terminal, label: 'الطرفية', onTap: () { Navigator.pop(ctx); onOpenApp?.call('TERMINAL'); }),
            _StartMenuItem(icon: Icons.monitor_heart, label: 'مراقب النظام', onTap: () { Navigator.pop(ctx); onOpenApp?.call('SYSTEM'); }),
            _StartMenuItem(icon: Icons.network_check, label: 'تشخيص الشبكة', onTap: () { Navigator.pop(ctx); onOpenApp?.call('NETWORK'); }),
            const Divider(color: Color(0xFF1A3A1A)),
            _StartMenuItem(icon: Icons.power_settings_new, label: 'إيقاف التشغيل', onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }
}

class _StartMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _StartMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon, color: const Color(0xFF00FF41), size: 20), title: Text(label, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 14)), dense: true, onTap: onTap);
  }
}

class _TaskbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TaskbarButton({required this.icon, required this.label, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00FF41).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isActive ? const Color(0xFF00FF41) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00FF41), size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
