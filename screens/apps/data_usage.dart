import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DataUsageApp extends StatefulWidget {
  const DataUsageApp({super.key});

  @override
  State<DataUsageApp> createState() => _DataUsageAppState();
}

class _DataUsageAppState extends State<DataUsageApp> {
  int _selectedPeriod = 0;
  final List<String> _periods = ['Today', 'Week', 'Month'];
  
  double _mobileData = 2.5;
  double _wifiData = 5.8;
  double _totalData = 8.3;
  double _remainingData = 8.2;
  
  final List<Map<String, dynamic>> _appUsage = [
    {'name': 'Browser', 'usage': 1.2, 'color': 0xFF00BCD4},
    {'name': 'Email', 'usage': 0.5, 'color': 0xFF2196F3},
    {'name': 'Maps', 'usage': 0.8, 'color': 0xFF4CAF50},
    {'name': 'Weather', 'usage': 0.3, 'color': 0xFFFF9800},
    {'name': 'Radio', 'usage': 1.5, 'color': 0xFF9C27B0},
    {'name': 'Translator', 'usage': 0.2, 'color': 0xFFE91E63},
  ];
  
  final List<Map<String, dynamic>> _dailyUsage = [
    {'day': 'Mon', 'usage': 0.8},
    {'day': 'Tue', 'usage': 1.2},
    {'day': 'Wed', 'usage': 0.5},
    {'day': 'Thu', 'usage': 1.8},
    {'day': 'Fri', 'usage': 1.1},
    {'day': 'Sat', 'usage': 2.5},
    {'day': 'Sun', 'usage': 1.3},
  ];

  List<BarChartGroupData> _getBarData() {
    return _dailyUsage.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value['usage'],
            color: const Color(0xFF00BCD4),
            width: 20,
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pieSections = [
      PieChartSectionData(
        value: _mobileData,
        title: 'Mobile\n${_mobileData.toStringAsFixed(1)} GB',
        color: const Color(0xFF00BCD4),
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      PieChartSectionData(
        value: _wifiData,
        title: 'WiFi\n${_wifiData.toStringAsFixed(1)} GB',
        color: Colors.grey,
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Data Usage', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Data Usage Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Total Data Used', style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalData.toStringAsFixed(1)} GB',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDataItem('Mobile', '${_mobileData.toStringAsFixed(1)} GB', const Color(0xFF00BCD4)),
                      _buildDataItem('WiFi', '${_wifiData.toStringAsFixed(1)} GB', Colors.grey),
                      _buildDataItem('Remaining', '${_remainingData.toStringAsFixed(1)} GB', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Data Breakdown Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('Data Breakdown', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: pieSections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend('Mobile', const Color(0xFF00BCD4)),
                      const SizedBox(width: 20),
                      _buildLegend('WiFi', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Daily Usage Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('Daily Usage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 3,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < _dailyUsage.length) {
                                  return Text(_dailyUsage[value.toInt()]['day'], style: const TextStyle(color: Colors.white54, fontSize: 10));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: _getBarData(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // App Usage
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Usage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._appUsage.map((app) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Color(app['color']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(_getAppIcon(app['name']), color: Color(app['color']), size: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(app['name'], style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                            Text('${app['usage']} GB', style: TextStyle(color: Color(app['color']))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: app['usage'] / 3,
                          backgroundColor: Colors.white24,
                          color: Color(app['color']),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  IconData _getAppIcon(String appName) {
    switch (appName) {
      case 'Browser': return Icons.public;
      case 'Email': return Icons.email;
      case 'Maps': return Icons.map;
      case 'Weather': return Icons.wb_sunny;
      case 'Radio': return Icons.radio;
      case 'Translator': return Icons.translate;
      default: return Icons.apps;
    }
  }
}
