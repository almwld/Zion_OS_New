import 'dart:math';

double _tanh(double x) {
  return (exp(x) - exp(-x)) / (exp(x) + exp(-x));
}

class NeuralLayer {
  late List<List<double>> weights;
  late List<double> biases;
  final int inputSize;
  final int outputSize;
  final String activation;

  NeuralLayer({
    required this.inputSize,
    required this.outputSize,
    this.activation = 'relu',
  }) {
    _initializeWeights();
  }

  void _initializeWeights() {
    final rand = Random();
    weights = List.generate(
      outputSize,
      (_) => List.generate(inputSize, (_) => (rand.nextDouble() - 0.5) * 2 * sqrt(2.0 / inputSize)),
    );
    biases = List.generate(outputSize, (_) => 0.0);
  }

  List<double> forward(List<double> input) {
    var output = List.filled(outputSize, 0.0);
    for (var i = 0; i < outputSize; i++) {
      var sum = biases[i];
      for (var j = 0; j < inputSize; j++) {
        sum += weights[i][j] * input[j];
      }
      output[i] = _activate(sum);
    }
    return output;
  }

  double _activate(double x) {
    switch (activation) {
      case 'relu':
        return x > 0 ? x : 0;
      case 'sigmoid':
        return 1 / (1 + exp(-x));
      case 'tanh':
        return _tanh(x);
      default:
        return x;
    }
  }
}

class NeuralNetwork {
  final List<NeuralLayer> layers;

  NeuralNetwork({required List<int> layerSizes}) : layers = [] {
    for (var i = 0; i < layerSizes.length - 1; i++) {
      layers.add(NeuralLayer(
        inputSize: layerSizes[i],
        outputSize: layerSizes[i + 1],
        activation: i == layerSizes.length - 2 ? 'sigmoid' : 'relu',
      ));
    }
  }

  List<double> predict(List<double> input) {
    var current = input;
    for (final layer in layers) {
      current = layer.forward(current);
    }
    return current;
  }
}
