import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/arsenal/zion_wifi_real.dart';

class ZionWiFiRealPanel extends StatefulWidget {
  const ZionWiFiRealPanel({super.key});

  @override
  State<ZionWiFiRealPanel> createState() => _ZionWiFiRealPanelState();
}

class _ZionWiFiRealPanelState extends State<ZionWiFiRealPanel> {
  final ZionWiFiReal _wifi = ZionWiFiReal();
  final TextEditingController _hostController = TextEditingController();
  bool _scanning = false;
  String _log = '';
  String _scanStatus = 'READY';
  WiFiConnectionObservation? _connection;
  List<WiFiSecurityAssessment> _assessments = const [];
  NetworkPortAssessment? _portAssessment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshConnection());
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _refreshConnection() async {
    try {
      final connection = await _wifi.currentConnection();
      if (mounted) setState(() => _connection = connection);
    } catch (_) {
      if (mounted) setState(() => _connection = null);
    }
  }

  Future<void> _scanWiFi() async {
    setState(() {
      _scanning = true;
      _scanStatus = 'SCANNING';
      _log = 'Starting real Android Wi-Fi scan...\n';
      _assessments = const [];
    });

    try {
      await _refreshConnection();
      final location = await Permission.location.request();
      if (!location.isGranted) {
        if (!mounted) return;
        setState(() { _scanStatus = 'PERMISSION_REQUIRED'; _log += 'Location permission is required by Android for Wi-Fi scan results.\n'; _scanning = false; });
        return;
      }
      final locationService = await Permission.location.serviceStatus;
      if (locationService != ServiceStatus.enabled) {
        if (!mounted) return;
        setState(() {
          _scanStatus = 'LOCATION_DISABLED';
          _log += 'Android Location services are disabled. Enable Location, then scan again.\n';
          _scanning = false;
        });
        return;
      }
      // NEARBY_WIFI_DEVICES is an Android 13+ runtime permission. On
      // Android 11 (API 30), requesting/checking it can incorrectly block a
      // scan even after the required location permission was granted.
      if (Platform.isAndroid) {
        final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        if (sdk >= 33) {
          final nearby = await Permission.nearbyWifiDevices.request();
          if (!nearby.isGranted) {
            if (!mounted) return;
            setState(() {
              _scanStatus = 'PERMISSION_REQUIRED';
              _log += 'Nearby Wi-Fi permission is required on Android 13+.\n';
              _scanning = false;
            });
            return;
          }
        }
      }
      final networks = await _wifi.scanNetworks();
      final assessments = <WiFiSecurityAssessment>[];
      for (final network in networks) {
        assessments.add(await _wifi.assessNetwork(network));
      }
      assessments.sort((a, b) => b.riskScore.compareTo(a.riskScore));
      if (!mounted) return;
      setState(() {
        _assessments = assessments;
        _scanStatus = networks.isEmpty ? 'NO_RESULTS' : 'AVAILABLE';
        _log += 'Observed ${networks.length} real networks.\n';
        _log += 'Assessment source: REAL_WIFI_TELEMETRY\n';
        _scanning = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scanStatus = 'UNAVAILABLE';
        _log += 'SCAN UNAVAILABLE: $error\n';
        _scanning = false;
      });
    }
  }

  Future<void> _scanPorts() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an authorized host/IP address.')),
      );
      return;
    }

    setState(() {
      _scanning = true;
      _log += 'Starting real TCP connectivity assessment for $host...\n';
    });

    const commonPorts = <int>[
      21, 22, 23, 25, 53, 80, 110, 143, 443, 445, 465, 587, 993, 995,
      1433, 1521, 2049, 2375, 3000, 3306, 3389, 5432, 5900, 6379, 8080,
      8443, 9200,
    ];
    final result = await _wifi.scanTcpPorts(host, commonPorts);
    if (!mounted) return;
    setState(() {
      _portAssessment = result;
      _log += 'Open TCP ports: ${result.openPorts.join(', ')}\n';
      _scanning = false;
    });
  }

  String _bandLabel(int frequency) {
    if (frequency >= 2400 && frequency <= 2500) return '2.4 GHz';
    if (frequency >= 4900 && frequency <= 5895) return '5 GHz';
    if (frequency >= 5925 && frequency <= 7125) return '6 GHz';
    if (frequency >= 57000 && frequency <= 71000) return '60 GHz';
    return 'Unknown band';
  }

  int? _channel(int frequency) {
    if (frequency >= 2412 && frequency <= 2484) return frequency == 2484 ? 14 : (frequency - 2407) ~/ 5;
    if (frequency >= 5000 && frequency <= 5895) return (frequency - 5000) ~/ 5;
    if (frequency >= 5925 && frequency <= 7125) return (frequency - 5950) ~/ 5 + 1;
    return null;
  }

  String _securityLabel(WiFiSecurityMode mode) => switch (mode) {
        WiFiSecurityMode.wpa3 => 'WPA3',
        WiFiSecurityMode.wpa2 => 'WPA2',
        WiFiSecurityMode.wpa => 'WPA legacy',
        WiFiSecurityMode.legacyWep => 'WEP',
        WiFiSecurityMode.open => 'OPEN',
        WiFiSecurityMode.unknown => 'UNKNOWN',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('فحص أمان Wi-Fi'),),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_scanStatus != 'READY')
              Align(
                alignment: Alignment.centerRight,
                child: Text(_scanStatus, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            if (_connection != null && _connection!.ssid.isNotEmpty && _connection!.ssid != '<unknown ssid>')
              Card(
                child: ListTile(
                  leading: const Icon(Icons.wifi),
                  title: Text('متصل الآن: ${_connection!.ssid}'),
                  subtitle: Text('RSSI ${_connection!.rssi} dBm · ${_connection!.linkSpeed} Mbps · ${_connection!.frequency} MHz'),
                  trailing: const Icon(Icons.check_circle),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanning ? null : _scanWiFi,
                    icon: const Icon(Icons.wifi_find),
                    label: Text(_scanning ? 'جارٍ الفحص...' : 'فحص شبكات Wi-Fi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'عنوان IP أو مضيف مصرح به لفحص الاتصال',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanning ? null : _scanPorts,
                icon: const Icon(Icons.radar),
                label: const Text('فحص منافذ TCP الشائعة'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ..._assessments.map(
                    (assessment) => Card(
                      child: ExpansionTile(
                        title: Text(
                          assessment.network.ssid.isEmpty
                              ? '<hidden SSID>'
                              : assessment.network.ssid,
                        ),
                        subtitle: Text(
                          '${_securityLabel(assessment.securityMode)} · '
                          '${_bandLabel(assessment.network.frequency)} · '
                          'Ch ${_channel(assessment.network.frequency) ?? '?'} · '
                          'RSSI ${assessment.network.level} dBm',
                        ),
                        children: assessment.findings
                            .map(
                              (finding) => ListTile(
                                title: Text(finding.title),
                                subtitle: Text(
                                  '${finding.description}\n${finding.recommendation}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                  if (_portAssessment != null)
                    Card(
                      child: ListTile(
                        title: Text('TCP: ${_portAssessment!.host}'),
                        subtitle: Text(
                          'Open: ${_portAssessment!.openPorts.join(', ')}',
                        ),
                      ),
                    ),
                  if (_log.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _log,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
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
