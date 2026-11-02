import 'dart:io';

class MetricValue<T> {
  const MetricValue.available(this.value)
      : isAvailable = true,
        error = null;
  const MetricValue.unavailable([this.error])
      : value = null,
        isAvailable = false;

  final T? value;
  final bool isAvailable;
  final String? error;
}

class SystemMetrics {
  Future<MetricValue<int>> batteryLevel() async {
    if (!(Platform.isLinux || Platform.isAndroid)) {
      return const MetricValue<int>.unavailable('المنصة لا توفر قراءة البطارية عبر sysfs.');
    }

    const candidates = [
      '/sys/class/power_supply/battery/capacity',
      '/sys/class/power_supply/BAT0/capacity',
      '/sys/class/power_supply/BAT1/capacity',
    ];

    for (final path in candidates) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final value = int.tryParse((await file.readAsString()).trim());
        if (value != null && value >= 0 && value <= 100) {
          return MetricValue<int>.available(value);
        }
      } catch (error) {
        return MetricValue<int>.unavailable(error.toString());
      }
    }
    return const MetricValue<int>.unavailable('مصدر قراءة البطارية غير متاح.');
  }

  Future<Map<String, dynamic>> snapshot() async {
    final battery = await batteryLevel();
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'batteryLevel': battery.value,
      'batteryAvailable': battery.isAvailable,
      if (battery.error != null) 'batteryError': battery.error,
    };

    if (Platform.isLinux || Platform.isAndroid) {
      try {
        final lines = await File('/proc/meminfo').readAsLines();
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length < 2) continue;
          final key = parts.first.replaceAll(':', '');
          if (key == 'MemTotal' ||
              key == 'MemAvailable' ||
              key == 'MemFree' ||
              key == 'SwapTotal' ||
              key == 'SwapFree') {
            final value = int.tryParse(parts[1]);
            if (value != null) result[key] = value;
          }
        }
        result['memoryAvailable'] = result.containsKey('MemTotal');
      } catch (error) {
        result['memoryAvailable'] = false;
        result['memoryError'] = error.toString();
      }
    } else {
      result['memoryAvailable'] = false;
    }
    return result;
  }
}
