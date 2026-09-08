import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/wm/window_manager.dart';
import 'zion_browser.dart';
import 'zion_file_manager.dart';
import 'zion_system_monitor.dart';

class ZionAppLauncher extends StatelessWidget {
  const ZionAppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E0A),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ابحث عن تطبيق...',
                hintStyle: TextStyle(color: const Color(0xFF00FF41).withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF41)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                const _AppCategory(title: 'أدوات النظام'),
                _AppItem(icon: Icons.terminal, name: 'الطرفية', onTap: () => _openApp(context, 'Terminal', const _TerminalUnavailable(), 600, 400)),
                _AppItem(icon: Icons.folder, name: 'مدير الملفات', onTap: () => _openApp(context, 'Files', const ZionFileManager(), 600, 400)),
                _AppItem(icon: Icons.edit, name: 'محرر النصوص', onTap: () => _openApp(context, 'Editor', const _TextEditor(), 600, 450)),
                _AppItem(icon: Icons.language, name: 'متصفح Zion', onTap: () => _openApp(context, 'Browser', const ZionBrowser(), 800, 500)),
                _AppItem(icon: Icons.monitor, name: 'مراقب النظام', onTap: () => _openApp(context, 'Monitor', const ZionSystemMonitor(), 350, 400)),
                const SizedBox(height: 16),
                const _AppCategory(title: 'الأمان والتشخيص'),
                _AppItem(icon: Icons.network_check, name: 'تشخيص الشبكة', onTap: () => _openApp(context, 'Network Diagnostics', const _SafePlaceholder(title: 'Network Diagnostics'), 600, 400)),
                _AppItem(icon: Icons.security, name: 'مركز الأمان', onTap: () => _openApp(context, 'Security', const _SafePlaceholder(title: 'Security Center'), 600, 400)),
                _AppItem(icon: Icons.health_and_safety, name: 'سلامة النظام', onTap: () => _openApp(context, 'System Safety', const _SafePlaceholder(title: 'System Safety'), 600, 400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openApp(BuildContext context, String title, Widget content, double width, double height) {
    context.read<WindowManager>().open(title, content, width: width, height: height);
  }
}

class _AppCategory extends StatelessWidget {
  final String title;
  const _AppCategory({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(title, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 14, fontWeight: FontWeight.bold)),
  );
}

class _AppItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final VoidCallback onTap;
  const _AppItem({required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: const Color(0xFF00FF41), size: 22),
    title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
    dense: true,
    onTap: onTap,
  );
}

class _SafePlaceholder extends StatelessWidget {
  final String title;
  const _SafePlaceholder({required this.title});

  @override
  Widget build(BuildContext context) => Center(
    child: Text('$title\nDefensive diagnostics only', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
  );
}

class _TerminalUnavailable extends StatelessWidget {
  const _TerminalUnavailable();
  @override
  Widget build(BuildContext context) => const _SafePlaceholder(title: 'Terminal is available from the main Terminal screen');
}

class _TextEditor extends StatefulWidget {
  const _TextEditor();
  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  final _controller = TextEditingController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      controller: _controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'اكتب النص هنا...'),
    ),
  );
}
