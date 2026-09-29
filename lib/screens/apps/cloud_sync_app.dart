import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/cloud_sync_service.dart';
import '../../core/theme/zion_colors.dart';
import '../../providers/theme_provider.dart';

class CloudSyncApp extends StatefulWidget {
  const CloudSyncApp({super.key});

  @override
  State<CloudSyncApp> createState() => _CloudSyncAppState();
}

class _CloudSyncAppState extends State<CloudSyncApp> {
  final _endpointController = TextEditingController();
  final _tokenController = TextEditingController();
  final _service = CloudSyncService();
  String _status = 'غير مُهيأ';
  bool _busy = false;

  @override
  void dispose() {
    _endpointController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testSync() async {
    final endpoint = Uri.tryParse(_endpointController.text.trim());
    if (endpoint == null || endpoint.scheme != 'https') {
      setState(() => _status = 'UNAVAILABLE: يجب استخدام عنوان HTTPS صالح');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'جارٍ اختبار الاتصال...';
    });
    try {
      _service.configure(
        endpoint: endpoint,
        bearerToken: _tokenController.text.trim().isEmpty
            ? null
            : _tokenController.text.trim(),
      );
      final result = await _service.uploadJson(
        collection: 'healthcheck',
        data: <String, dynamic>{
          'source': 'zion-os',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
      if (!mounted) return;
      setState(() {
        _status = result.ok
            ? 'AVAILABLE: HTTP ${result.status} — SHA-256 ${result.digest}'
            : 'UNAVAILABLE: HTTP ${result.status} — ${result.error ?? 'بدون استجابة'}';
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'UNAVAILABLE: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: const Text('المزامنة السحابية')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.cloud_sync, size: 52, color: ZionColors.cyan),
          const SizedBox(height: 12),
          const Text(
            'تكامل HTTPS حقيقي. لن تُعرض المزامنة كناجحة ما لم يُرجع الخادم رمز 2xx.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _endpointController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'HTTPS endpoint',
              hintText: 'https://example.com/api/',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Bearer token (اختياري)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _testSync,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_busy ? 'جارٍ الاختبار' : 'اختبار المزامنة'),
          ),
          const SizedBox(height: 20),
          SelectableText(
            _status,
            style: TextStyle(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }
}
