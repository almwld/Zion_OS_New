import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

class RemoteSessionManager {
  SSHClient? _sshClient;
  SSHSession? _sshSession;
  StreamSubscription<Uint8List>? _stdout;
  StreamSubscription<Uint8List>? _stderr;
  final StreamController<String> _output = StreamController<String>.broadcast();

  Stream<String> get output => _output.stream;
  bool get isConnected => _sshClient != null && !_sshClient!.isClosed;
  String? get remoteVersion => _sshClient?.remoteVersion;

  Future<void> connectSsh({
    required String host,
    required int port,
    required String username,
    required FutureOr<String?> Function() onPasswordRequest,
    required FutureOr<bool> Function(String type, Uint8List fingerprint)
        onVerifyHostKey,
    List<SSHKeyPair>? identities,
  }) async {
    await disconnect();
    final socket = await SSHSocket.connect(
      host,
      port,
      timeout: const Duration(seconds: 15),
    );
    final client = SSHClient(
      socket,
      username: username,
      identities: identities,
      onPasswordRequest: onPasswordRequest,
      onVerifyHostKey: onVerifyHostKey,
      handshakeTimeout: const Duration(seconds: 15),
      authTimeout: const Duration(seconds: 20),
      keepAliveInterval: const Duration(seconds: 10),
    );

    try {
      await client.authenticated;
      _sshClient = client;
    } catch (_) {
      await client.close();
      rethrow;
    }
  }

  Future<void> startShell({int rows = 30, int cols = 100}) async {
    final client = _sshClient;
    if (client == null || client.isClosed) {
      throw StateError('SSH is not connected');
    }

    await _closeShellOnly();
    final session = await client.shell(
      pty: SSHPtyConfig(
        type: 'xterm-256color',
        width: cols,
        height: rows,
      ),
    );
    _sshSession = session;

    _stdout = session.stdout.listen(
      (data) => _output.add(utf8.decode(data, allowMalformed: true)),
      onError: (Object error, StackTrace stack) =>
          _output.add('[ZION][SSH stdout] $error'),
    );
    _stderr = session.stderr.listen(
      (data) => _output.add(utf8.decode(data, allowMalformed: true)),
      onError: (Object error, StackTrace stack) =>
          _output.add('[ZION][SSH stderr] $error'),
    );
  }

  void write(String input) {
    _sshSession?.write(Uint8List.fromList(utf8.encode(input)));
  }

  void resize({required int rows, required int cols}) {
    _sshSession?.resizeTerminal(cols, rows);
  }

  Future<int?> waitForExit({Duration? timeout}) =>
      _sshSession?.waitForExit(timeout: timeout) ?? Future<int?>.value(null);

  Future<void> uploadFile({
    required String localPath,
    required String remotePath,
  }) async {
    final client = _sshClient;
    if (client == null || client.isClosed) {
      throw StateError('SSH is not connected');
    }
    final sftp = await client.sftp();
    final remote = await sftp.open(
      remotePath,
      mode: SftpFileOpenMode.create | SftpFileOpenMode.truncate | SftpFileOpenMode.write,
    );
    try {
      final writer = remote.write(File(localPath).openRead().cast<Uint8List>());
      await writer.done;
    } finally {
      await remote.close();
    }
  }

  Future<void> downloadFile({
    required String remotePath,
    required String localPath,
  }) async {
    final client = _sshClient;
    if (client == null || client.isClosed) {
      throw StateError('SSH is not connected');
    }
    final sftp = await client.sftp();
    final output = File(localPath).openWrite();
    await sftp.download(remotePath, output, closeDestination: true);
  }

  Future<List<SftpName>> listRemoteDirectory(String path) async {
    final client = _sshClient;
    if (client == null || client.isClosed) {
      throw StateError('SSH is not connected');
    }
    final sftp = await client.sftp();
    return sftp.listdir(path);
  }

  Future<void> disconnect() async {
    await _closeShellOnly();
    final client = _sshClient;
    _sshClient = null;
    if (client != null) await client.close();
  }

  Future<void> _closeShellOnly() async {
    await _stdout?.cancel();
    await _stderr?.cancel();
    _stdout = null;
    _stderr = null;
    final session = _sshSession;
    _sshSession = null;
    if (session != null) session.close();
  }

  Future<void> dispose() async {
    await disconnect();
    await _output.close();
  }
}
