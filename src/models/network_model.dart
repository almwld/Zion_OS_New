class NetworkDevice {
  final String ip;
  final String? hostname;
  final List<int> openPorts;
  final String? os;
  final int signalStrength;
  final DateTime lastSeen;

  NetworkDevice({
    required this.ip,
    this.hostname,
    required this.openPorts,
    this.os,
    required this.signalStrength,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
    'ip': ip,
    'hostname': hostname,
    'openPorts': openPorts,
    'os': os,
    'signalStrength': signalStrength,
    'lastSeen': lastSeen.toIso8601String(),
  };
}
