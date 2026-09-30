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
  List<WiFiSecurityAssessment> _assessments = const [];
  NetworkPortAssessment? _portAssessment;

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _scanWiFi() async {
    setState(() {
      _scanning = true;
      _scanStatus = 'SCANNING';
      _log = 'Starting real Android Wi-Fi scan...\n';
      _assessments = const [];
    });

    try {
      final location = await Permission.location.request();
      if (!location.isGranted) {
        if (!mounted) return;
        setState(() { _scanStatus = 'PERMISSION_REQUIRED'; _log += 'Location permission is required by Android for Wi-Fi scan results.\n'; _scanning = false; });
        return;
      }
      if (await Permission.nearbyWifiDevices.isDenied) await Permission.nearbyWifiDevices.request();
      final nearby = await Permission.nearbyWifiDevices.status;
      if (nearby.isDenied || nearby.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() { _scanStatus = 'PERMISSION_REQUIRED'; _log += 'Nearby Wi-Fi permission is required.\n'; _scanning = false; });
        return;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Zion Wi-Fi Security Assessment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanning ? null : _scanWiFi,
                    icon: const Icon(Icons.wifi_find),
                    label: Text(_scanning ? 'SCANNING...' : 'SCAN WI-FI'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Authorized host / IP for TCP assessment',
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
                label: const Text('ASSESS COMMON TCP PORTS'),
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
