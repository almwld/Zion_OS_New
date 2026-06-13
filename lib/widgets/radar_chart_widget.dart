import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class RadarChartWidget extends StatefulWidget {
  const RadarChartWidget({super.key});

  @override
  State<RadarChartWidget> createState() => _RadarChartWidgetState();
}

class _RadarChartWidgetState extends State<RadarChartWidget> {
  final List<String> _titles = ['CPU', 'RAM', 'Storage', 'Battery', 'Network', 'Temp'];
  final List<Color> _colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.cyan, Colors.red];
  final Random _random = Random();

  List<double> _values = [];

  @override
  void initState() {
    super.initState();
    _values = List.generate(6, (_) => _random.nextDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: const Color(0xFF00BCD4).withOpacity(0.2),
              borderColor: const Color(0xFF00BCD4),
              entryRadius: 4,
              dataEntries: _values.asMap().entries.map((e) => RadarEntry(value: e.value)).toList(),
            ),
          ],
          radarBorderData: const BorderSide(color: Color(0xFF00BCD4), width: 1),
          titlePositionPercentageOffset: 1.2,
          getTitle: (index, angle) => RadarChartTitle(
            text: _titles[index],
            angle: angle,
            style: TextStyle(color: _colors[index % _colors.length], fontSize: 10),
          ),
          ticks: const [0.2, 0.4, 0.6, 0.8, 1.0],
          tickBorderData: const BorderSide(color: Color(0xFF00BCD4), width: 0.5),
        ),
      ),
    );
  }
}
