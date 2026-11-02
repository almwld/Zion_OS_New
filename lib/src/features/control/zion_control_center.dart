import 'dart:io';

import 'package:flutter/material.dart';

import '../../../ai/llama_service.dart';
import '../../../core/userland/zion_bootstrap.dart';
import '../../../core/userland/zion_userland_installer.dart';
import '../../../features/terminal/terminal_capabilities.dart';
import '../../../features/terminal/terminal_screen.dart';
import '../backup/backup_manager.dart';
import '../developer/developer_center.dart';
import '../packages/package_manager.dart';
import '../security_center/security_center.dart';
import '../storage/disk_usage_analyzer.dart';
import '../system/system_monitor.dart';
import '../wifi/zion_wifi_panel.dart';
import '../windows/zion_file_manager.dart';

class ZionControlCenter extends StatefulWidget {
  const ZionControlCenter({super.key});

  @override
  State<ZionControlCenter> createState() => _ZionControlCenterState();
}

class _ZionControlCenterState extends State<ZionControlCenter> {
  bool _loading = true;
  String? _refreshError;
  final List<_Capability> _capabilities = <_Capability>[];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading && _capabilities.isNotEmpty) return;
    if (mounted) {
      setState(() {
        _loading = true;
        _refreshError = null;
      });
    }

    try {
      final results = await Future.wait<Object>([
        _describeRuntime(),
        _probe(_shellPath, const <String>['-c', 'exit 0']),
        _probe('git', const <String>['--version']),
        _probe('python', const <String>['--version']),
        _probe('df', const <String>['-h', '/']),
        _inspectUserland(),
        _inspectAiModels(),
      ]);

      if (!mounted) return;
      final runtime = results[0] as String;
      final shell = results[1] as bool;
      final git = results[2] as bool;
      final python = results[3] as bool;
      final storage = results[4] as bool;
      final userland = results[5] as _Capability;
      final ai = results[6] as _Capability;

      setState(() {
        _capabilities
          ..clear()
          ..addAll([
            _Capability(
              'Terminal / shell',
              shell,
              shell ? 'تم تنفيذ اختبار shell بنجاح' : 'تعذر تنفيذ shell على هذه البيئة',
            ),
            _Capability(
              'Zion runtime',
              runtime.contains('AVAILABLE'),
              runtime,
            ),
            userland,
            _Capability(
              'Git',
              git,
              git ? 'تم العثور على Git وتشغيل --version' : 'Git غير متاح في PATH الحالي',
            ),
            _Capability(
              'Python',
              python,
              python ? 'تم العثور على Python وتشغيل --version' : 'Python غير متاح في PATH الحالي',
            ),
            _Capability(
              'Storage telemetry',
              storage,
              storage ? 'قراءة df نجحت' : 'تعذر قراءة مساحة التخزين',
            ),
            ai,
            const _Capability(
              'P2P',
              false,
              'لا توجد خدمة P2P متصلة بمركز التحكم حالياً',
              configured: false,
            ),
          ]);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshError = 'تعذر تحديث مؤشرات النظام: $error';
      });
    }
  }

  String get _shellPath => Platform.isAndroid ? '/system/bin/sh' : '/bin/sh';

  Future<String> _describeRuntime() async {
    try {
      return await TerminalCapabilities.describeRuntime()
          .timeout(const Duration(seconds: 5));
    } catch (error) {
      return 'Runtime status unavailable: $error';
    }
  }

  Future<bool> _probe(String command, List<String> args) async {
    try {
      final result = await Process.run(
        command,
        args,
        runInShell: false,
      ).timeout(const Duration(seconds: 3));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<_Capability> _inspectUserland() async {
    try {
      final installed = await const ZionUserlandInstaller()
          .isInstalled()
          .timeout(const Duration(seconds: 5));
      if (!installed) {
        return const _Capability(
          'Zion Userland',
          false,
          'لم يتم العثور على Bash payload صالح داخل usr/',
        );
      }

      final proot = File('${ZionBootstrap.prefix}/bin/proot');
      final exists = await proot.exists();
      if (!exists) {
        return const _Capability(
          'Zion Userland',
          true,
          'بيانات Bash موجودة؛ ملف PRoot غير موجود',
        );
      }
      final stat = await proot.stat();
      final executable = (stat.mode & 0x49) != 0;
      return _Capability(
        'Zion Userland',
        true,
        executable
            ? 'Bash وملف PRoot موجودان؛ لم يُجر اختبار تشغيل PRoot هنا'
            : 'Bash موجود؛ ملف PRoot غير قابل للتنفيذ',
      );
    } catch (error) {
      return _Capability(
        'Zion Userland',
        false,
        'تعذر فحص بيانات التثبيت: $error',
      );
    }
  }

  Future<_Capability> _inspectAiModels() async {
    try {
      final models = await LlamaService()
          .discoverModels()
          .timeout(const Duration(seconds: 8));
      final usable = models.where(
        (model) =>
            model.readable &&
            model.path.isNotEmpty &&
            model.sizeBytes > 0,
      );
      final count = usable.length;
      return _Capability(
        'Local AI models',
        count > 0,
        count > 0
            ? 'تم اكتشاف $count نموذج محلي قابل للقراءة؛ لم يتم تحميله تلقائياً'
            : 'لم يتم اكتشاف نموذج GGUF قابل للقراءة',
      );
    } catch (error) {
      return _Capability(
        'Local AI models',
        false,
        'تعذر فحص النماذج المحلية: $error',
      );
    }
  }

  void _open(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _capabilities.where((capability) => capability.available).length;
    final total = _capabilities.length;

    return Scaffold(
      backgroundColor: const Color(0xFF070B10),
      appBar: AppBar(
        title: const Text('Zion Control Center'),
        backgroundColor: const Color(0xFF101923),
        actions: [
          IconButton(
            tooltip: 'تحديث الحالة',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF00BCD4)),
                color: const Color(0xFF0D1720),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hub, color: Color(0xFF00BCD4), size: 42),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ZION OS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _loading
                              ? 'جارٍ فحص القدرات الفعلية…'
                              : '$ready/$total قدرات متاحة وفق الفحص الحالي',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_refreshError != null) ...[
              const SizedBox(height: 10),
              ListTile(
                tileColor: const Color(0xFF321B1B),
                leading: const Icon(Icons.error_outline, color: Colors.redAccent),
                title: Text(
                  _refreshError!,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  onPressed: _loading ? null : _refresh,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Core distribution',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _action(Icons.terminal, 'Terminal', const TerminalScreen()),
                _action(Icons.inventory_2, 'Packages', const PackageManager()),
                _action(Icons.folder_copy, 'File Manager', const ZionFileManager()),
                _action(Icons.wifi_find, 'Network Center', const ZionWifiPanel()),
                _action(Icons.monitor_heart, 'System Monitor', const SystemMonitor()),
                _action(Icons.security, 'Security Center', const SecurityCenter()),
                _action(Icons.backup, 'Backup / Restore', const BackupManager()),
                _action(Icons.storage, 'Storage', const DiskUsageAnalyzer()),
                _action(Icons.code, 'Developer', const DeveloperCenter()),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Live capabilities',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading && _capabilities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ..._capabilities.map(
                (capability) => ListTile(
                  leading: Icon(
                    capability.available
                        ? Icons.check_circle
                        : capability.configured
                            ? Icons.error_outline
                            : Icons.remove_circle_outline,
                    color: capability.available
                        ? Colors.greenAccent
                        : capability.configured
                            ? Colors.orangeAccent
                            : Colors.white38,
                  ),
                  title: Text(
                    capability.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    capability.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: Text(
                    capability.available
                        ? 'AVAILABLE'
                        : capability.configured
                            ? 'UNAVAILABLE'
                            : 'NOT CONFIGURED',
                    style: TextStyle(
                      color: capability.available
                          ? Colors.greenAccent
                          : capability.configured
                              ? Colors.orangeAccent
                              : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String title, Widget page) => Card(
        color: const Color(0xFF101923),
        child: InkWell(
          onTap: () => _open(page),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF00BCD4), size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Capability {
  const _Capability(
    this.name,
    this.available,
    this.detail, {
    this.configured = true,
  });

  final String name;
  final bool available;
  final String detail;
  final bool configured;
}
