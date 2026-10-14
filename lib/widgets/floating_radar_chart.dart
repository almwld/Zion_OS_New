import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Draggable live network radar backed by the native Android telemetry stream.
/// It deliberately displays no fabricated CPU/RAM/security values.
class FloatingRadarChart extends StatefulWidget {
  final VoidCallback onClose;
  const FloatingRadarChart({super.key, required this.onClose});

  @override
  State<FloatingRadarChart> createState() => _FloatingRadarChartState();
}

class _FloatingRadarChartState extends State<FloatingRadarChart> {
  static const EventChannel _channel = EventChannel('zion.os/network/radar');
  static const List<String> _titles = <String>[
    'RX rate', 'TX rate', 'RX packets', 'TX packets',
    'Downlink', 'Uplink', 'Wi-Fi RSSI', 'Link speed',
  ];

  Offset _position = Offset.zero;
  double _width = 280;
  double _height = 280;
  StreamSubscription<dynamic>? _subscription;
  Map<String, dynamic> _sample = <String, dynamic>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      setState(() {
        _position = Offset(
          (size.width - _width - 20).clamp(0.0, double.infinity),
          (size.height - _height - 100).clamp(0.0, double.infinity),
        );
      });
    });
    _subscription = _channel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;
        final next = Map<String, dynamic>.from(event);
        if (next['event'] == true && next.length <= 4) return;
        if (!mounted) return;
        setState(() {
          _sample = next;
          _error = null;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _error = 'Network telemetry unavailable');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  double _value(String key) {
    final value = _sample[key];
    return value is num ? value.toDouble() : 0.0;
  }

  double _normalized(String key, double ceiling) =>
      (_value(key) / ceiling).clamp(0.0, 1.0).toDouble();

  List<RadarEntry> _entries() => <RadarEntry>[
        RadarEntry(value: _normalized('rxBytesPerSec', 10 * 1024 * 1024)),
        RadarEntry(value: _normalized('txBytesPerSec', 5 * 1024 * 1024)),
        RadarEntry(value: _normalized('rxPacketsPerSec', 5000)),
        RadarEntry(value: _normalized('txPacketsPerSec', 5000)),
        RadarEntry(value: _normalized('downstreamKbps', 100000)),
        RadarEntry(value: _normalized('upstreamKbps', 50000)),
        RadarEntry(value: _sample['wifiRssi'] is num
            ? ((_value('wifiRssi') + 100) / 70).clamp(0.0, 1.0).toDouble()
            : 0.0),
        RadarEntry(value: _normalized('wifiLinkSpeedMbps', 1000)),
      ];

  String _rate(String key) {
    final value = _value(key);
    if (value >= 1024 * 1024) return '${(value / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} KB/s';
    return '${value.toStringAsFixed(0)} B/s';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxLeft = (size.width - _width).clamp(0.0, double.infinity);
    final maxTop = (size.height - _height - 50).clamp(0.0, double.infinity);
    final left = _position.dx.clamp(0.0, maxLeft);
    final top = _position.dy.clamp(0.0, maxTop);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.6), width: 1.5),
          ),
          child: Column(
            children: [
              GestureDetector(
                onPanUpdate: (details) => setState(() {
                  _position = Offset(
                    (_position.dx + details.delta.dx).clamp(0.0, maxLeft),
                    (_position.dy + details.delta.dy).clamp(0.0, maxTop),
                  );
                }),
                child: Container(
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0x3300BCD4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.radar, color: Color(0xFF00BCD4), size: 18),
                      const SizedBox(width: 8),
                      const Text('Live Network Radar',
                          style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
                      const Spacer(),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                        onPressed: () => setState(() {
                          if (_width == 48) {
                            _width = 280;
                            _height = 280;
                          } else {
                            _width = 48;
                            _height = 48;
                          }
                        }),
                        icon: const Icon(Icons.minimize, color: Color(0xFF00BCD4), size: 18),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, color: Color(0xFF00BCD4), size: 18),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              if (_width > 100)
                Expanded(
                  child: GestureDetector(
                    onScaleUpdate: (details) => setState(() {
                      _width = (_width * details.scale).clamp(180.0, 500.0);
                      _height = (_height * details.scale).clamp(180.0, 500.0);
                    }),
                    child: _sample.isEmpty
                        ? Center(
                            child: Text(
                              _error ?? 'Waiting for live system telemetry…',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          )
                        : RadarChart(
                            RadarChartData(
                              dataSets: [
                                RadarDataSet(
                                  fillColor: const Color(0x3300BCD4),
                                  borderColor: const Color(0xFF00BCD4),
                                  borderWidth: 1.5,
                                  entryRadius: 3,
                                  dataEntries: _entries(),
                                ),
                              ],
                              radarBorderData: const BorderSide(color: Color(0xFF00BCD4)),
                              titlePositionPercentageOffset: 0.12,
                              getTitle: (index, angle) =>
                                  RadarChartTitle(text: _titles[index], angle: angle),
                            ),
                          ),
                  ),
                ),
              if (_width > 100 && _sample.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    'RX ${_rate('rxBytesPerSec')} • TX ${_rate('txBytesPerSec')}\n'
                    '${_sample['transport'] ?? 'none'} • ${_sample['interface'] ?? 'unknown'} • '
                    '${_sample['validated'] == true ? 'Internet verified' : 'Not validated'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
