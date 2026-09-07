import 'dart:math' as math;

class NeuralNetwork {
  NeuralNetwork({int inputSize = 4, int hiddenSize = 8, int outputSize = 2, int seed = 42})
      : _weights1 = _matrix(hiddenSize, inputSize, seed),
        _bias1 = List<double>.filled(hiddenSize, 0),
        _weights2 = _matrix(outputSize, hiddenSize, seed + 1),
        _bias2 = List<double>.filled(outputSize, 0);
  final List<List<double>> _weights1;
  final List<double> _bias1;
  final List<List<double>> _weights2;
  final List<double> _bias2;

  static List<List<double>> _matrix(int rows, int cols, int seed) {
    final r = math.Random(seed);
    return List.generate(rows, (_) => List.generate(cols, (_) => (r.nextDouble() - .5) * .5));
  }
  double _relu(double x) => x > 0 ? x : 0;
  List<double> predict(List<double> input) {
    if (input.length != _weights1.first.length) throw ArgumentError('Expected ${_weights1.first.length} inputs');
    final hidden = List.generate(_weights1.length, (i) => _relu(_bias1[i] + _dot(_weights1[i], input)));
    final logits = List.generate(_weights2.length, (i) => _bias2[i] + _dot(_weights2[i], hidden));
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sum = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((x) => x / sum).toList();
  }

  void train(List<double> input, int target, {double learningRate = .03}) {
    final hidden = List.generate(_weights1.length, (i) => _relu(_bias1[i] + _dot(_weights1[i], input)));
    final logits = List.generate(_weights2.length, (i) => _bias2[i] + _dot(_weights2[i], hidden));
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sum = exps.fold<double>(0, (a, b) => a + b);
    final probs = exps.map((x) => x / sum).toList();
    final delta2 = List.generate(probs.length, (i) => probs[i] - (i == target ? 1 : 0));
    final oldWeights2 = _weights2.map((row) => List<double>.from(row)).toList();
    for (var i = 0; i < _weights2.length; i++) {
      for (var j = 0; j < _weights2[i].length; j++) _weights2[i][j] -= learningRate * delta2[i] * hidden[j];
      _bias2[i] -= learningRate * delta2[i];
    }
    for (var j = 0; j < hidden.length; j++) {
      var d = 0.0;
      if (hidden[j] != 0) {
        for (var i = 0; i < delta2.length; i++) d += oldWeights2[i][j] * delta2[i];
      }
      for (var k = 0; k < input.length; k++) _weights1[j][k] -= learningRate * d * input[k];
      _bias1[j] -= learningRate * d;
    }
  }

  static double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) sum += a[i] * b[i];
    return sum;
  }
}

class ReinforcementAgent {
  final Map<String, Map<String, double>> _q = {};
  double alpha = .2;
  double gamma = .9;
  double epsilon = .1;

  String choose(String state, List<String> actions, {math.Random? random}) {
    if (actions.isEmpty) throw ArgumentError('actions cannot be empty');
    final rng = random ?? math.Random();
    final row = _q.putIfAbsent(state, () => {for (final a in actions) a: 0});
    if (rng.nextDouble() < epsilon) return actions[rng.nextInt(actions.length)];
    return actions.reduce((a, b) => (row[a] ?? 0) >= (row[b] ?? 0) ? a : b);
  }

  void learn(String state, String action, double reward, String nextState, List<String> nextActions) {
    final row = _q.putIfAbsent(state, () => {});
    final next = _q.putIfAbsent(nextState, () => {for (final a in nextActions) a: 0});
    final bestNext = next.values.isEmpty ? 0 : next.values.reduce(math.max);
    final old = row[action] ?? 0;
    row[action] = old + alpha * (reward + gamma * bestNext - old);
  }
}

class SiAgent {
  final NeuralNetwork neural = NeuralNetwork();
  final ReinforcementAgent reinforcement = ReinforcementAgent();

  Map<String, dynamic> analyzeSecurity({required double openPorts, required double anomalies, required double authFailures, required double encryptedTraffic}) {
    final features = [openPorts.clamp(0, 1).toDouble(), anomalies.clamp(0, 1).toDouble(), authFailures.clamp(0, 1).toDouble(), encryptedTraffic.clamp(0, 1).toDouble()];
    final probabilities = neural.predict(features);
    return {'riskScore': (probabilities[1] * 100).roundToDouble(), 'benignProbability': probabilities[0], 'riskProbability': probabilities[1], 'model': 'local-mlp'};
  }

  Map<String, dynamic> oracleForecast(List<double> values) {
    if (values.length < 3) return {'status': 'UNAVAILABLE', 'reason': 'at least 3 observations required'};
    final n = values.length;
    final xMean = (n - 1) / 2;
    final yMean = values.reduce((a, b) => a + b) / n;
    var num = 0.0, den = 0.0;
    for (var i = 0; i < n; i++) { final dx = i - xMean; num += dx * (values[i] - yMean); den += dx * dx; }
    final slope = den == 0 ? 0 : num / den;
    return {'status': 'REAL', 'next': yMean + slope * n, 'slope': slope, 'method': 'linear-regression'};
  }

  Map<String, dynamic> guardian(List<String> indicators) {
    final highRisk = indicators.where((i) => RegExp(r'(credential|exfiltration|malware|ransom|deauth|bruteforce)', caseSensitive: false).hasMatch(i)).toList();
    return {'status': highRisk.isEmpty ? 'SAFE' : 'ALERT', 'indicators': highRisk, 'action': highRisk.isEmpty ? 'MONITOR' : 'BLOCK_AND_AUDIT'};
  }

  Map<String, dynamic> empathic(String text) {
    final positive = RegExp(r'\b(good|great|happy|thanks|excellent|ممتاز|سعيد|شكرا|جيد)\b', caseSensitive: false).allMatches(text).length;
    final negative = RegExp(r'\b(bad|sad|angry|afraid|urgent|سيء|حزين|غاضب|خائف|عاجل)\b', caseSensitive: false).allMatches(text).length;
    final label = positive > negative ? 'positive' : negative > positive ? 'negative' : 'neutral';
    return {'status': 'REAL', 'emotion': label, 'confidence': (positive + negative) == 0 ? .5 : (math.max(positive, negative) / (positive + negative))};
  }

  Map<String, dynamic> selfEvolve(List<Map<String, dynamic>> feedback) {
    var trained = 0;
    for (final item in feedback) {
      final input = (item['input'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList();
      final target = item['target'];
      if (input != null && input.length == 4 && target is int && target >= 0 && target < 2) { neural.train(input, target); trained++; }
    }
    return {'status': 'REAL', 'trainedSamples': trained, 'mechanism': 'online-gradient-update'};
  }
}
