import 'package:flutter/material.dart';

import 'system_metrics.dart';

class Dashboard extends StatefulWidget {
  Dashboard({super.key, SystemMetrics? metrics})
      : metrics = metrics ?? SystemMetrics();

  final SystemMetrics metrics;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Future<MetricValue<int>> _battery;

  @override
  void initState() {
    super.initState();
    _battery = widget.metrics.batteryLevel();
  }

  void _refresh() {
    setState(() => _battery = widget.metrics.batteryLevel());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('مؤشرات النظام',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'تحديث المؤشرات',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            FutureBuilder<MetricValue<int>>(
              future: _battery,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    dense: true,
                    title: Text('البطارية'),
                    subtitle: Text('جارٍ قراءة المؤشر…'),
                  );
                }
                if (snapshot.hasError) {
                  return const ListTile(
                    dense: true,
                    title: Text('البطارية'),
                    subtitle: Text('تعذر قراءة المؤشر'),
                    trailing: Icon(Icons.warning_amber_outlined),
                  );
                }
                final metric = snapshot.data;
                if (metric == null || !metric.isAvailable) {
                  return ListTile(
                    dense: true,
                    title: const Text('البطارية'),
                    subtitle: Text(metric?.error ?? 'غير متاح على هذه المنصة'),
                    trailing: Icon(Icons.remove_circle_outline,
                        color: scheme.onSurfaceVariant),
                  );
                }
                return ListTile(
                  dense: true,
                  title: const Text('البطارية'),
                  subtitle: Text('${metric.value}%'),
                  trailing: SizedBox(
                    width: 110,
                    child: LinearProgressIndicator(
                      value: metric.value! / 100,
                      minHeight: 7,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
