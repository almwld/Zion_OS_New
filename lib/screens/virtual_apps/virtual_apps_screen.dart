import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// First milestone of Zion Virtual Apps: safely import and catalogue APKs.
/// Imported packages are not reported as running until a real container runtime
/// is integrated and verified.
class VirtualAppsScreen extends StatefulWidget {
  const VirtualAppsScreen({super.key});

  @override
  State<VirtualAppsScreen> createState() => _VirtualAppsScreenState();
}

class _VirtualAppsScreenState extends State<VirtualAppsScreen> {
  static const _channel = MethodChannel('zion.os/virtual_apps');
  static const _cyan = Color(0xFF00BCD4);
  List<Map<String, dynamic>> _apps = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _channel.invokeListMethod<dynamic>('list');
      if (!mounted) return;
      setState(() {
        _apps = (result ?? const []).whereType<Map>().map(
          (item) => Map<String, dynamic>.from(item),
        ).toList();
        _loading = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.message ?? 'تعذر قراءة قائمة APK'; });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'تحتاج هذه الميزة إلى إصدار Zion المحدّث.'; });
    }
  }

  Future<void> _importApk() async {
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('pickApk');
      if (result?['status'] == 'IMPORTED') {
        await _refresh();
        if (mounted) _message('تم استيراد APK وفحص بيانات الحزمة.');
      } else if (result?['status'] == 'UNSUPPORTED') {
        _message('الملف لا يبدو كحزمة APK صالحة.');
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'فشل استيراد APK');
    } on MissingPluginException {
      if (mounted) setState(() => _error = 'قناة استيراد APK غير متاحة في هذا الإصدار.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101827),
        foregroundColor: Colors.white,
        title: const Text('Zion Virtual Apps'),
        actions: [IconButton(onPressed: _refresh, tooltip: 'تحديث', icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _cyan,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cyan.withOpacity(.35)),
                color: const Color(0xFF101827),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.layers_rounded, color: _cyan, size: 30),
                  SizedBox(width: 12),
                  Expanded(child: Text('مساحة تطبيقات Zion', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 12),
                const Text(
                  'استورد ملفات APK إلى مساحة Zion الخاصة، وراجع معلومات الحزم قبل تفعيل محرك التشغيل الافتراضي.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _importApk,
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.file_open),
                    label: Text(_busy ? 'جارٍ استيراد الملف...' : 'استيراد ملف APK'),
                    style: FilledButton.styleFrom(backgroundColor: _cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('حالة المحرك', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _statusRow(Icons.check_circle_outline, 'استيراد APK وفحص بيانات الحزمة', 'متاح', true),
            _statusRow(Icons.pending_outlined, 'تشغيل التطبيقات داخل حاوية افتراضية', 'يتطلب دمج محرك Runtime', false),
            _statusRow(Icons.pending_outlined, 'ملفات بيانات مستقلة لكل نسخة', 'لاحقاً مع المحرك', false),
            _statusRow(Icons.pending_outlined, 'توافق الخدمات والإشعارات وGoogle Play', 'يُختبر لكل تطبيق', false),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Text('ملفات APK المستوردة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
              Text('${_apps.length}', style: const TextStyle(color: _cyan)),
            ]),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(color: _cyan)))
            else if (_apps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 26),
                child: Column(children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.white38, size: 42),
                  SizedBox(height: 10),
                  Text('لم يتم استيراد أي APK بعد', style: TextStyle(color: Colors.white60)),
                ]),
              )
            else
              ..._apps.map(_appCard),
            const SizedBox(height: 14),
            const Text(
              'تنبيه: الاستيراد لا يثبت التطبيق في أندرويد ولا يعني أنه يعمل افتراضياً. لن يظهر التطبيق على أنه قابل للتشغيل حتى يكتمل دمج المحرك واختباره.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(IconData icon, String title, String status, bool ready) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.035), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: ready ? Colors.greenAccent : Colors.orangeAccent, size: 21),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13))),
      const SizedBox(width: 8),
      Flexible(child: Text(status, textAlign: TextAlign.end, style: TextStyle(color: ready ? Colors.greenAccent : Colors.orangeAccent, fontSize: 11))),
    ]),
  );

  Widget _appCard(Map<String, dynamic> app) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: const Color(0xFF101827), borderRadius: BorderRadius.circular(14), border: Border.all(color: _cyan.withOpacity(.2))),
    child: Row(children: [
      const CircleAvatar(backgroundColor: Color(0x2233BCD4), child: Icon(Icons.android, color: _cyan)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((app['label'] as String?)?.isNotEmpty == true ? app['label'] as String : (app['fileName'] as String? ?? 'APK'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(app['packageName'] as String? ?? 'تعذر استخراج اسم الحزمة', style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text('الإصدار: ${app['versionName'] ?? 'غير معروف'} · ${app['fileName'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ])),
      const SizedBox(width: 6),
      const Icon(Icons.archive_outlined, color: _cyan),
    ]),
  );
}
