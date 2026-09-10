import 'package:flutter/foundation.dart';

import '../../ai/command_predictor.dart';
import '../../ai/neural_analyzer.dart';

/// Coordinates the advanced local runtime features without executing predictions
/// automatically or claiming capabilities that are not available.
class ProfessionalRuntimeController extends ChangeNotifier {
  ProfessionalRuntimeController({CommandPredictor? predictor})
      : predictor = predictor ?? CommandPredictor();

  final CommandPredictor predictor;
  NeuralAnalysisResult? _lastAnalysis;
  List<CommandPrediction> _predictions = const [];
  bool _initialized = false;

  NeuralAnalysisResult? get lastAnalysis => _lastAnalysis;
  List<CommandPrediction> get predictions => List.unmodifiable(_predictions);
  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    await predictor.init();
    _initialized = true;
    notifyListeners();
  }

  Future<NeuralAnalysisResult> inspectCommand(String command) async {
    await init();
    final result = NeuralAnalyzer.analyze(command);
    _lastAnalysis = result;
    _predictions = predictor.predictNext(command);
    notifyListeners();
    return result;
  }

  Future<void> recordExecutedCommand(String command) async {
    await init();
    await predictor.train(command);
    _predictions = predictor.predictNext(command);
    notifyListeners();
  }

  List<String> autocomplete(String partial) => predictor.autocomplete(partial);

  Future<void> clearHistory() async {
    await predictor.clear();
    _predictions = const [];
    _lastAnalysis = null;
    notifyListeners();
  }
}
