import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class LearningDatabase {
  static final LearningDatabase _instance = LearningDatabase._internal();
  factory LearningDatabase() => _instance;
  LearningDatabase._internal();

  late File _trainingDataFile;
  final List<Map<String, dynamic>> _trainingData = [];

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _trainingDataFile = File('${dir.path}/zion_training.json');
    await _loadData();
  }

  Future<void> _loadData() async {
    if (await _trainingDataFile.exists()) {
      final content = await _trainingDataFile.readAsString();
      final List<dynamic> data = jsonDecode(content);
      _trainingData.clear();
      _trainingData.addAll(data.map((e) => e as Map<String, dynamic>));
    }
  }

  Future<void> saveTrainingSample(Map<String, dynamic> sample) async {
    _trainingData.add(sample);
    await _trainingDataFile.writeAsString(jsonEncode(_trainingData));
  }

  Future<List<Map<String, dynamic>>> getTrainingData({int limit = 1000}) async {
    return _trainingData.reversed.take(limit).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final successes = _trainingData.where((s) => s['success'] == true).length;
    return {
      'total_samples': _trainingData.length,
      'successful_attacks': successes,
      'success_rate': _trainingData.isEmpty ? 0 : successes / _trainingData.length,
      'last_updated': (await _trainingDataFile.lastModified()).toIso8601String(),
    };
  }

  Future<void> exportData(String path) async {
    final exportFile = File('$path/zion_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await exportFile.writeAsString(jsonEncode(_trainingData));
  }

  Future<void> clear() async {
    _trainingData.clear();
    await _trainingDataFile.writeAsString('[]');
  }
}
