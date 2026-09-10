import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});
  @override State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final _cityController = TextEditingController(text: 'Sana\'a');
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;

  Future<void> _fetchWeather() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final geo = await http.get(Uri.https('geocoding-api.open-meteo.com', '/v1/search', {'name': city, 'count': '1', 'language': 'en', 'format': 'json'})).timeout(const Duration(seconds: 15));
      if (geo.statusCode != 200) throw Exception('Geocoding HTTP ${geo.statusCode}');
      final g = jsonDecode(geo.body) as Map<String, dynamic>;
      final results = g['results'];
      if (results is! List || results.isEmpty) throw Exception('City not found');
      final place = results.first as Map<String, dynamic>;
      final lat = (place['latitude'] as num).toDouble();
      final lon = (place['longitude'] as num).toDouble();
      final weather = await http.get(Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$lat', 'longitude': '$lon',
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,pressure_msl,weather_code',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'forecast_days': '7', 'timezone': 'auto',
      })).timeout(const Duration(seconds: 15));
      if (weather.statusCode != 200) throw Exception('Weather HTTP ${weather.statusCode}');
      final w = jsonDecode(weather.body) as Map<String, dynamic>;
      if (mounted) setState(() { _data = {'place': place, 'weather': w}; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'تعذر جلب الطقس الحقيقي: $e'; });
    }
  }

  String _description(int code) {
    if (code == 0) return 'Clear sky';
    if ([1,2,3].contains(code)) return 'Cloudy';
    if ([45,48].contains(code)) return 'Fog';
    if ([51,53,55,56,57].contains(code)) return 'Drizzle';
    if ([61,63,65,66,67,80,81,82].contains(code)) return 'Rain';
    if ([71,73,75,77,85,86].contains(code)) return 'Snow';
    if ([95,96,99].contains(code)) return 'Thunderstorm';
    return 'Unknown';
  }
  IconData _icon(int code) => code == 0 ? Icons.wb_sunny : ([95,96,99].contains(code) ? Icons.flash_on : ([61,63,65,80,81,82].contains(code) ? Icons.water_drop : Icons.cloud));

  @override void initState() { super.initState(); _fetchWeather(); }
  @override void dispose() { _cityController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final current = _data?['weather']?['current'] as Map<String, dynamic>?;
    final daily = _data?['weather']?['daily'] as Map<String, dynamic>?;
    final place = _data?['place'] as Map<String, dynamic>?;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Weather', style: TextStyle(color: Color(0xFF00BCD4))), backgroundColor: Colors.black, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)), onPressed: () => Navigator.pop(context))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [Expanded(child: TextField(controller: _cityController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Enter city name', hintStyle: TextStyle(color: Colors.white38))),), const SizedBox(width: 8), ElevatedButton(onPressed: _loading ? null : _fetchWeather, child: const Icon(Icons.search))]),
        const SizedBox(height: 20),
        if (_loading) const Center(child: CircularProgressIndicator())
        else if (_error != null) _message(_error!)
        else if (current != null) ...[
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]), borderRadius: BorderRadius.circular(20)), child: Column(children: [
            Text('${place?['name'] ?? ''}, ${place?['country'] ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
            Icon(_icon((current['weather_code'] as num).toInt()), size: 72, color: Colors.white),
            Text('${(current['temperature_2m'] as num).round()}°C', style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(_description((current['weather_code'] as num).toInt()), style: const TextStyle(color: Colors.white70)),
          ])),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _detail('Feels like', '${(current['apparent_temperature'] as num).round()}°C'),
            _detail('Humidity', '${(current['relative_humidity_2m'] as num).round()}%'),
            _detail('Wind', '${(current['wind_speed_10m'] as num).round()} km/h'),
            _detail('Pressure', '${(current['pressure_msl'] as num).round()} hPa'),
          ]),
          const SizedBox(height: 20),
          const Text('7-Day Forecast', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (daily != null) SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: (daily['time'] as List).length, itemBuilder: (_, i) {
            final code = (daily['weather_code'] as List)[i] as num;
            return Container(width: 92, margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(.05), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text((daily['time'] as List)[i].toString().substring(5), style: const TextStyle(color: Colors.white70)), Icon(_icon(code.toInt()), color: const Color(0xFF00BCD4)), Text('${((daily['temperature_2m_max'] as List)[i] as num).round()}° / ${((daily['temperature_2m_min'] as List)[i] as num).round()}°', style: const TextStyle(color: Colors.white))]));
          })),
        ]
      ]),
    );
  }

  Widget _detail(String label, String value) => Container(width: 150, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(.05), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(label, style: const TextStyle(color: Colors.white54)), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]));
  Widget _message(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text(text, style: const TextStyle(color: Colors.orangeAccent), textAlign: TextAlign.center)));
}
