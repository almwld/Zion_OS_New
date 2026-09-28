class SeismicControl {
  bool _isActive = false;
  final List<Map<String, dynamic>> _operations = [];
  final List<Map<String, dynamic>> _detectedFaults = [];

  bool get isActive => _isActive;
  List<Map<String, dynamic>> get operations => List.unmodifiable(_operations);
  List<Map<String, dynamic>> get detectedFaults => List.unmodifiable(_detectedFaults);

  /// Real seismic monitoring requires an external sensor/data provider.
  /// Never fabricate fault stress, depth, or criticality.
  Future<void> scanFaultLines() async {
    _detectedFaults.clear();
  }

  Future<Map<String, dynamic>> induceEarthquake(
    String faultName,
    double magnitude,
  ) async {
    _isActive = false;
    return {
      'fault': faultName,
      'magnitude': magnitude,
      'status': 'blocked',
      'reason': 'التسبب بالزلازل غير مدعوم وممنوع.',
    };
  }
}
