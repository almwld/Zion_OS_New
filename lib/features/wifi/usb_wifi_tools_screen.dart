import 'dart:io';

import 'package:flutter/material.dart';

import 'kali_pcap_analyzer.dart';
import 'usb_wifi_bridge.dart';

class UsbWifiToolsScreen extends StatefulWidget {
  const UsbWifiToolsScreen({super.key});
  @override
  State<UsbWifiToolsScreen> createState() => _UsbWifiToolsScreenState();
}

class _UsbWifiToolsScreenState extends State<UsbWifiToolsScreen> {
  final _name = TextEditingController(text: 'zion-capture.pcap');
  int _channel = 6;
  bool _installed = false, _busy = false, _capturing = false;
  String _status = 'جارٍ التحقق من USB WiFi Monitor…';
  List<FileSystemEntity> _files = const [];
  static const _folder = '/storage/emulated/0/Download/UsbWifiMonitor';

  @override
  void initState() { super.initState(); _refresh(); }
  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _refresh() async {
    try {
      final installed = await UsbWifiBridge.isInstalled();
      final dir = Directory(_folder);
      final files = await dir.exists()
          ? await dir.list().where((f) => f.path.toLowerCase().endsWith('.pcap')).toList()
          : <FileSystemEntity>[];
      if (!mounted) return;
      setState(() {
        _installed = installed;
        _files = files;
        _status = installed ? 'USB WiFi Monitor: installed' : 'USB WiFi Monitor غير مثبت. ثبّت التطبيق الرسمي أولاً.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'تعذر التحقق: $e');
    }
  }

  Future<void> _run(Future<bool> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await action();
      if (mounted) setState(() => _status = ok ? success : 'لم يؤكد التطبيق نجاح العملية.');
    } catch (e) {
      if (mounted) setState(() => _status = 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _analyze(String name) async {
    setState(() { _busy = true; _status = 'نسخ PCAP وتشغيل aircrack-ng داخل Kali…'; });
    try {
      final output = await KaliPcapAnalyzer.analyzeInKali(name);
      if (!mounted) return;
      setState(() => _status = output);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('نتيجة تحليل PCAP في Kali'),
          content: SingleChildScrollView(child: SelectableText(output, textDirection: TextDirection.ltr)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _status = 'فشل التحليل: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('USB WiFi Monitor وPCAP')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(child: ListTile(
              leading: Icon(_installed ? Icons.check_circle : Icons.error_outline,
                  color: _installed ? Colors.green : theme.colorScheme.error),
              title: Text(_installed ? 'USB WiFi Monitor: installed' : 'USB WiFi Monitor: غير مثبت'),
              subtitle: const Text('يتطلب محول USB OTG بشريحة AR9271 وإذن USB من التطبيق.'),
              trailing: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            )),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _channel,
              decoration: const InputDecoration(labelText: 'قناة الالتقاط'),
              items: [
                for (var ch = 1; ch <= 11; ch++) DropdownMenuItem(value: ch, child: Text('القناة $ch')),
                const DropdownMenuItem(value: -1, child: Text('التنقل التلقائي بين القنوات')),
              ],
              onChanged: _busy ? null : (v) => setState(() => _channel = v ?? 6),
            ),
            const SizedBox(height: 10),
            TextField(controller: _name, decoration: const InputDecoration(
              labelText: 'اسم ملف PCAP', helperText: 'سيضاف امتداد .pcap تلقائياً إن لم يوجد')),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy || !_installed || _capturing ? null : () async {
                await _run(() => UsbWifiBridge.startCapture(channel: _channel, pcapName: _name.text.trim()),
                    'تم إرسال طلب بدء الالتقاط. تحقق من ظهور ملف PCAP.');
                if (mounted) setState(() => _capturing = true);
              },
              icon: const Icon(Icons.play_arrow), label: const Text('بدء الالتقاط')),
            OutlinedButton.icon(
              onPressed: _busy || !_capturing ? null : () async {
                await _run(UsbWifiBridge.stopCapture, 'تم إرسال طلب إيقاف الالتقاط.');
                if (mounted) setState(() => _capturing = false);
              },
              icon: const Icon(Icons.stop), label: const Text('إيقاف الالتقاط')),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(UsbWifiBridge.openPcapFolder, 'تم فتح محدد مجلد PCAP.'),
              icon: const Icon(Icons.folder_open), label: const Text('فتح مجلد PCAP')),
            const SizedBox(height: 12),
            Text('الحالة', style: theme.textTheme.titleMedium),
            SelectableText(_status, textDirection: TextDirection.ltr),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: Text('ملفات PCAP (${_files.length})', style: theme.textTheme.titleMedium)),
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            ]),
            if (_files.isEmpty)
              const Text('لا توجد ملفات مرئية. تأكد من أذونات التخزين وأن التطبيق أنشأ ملفاً.')
            else
              for (final file in _files)
                Card(child: ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(file.path.split('/').last),
                  subtitle: Text(File(file.path).existsSync()
                      ? '${(File(file.path).lengthSync() / 1024).toStringAsFixed(1)} KB' : 'غير متاح'),
                  trailing: IconButton(
                    tooltip: 'تحليل في Kali', icon: const Icon(Icons.analytics_outlined),
                    onPressed: _busy ? null : () => _analyze(file.path.split('/').last)),
                )),
          ],
        ),
      ),
    );
  }
}
