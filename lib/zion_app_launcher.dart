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

class ZionAppLauncher extends StatefulWidget {
  const ZionAppLauncher({super.key});
  @override State<ZionAppLauncher> createState() => _ZionAppLauncherState();
}

class _ZionAppLauncherState extends State<ZionAppLauncher> {
  final TextEditingController _search = TextEditingController();
  @override void dispose() { _search.dispose(); super.dispose(); }


  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final apps = <({String category, Widget item})>[
      (category: 'أدوات النظام', item: _AppItem(icon: Icons.terminal, name: 'الطرفية', onTap: () => _openApp(context, 'Terminal', const TerminalScreen(), 600, 400))),
      (category: 'أدوات النظام', item: _AppItem(icon: Icons.folder, name: 'مدير الملفات', onTap: () => _openApp(context, 'Files', const ZionFileManager(), 600, 400))),
      (category: 'أدوات النظام', item: _AppItem(icon: Icons.edit, name: 'محرر النصوص', onTap: () => _openApp(context, 'Editor', const _TextEditor(), 600, 450))),
      (category: 'أدوات النظام', item: _AppItem(icon: Icons.language, name: 'متصفح Zion', onTap: () => _openApp(context, 'Browser', const ZionBrowser(), 800, 500))),
      (category: 'أدوات النظام', item: _AppItem(icon: Icons.monitor, name: 'مراقب النظام', onTap: () => _openApp(context, 'Monitor', const ZionSystemMonitor(), 350, 400))),
      (category: 'أدوات النظام', item: _AppItem(icon: Icons.psychology, name: 'الذكاء المحلي Offline AI', onTap: () => _openApp(context, 'Offline AI', const AIChatScreen(), 700, 600))),
      (category: 'أدوات النظام', item: _AppItem(icon: Icons.hub, name: 'مركز الوكلاء والذكاء المتقدم', onTap: () => _openApp(context, 'Zion AI Center', const AdvancedAICenter(), 760, 720))),
      (category: 'أدوات النظام', item: _AppItem(icon: Icons.smart_toy, name: 'Zion Agent', onTap: () => _openApp(context, 'Zion Agent', const AgentScreen(), 820, 700))),
      (category: 'الأمان والتشخيص', item: _AppItem(icon: Icons.security, name: 'مركز الأمان', onTap: () => _openApp(context, 'Security', const SecurityCenter(), 650, 560))),
    ];
    final filtered = query.isEmpty ? apps : apps.where((a) => (a.item as _AppItem).name.toLowerCase().contains(query)).toList();
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
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
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
              children: query.isNotEmpty && filtered.isEmpty
                  ? [const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد تطبيقات مطابقة', style: TextStyle(color: Colors.white54))))]
                  : filtered.map((a) => a.item).toList(),
                const _AppCategory(title: 'أدوات النظام'),
                _AppItem(icon: Icons.terminal, name: 'الطرفية', onTap: () => _openApp(context, 'Terminal', const TerminalScreen(), 600, 400)),
                _AppItem(icon: Icons.folder, name: 'مدير الملفات', onTap: () => _openApp(context, 'Files', const ZionFileManager(), 600, 400)),
                _AppItem(icon: Icons.edit, name: 'محرر النصوص', onTap: () => _openApp(context, 'Editor', const _TextEditor(), 600, 450)),
                _AppItem(icon: Icons.language, name: 'متصفح Zion', onTap: () => _openApp(context, 'Browser', const ZionBrowser(), 800, 500)),
                _AppItem(icon: Icons.monitor, name: 'مراقب النظام', onTap: () => _openApp(context, 'Monitor', const ZionSystemMonitor(), 350, 400)),
                _AppItem(icon: Icons.psychology, name: 'الذكاء المحلي Offline AI', onTap: () => _openApp(context, 'Offline AI', const AIChatScreen(), 700, 600)),
                _AppItem(icon: Icons.hub, name: 'مركز الوكلاء والذكاء المتقدم', onTap: () => _openApp(context, 'Zion AI Center', const AdvancedAICenter(), 760, 720)),
                _AppItem(icon: Icons.smart_toy, name: 'Zion Agent', onTap: () => _openApp(context, 'Zion Agent', const AgentScreen(), 820, 700)),
                const SizedBox(height: 16),
                const _AppCategory(title: 'الأمان والتشخيص'),
                _AppItem(icon: Icons.security, name: 'مركز الأمان', onTap: () => _openApp(context, 'Security', const SecurityCenter(), 650, 560)),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openApp(BuildContext context, String title, Widget content, double width, double height) {
    context.read<WindowManager>().open(title: title, content: content, width: width, height: height);
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
