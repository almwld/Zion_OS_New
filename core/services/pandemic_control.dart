import 'dart:async';
import 'dart:math';

class PandemicControl {
  bool _isActive = false;
  final List<Map<String, dynamic>> _pathogens = [];
  final List<Map<String, dynamic>> _outbreaks = [];

  bool get isActive => _isActive;
  List<Map<String, dynamic>> get pathogens => _pathogens;
  List<Map<String, dynamic>> get outbreaks => _outbreaks;

  Future<Map<String, dynamic>> designPathogen(String name, Map<String, dynamic> params) async {
    _isActive = true;
    final pathogen = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'type': params['type'] ?? 'Virus',
      'r0': params['r0'] ?? Random().nextDouble() * 5 + 2,
      'mortality': params['mortality'] ?? '${(Random().nextDouble() * 10).toStringAsFixed(1)}%',
      'incubation': '${Random().nextInt(14) + 1} days',
      'status': 'designed',
    };

    await Future.delayed(const Duration(seconds: 2));
    _pathogens.add(pathogen);
    _isActive = false;
    return pathogen;
  }

  Future<Map<String, dynamic>> releasePathogen(String pathogenId, String target) async {
    _isActive = true;
    final outbreak = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'pathogenId': pathogenId,
      'target': target,
      'status': 'spreading',
      'startedAt': DateTime.now(),
      'infected': 0,
      'spreadRate': 'Exponential',
    };

    await Future.delayed(const Duration(seconds: 2));
    outbreak['infected'] = Random().nextInt(100000) + 1000;
    outbreak['status'] = 'pandemic';
    _outbreaks.add(outbreak);
    _isActive = false;
    return outbreak;
  }
}
