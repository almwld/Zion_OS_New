import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TelnetSessionManager {
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;
  final StreamController<String> _output = StreamController<String>.broadcast();
  bool _iac = false;
  int? _command;

  Stream<String> get output => _output.stream;
  bool get isConnected => _socket != null;

  Future<void> connect({required String host, int port = 23}) async {
    await disconnect();
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 10),
    );
    _socket = socket;
    socket.setOption(SocketOption.tcpNoDelay, true);
    _subscription = socket.listen(
      _consume,
      onError: (Object error, StackTrace stack) => _output.add('[ZION][TELNET] $error'),
      onDone: () {
        _socket = null;
        _output.add('\r\n[ZION] Telnet session closed.\r\n');
      },
      cancelOnError: false,
    );
  }

  void write(String input) {
    _socket?.add(utf8.encode(input));
  }

  void _consume(List<int> bytes) {
    final text = BytesBuilder();
    for (final byte in bytes) {
      if (_iac) {
        if (byte == 255) {
          text.addByte(255);
          _iac = false;
          _command = null;
          continue;
        }
        final command = _command;
        if (command == null) {
          _command = byte;
          continue;
        }
        _respondToNegotiation(command, byte);
        _iac = false;
        _command = null;
        continue;
      }
      if (byte == 255) {
        _iac = true;
        continue;
      }
      text.addByte(byte);
    }
    if (text.length > 0) {
      _output.add(utf8.decode(text.takeBytes(), allowMalformed: true));
    }
  }

  void _respondToNegotiation(int command, int option) {
    final socket = _socket;
    if (socket == null) return;
    // Refuse option negotiation by default. This keeps the client deterministic
    // and prevents the remote endpoint from enabling unsupported local modes.
    const iac = 255;
    const will = 251;
    const wont = 252;
    const doCommand = 253;
    const dont = 254;
    if (command == will || command == wont) {
      socket.add(<int>[iac, dont, option]);
    } else if (command == doCommand || command == dont) {
      socket.add(<int>[iac, wont, option]);
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    final socket = _socket;
    _socket = null;
    await socket?.close();
  }

  Future<void> dispose() async {
    await disconnect();
    await _output.close();
  }
}
