import 'dart:io';
class SystemMetrics {
  Future<int> batteryLevel() async {
    if(!(Platform.isLinux||Platform.isAndroid))return 0;
    try {
      final file=File('/sys/class/power_supply/battery/capacity');
      if(await file.exists())return int.tryParse((await file.readAsString()).trim());
    } catch (_) {}
    return 0;
  }
  Future<Map<String,dynamic>> snapshot() async {
    final result=<String,dynamic>{'timestamp':DateTime.now().toIso8601String(),'platform':Platform.operatingSystem,'batteryLevel':await batteryLevel()};
    if(Platform.isLinux||Platform.isAndroid){
      try {
        final stat=await File('/proc/meminfo').readAsLines();
        for(final line in stat.take(8)){
          final parts=line.split(RegExp(r'\\s+'));
          if(parts.length>=2&&parts[0].startsWith('Mem'))result[parts[0].replaceAll(':','')]=parts[1];
        }
      } catch (_) {}
    }
    return result;
  }
}
