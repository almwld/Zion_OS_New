class WiFiNetwork {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final String security;
  final bool isHidden;
  final int channel;

  WiFiNetwork({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.security,
    required this.isHidden,
    required this.channel,
  });

  Map<String, dynamic> toJson() => {
    'ssid': ssid,
    'bssid': bssid,
    'signalStrength': signalStrength,
    'security': security,
    'isHidden': isHidden,
    'channel': channel,
  };
}
