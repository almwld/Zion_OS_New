import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class DeepPacketInspector {
  RawDatagramSocket? _socket;
  final StreamController<Map<String, dynamic>> _packetController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get packetStream => _packetController.stream;

  /// بدء الالتقاط على منفذ معين
  Future<void> startCapture(int port) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) {
          final packet = _parsePacket(datagram.data);
          if (packet != null) {
            _packetController.add(packet);
          }
        }
      }
    });
  }

  /// إيقاف الالتقاط
  void stopCapture() {
    _socket?.close();
    _packetController.close();
  }

  /// تحليل حزمة
  Map<String, dynamic>? _parsePacket(Uint8List data) {
    if (data.length < 20) return null;

    final packet = <String, dynamic>{};
    final version = (data[0] >> 4) & 0x0F;
    final headerLength = (data[0] & 0x0F) * 4;
    final protocol = data[9];

    // IP Header
    packet['source_ip'] = '${data[12]}.${data[13]}.${data[14]}.${data[15]}';
    packet['dest_ip'] = '${data[16]}.${data[17]}.${data[18]}.${data[19]}';
    packet['length'] = data.length;

    // TCP
    if (protocol == 6 && data.length >= headerLength + 20) {
      final tcpStart = headerLength;
      packet['protocol'] = 'TCP';
      packet['source_port'] = (data[tcpStart] << 8) | data[tcpStart + 1];
      packet['dest_port'] = (data[tcpStart + 2] << 8) | data[tcpStart + 3];

      final flags = data[tcpStart + 13];
      final flagList = <String>[];
      if (flags & 0x02 != 0) flagList.add('SYN');
      if (flags & 0x10 != 0) flagList.add('ACK');
      if (flags & 0x01 != 0) flagList.add('FIN');
      if (flags & 0x04 != 0) flagList.add('RST');
      packet['flags'] = flagList;

      final payloadStart = headerLength + ((data[tcpStart + 12] >> 4) & 0x0F) * 4;
      if (data.length > payloadStart) {
        packet['payload'] = _safeDecode(data.sublist(payloadStart));
      }
    }
    // UDP
    else if (protocol == 17 && data.length >= headerLength + 8) {
      final udpStart = headerLength;
      packet['protocol'] = 'UDP';
      packet['source_port'] = (data[udpStart] << 8) | data[udpStart + 1];
      packet['dest_port'] = (data[udpStart + 2] << 8) | data[udpStart + 3];
    }
    // ICMP
    else if (protocol == 1) {
      packet['protocol'] = 'ICMP';
      packet['type'] = data[headerLength];
      packet['code'] = data[headerLength + 1];
    }

    return packet;
  }

  String _safeDecode(List<int> bytes) {
    try {
      return String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126));
    } catch (_) {
      return '[Binary Data: ${bytes.length} bytes]';
    }
  }
}
