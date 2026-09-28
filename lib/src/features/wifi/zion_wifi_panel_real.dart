import 'package:flutter/material.dart';
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
      _log = 'Starting real Android Wi-Fi scan...\n';
      _assessments = const [];
    });

    try {
      final networks = await _wifi.scanNetworks();
      final assessments = <WiFiSecurityAssessment>[];
      for (final network in networks) {
        assessments.add(await _wifi.assessNetwork(network));
      }
      assessments.sort((a, b) => b.riskScore.compareTo(a.riskScore));
      if (!mounted) return;
      setState(() {
        _assessments = assessments;
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
                          'Risk ${assessment.riskScore}/100 · '
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
