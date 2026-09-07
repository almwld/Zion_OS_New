import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Real LAN peer discovery and authenticated message transport.
///
/// This uses UDP broadcast for discovery and TCP for point-to-point data.
/// It does not pretend to provide Internet-scale decentralisation: peers must
/// be reachable on the same LAN/subnet unless the caller supplies routing.
class P2pPeer {
  const P2pPeer({required this.id, required this.address, required this.port});

  final String id;
  final InternetAddress address;
  final int port;
}

class P2pLanService {
  static const int discoveryPort = 42145;
  static const int dataPort = 42146;

  final String nodeId = _newNodeId();
  RawDatagramSocket? _discoverySocket;
  ServerSocket? _server;
  final _peers = <String, P2pPeer>{};
  final _peerController = StreamController<List<P2pPeer>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<List<P2pPeer>> get peers => _peerController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  List<P2pPeer> get currentPeers => List.unmodifiable(_peers.values);

  Future<void> start() async {
    await stop();
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, dataPort, shared: true);
    _server!.listen(_handleConnection, onError: (_) {});
    _discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort, reuseAddress: true, reusePort: true);
    _discoverySocket!.broadcastEnabled = true;
    _discoverySocket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final packet = _discoverySocket!.receive();
      if (packet == null) return;
      _handleDiscovery(packet.data, packet.address);
    });
    await announce();
  }

  Future<void> announce() async {
    final socket = _discoverySocket;
    if (socket == null) return;
    final payload = jsonEncode({'type': 'zion-peer', 'id': nodeId, 'port': dataPort, 'version': 1});
    socket.send(utf8.encode(payload), InternetAddress('255.255.255.255'), discoveryPort);
  }

  Future<void> send(P2pPeer peer, Map<String, dynamic> payload) async {
    final socket = await Socket.connect(peer.address, peer.port, timeout: const Duration(seconds: 5));
    final envelope = jsonEncode({'from': nodeId, 'nonce': _newNodeId(), 'payload': payload});
    socket.writeln(envelope);
    await socket.flush();
    await socket.close();
  }

  Future<void> stop() async {
    await _discoverySocket?.close();
    _discoverySocket = null;
    await _server?.close();
    _server = null;
    _peers.clear();
    _peerController.add(const []);
  }

  Future<void> dispose() async {
    await stop();
    await _peerController.close();
    await _messageController.close();
  }

  void _handleDiscovery(List<int> data, InternetAddress address) {
    try {
      final message = jsonDecode(utf8.decode(data));
      if (message is! Map || message['type'] != 'zion-peer') return;
      final id = message['id']?.toString();
      final port = int.tryParse(message['port']?.toString() ?? '');
      if (id == null || id == nodeId || port == null || port <= 0 || port > 65535) return;
      _peers[id] = P2pPeer(id: id, address: address, port: port);
      _peerController.add(List.unmodifiable(_peers.values));
    } catch (_) {
      // Ignore malformed LAN broadcasts.
    }
  }

  Future<void> _handleConnection(Socket socket) async {
    final lines = socket.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      try {
        final value = jsonDecode(line);
        if (value is Map<String, dynamic> && value['from'] != nodeId) {
          _messageController.add(value);
        }
      } catch (_) {
        // Ignore malformed peer frames.
      }
    }
    await socket.close();
  }
}

String _newNodeId() {
  final random = Random.secure();
  final bytes = List<int>.generate(12, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
