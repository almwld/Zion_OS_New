import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RadarChartWidget extends StatelessWidget {
  final List<double> values;
  final List<String> titles;
  const RadarChartWidget({super.key, required this.values, required this.titles});

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
              dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
            ),
          ],
          radarBorderData: const BorderSide(color: Color(0xFF00BCD4), width: 1),
          titlePositionPercentageOffset: 1.2,
          getTitle: (index, angle) => RadarChartTitle(text: titles[index], angle: angle),
        ),
      ),
    );
  }
}
