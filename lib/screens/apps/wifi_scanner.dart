import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class WiFiScannerApp extends StatefulWidget {
  const WiFiScannerApp({super.key});

  @override
  State<WiFiScannerApp> createState() => _WiFiScannerAppState();
}

class _WiFiScannerAppState extends State<WiFiScannerApp> {
  static const _channel = MethodChannel('zion.os/platform');
  List<Map<String, dynamic>> _networks = const [];
  bool _isScanning = false;
  String _status = 'NOT_CONFIGURED';
  String _reason = 'اضغط تحديث لبدء فحص Wi-Fi الحقيقي.';

  @override
  void initState() {
    super.initState();
    _requestAndScan();
  }

  Future<void> _requestAndScan() async {
    final status = await Permission.location.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() {
        _status = 'PERMISSION_REQUIRED';
        _reason = 'يجب السماح بالموقع حتى يسمح Android بعرض نتائج شبكات Wi-Fi.';
        _networks = const [];
      });
      return;
    }
    await _scanWiFi();
  }

  Future<void> _scanWiFi() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('wifiScan');
      final data = Map<String, dynamic>.from(raw ?? const {});
      final rawNetworks = data['networks'];
      final networks = rawNetworks is List
          ? rawNetworks.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _networks = networks;
        _status = (data['status'] ?? 'UNAVAILABLE').toString();
        _reason = (data['reason'] ?? 'لم تتوفر نتائج حقيقية من Android.').toString();
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _networks = const [];
        _status = 'UNAVAILABLE';
        _reason = e.message ?? 'تعذر الوصول إلى خدمة Wi-Fi في Android.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _networks = const [];
        _status = 'UNAVAILABLE';
        _reason = 'تعذر الحصول على نتائج Wi-Fi: $e';
      });
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('WiFi Scanner', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)), onPressed: _requestAndScan)],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.25))),
            child: Row(children: [
              Icon(_status == 'AVAILABLE' ? Icons.wifi : Icons.info_outline, color: const Color(0xFF00BCD4)),
              const SizedBox(width: 10),
              Expanded(child: Text('$_status\n$_reason', style: const TextStyle(color: Colors.white70, fontSize: 12))),
            ]),
          ),
          if (_status == 'PERMISSION_REQUIRED')
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(onPressed: _requestAndScan, icon: const Icon(Icons.location_on), label: const Text('السماح بالموقع')),
            ),
          Expanded(
            child: _isScanning
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
                : _networks.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_reason, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38))))
                    : RefreshIndicator(
                        onRefresh: _scanWiFi,
                        child: ListView.builder(
                          itemCount: _networks.length,
                          itemBuilder: (ctx, i) {
                            final n = _networks[i];
                            final signal = n['signal'];
                            final frequency = n['frequencyMHz'];
                            final channel = n['channel'];
                            final security = (n['capabilities'] ?? '').toString();
                            return ListTile(
                              leading: const Icon(Icons.wifi, color: Color(0xFF00BCD4)),
                              title: Text((n['ssid'] ?? '<hidden>').toString(), style: const TextStyle(color: Colors.white)),
                              subtitle: Text('${signal ?? '?'} dBm • ${frequency ?? '?'} MHz • Ch ${channel ?? '?'}\n${n['bssid'] ?? ''}\n$security', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              isThreeLine: true,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
