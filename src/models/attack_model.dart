class AttackModel {
  final String id;
  final String target;
  final String type;
  final bool success;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  AttackModel({
    required this.id,
    required this.target,
    required this.type,
    required this.success,
    required this.timestamp,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'target': target,
    'type': type,
    'success': success,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };

  factory AttackModel.fromJson(Map<String, dynamic> json) => AttackModel(
    id: json['id'],
    target: json['target'],
    type: json['type'],
    success: json['success'],
    timestamp: DateTime.parse(json['timestamp']),
    details: json['details'],
  );
}
