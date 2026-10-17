import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class NativePtyCommandResult {
  const NativePtyCommandResult({
    required this.stdout,
    required this.exitCode,
    this.stderr = '',
  });

  final String stdout;
  final String stderr;
  final int exitCode;
  bool get succeeded => exitCode == 0;
}

class NativePtyAdapter {
  NativePtyAdapter() : _channel = const MethodChannel('zion.os/pty');

  static final Stream<dynamic> _sharedEvents =
      const EventChannel('zion.os/pty/events').receiveBroadcastStream();

  final MethodChannel _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<String> _output = StreamController<String>.broadcast();
  final StreamController<List<int>> _rawBytes =
      StreamController<List<int>>.broadcast();
  StreamSubscription<String>? _decoderSubscription;
  int? _handle;
  bool _running = false;
  bool _starting = false;
  final List<Map<dynamic, dynamic>> _pendingEvents = <Map<dynamic, dynamic>>[];

  Stream<String> get output => _output.stream;
  bool get isRunning => _running;
  int? get handle => _handle;

  /// Initialize the embedded Termux bootstrap once before any code creates
  /// an empty PREFIX directory. The native side preserves non-empty prefixes.
  Future<Map<String, dynamic>?> ensureBootstrap() async {
    try {
      return await _channel.invokeMapMethod<String, dynamic>('ensureBootstrap');
    } on PlatformException catch (error) {
      return <String, dynamic>{
        'success': false,
        'status': 'platform-error',
        'message': error.message ?? error.code,
      };
    } on MissingPluginException {
      return <String, dynamic>{
        'success': false,
        'status': 'channel-unavailable',
        'message': 'Native Termux bootstrap channel is unavailable.',
      };
    }
  }

  /// Install/validate the APK-bundled ARM64 PRoot executable and loader
  /// into Zion's private prefix before a Kali preflight checks those paths.
  Future<bool> ensureProotRuntime() async {
    try {
      return await _channel.invokeMethod<bool>('ensureProot') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Inspect the APK's actual native-library directory and local Userland paths.
  /// This is metadata-only: it never loads or executes the reported binaries.
  Future<Map<String, dynamic>?> inspectRuntime() async {
    try {
      return await _channel.invokeMapMethod<String, dynamic>('inspectRuntime');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  void _handleEvent(Map<dynamic, dynamic> value) {
    final id = value['sessionId'];
    if (id != _handle) return;
    if (value['closed'] == true) {
      _running = false;
      _handle = null;
      return;
    }
    final data = value['data'];
    if (data is Uint8List) {
      _rawBytes.add(data);
    } else if (data is List<int>) {
      _rawBytes.add(data);
    }
  }

  /// Request Magisk/su authorization explicitly, then start an interactive
  /// root shell inside the existing native PTY. No SELinux changes are made.
  Future<Map<String, dynamic>?> requestRootAccess() async {
    try {
      return await const MethodChannel('zion.os/root')
          .invokeMapMethod<String, dynamic>('request');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Start a root shell only after the user-approved su probe succeeds.
  /// The native layer independently allowlists the shell path.
  Future<bool> startAsRoot({
    int rows = 24,
    int cols = 80,
    String shell = '/data/data/com.zion.os/files/usr/bin/bash',
  }) async {
    final status = await requestRootAccess();
    if (status?['granted'] != true) {
      _output.add('[Zion Root] Root access was not granted; no root shell was started.');
      return false;
    }
    return start(rows: rows, cols: cols, shell: 'root:$shell');
  }

  Future<bool> start({int rows = 24, int cols = 80, String? shell}) async {
    if (_running) return true;
    if (_starting) return false;
    // Claim startup before awaiting platform availability so simultaneous
    // callers cannot race through the same asynchronous check.
    _starting = true;
    _pendingEvents.clear();
    if (!await isAvailable()) {
      _starting = false;
      _pendingEvents.clear();
      return false;
    }

    _decoderSubscription ??= _rawBytes.stream
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(_output.add);

    _subscription ??= _sharedEvents.listen(
      (dynamic value) {
        if (value is! Map) return;
        // The native reader may emit the shell prompt before the start method
        // result reaches Dart and assigns _handle. Buffer a small bounded number
        // of early events, then replay only events for the newly assigned handle.
        if (_starting) {
          if (_pendingEvents.length < 128) {
            _pendingEvents.add(Map<dynamic, dynamic>.from(value));
          }
          return;
        }
        _handleEvent(value);
      },
      onError: (Object error, StackTrace stack) {
        _output.add('[ZION] PTY event error: $error');
      },
    );

    try {
      final handle = await _channel.invokeMethod<int>(
        'start',
        <String, Object>{
          'rows': rows,
          'cols': cols,
          if (shell != null && shell.trim().isNotEmpty) 'shell': shell.trim(),
        },
      );
      if (handle == null || handle <= 0) {
        _starting = false;
        _pendingEvents.clear();
        await stop();
        return false;
      }
      _handle = handle;
      _running = true;
      _starting = false;
      final earlyEvents = List<Map<dynamic, dynamic>>.from(_pendingEvents);
      _pendingEvents.clear();
      for (final event in earlyEvents) {
        _handleEvent(event);
      }
      return true;
    } on PlatformException {
      _starting = false;
      _pendingEvents.clear();
      await stop();
      return false;
    } on MissingPluginException {
      _starting = false;
      _pendingEvents.clear();
      await stop();
      return false;
    } catch (_) {
      _starting = false;
      _pendingEvents.clear();
      await stop();
      return false;
    }
  }

  /// Execute a bounded command inside a native PTY session. This keeps
  /// terminal process creation on the JNI side rather than Dart Process.start.
  /// It does not bypass Android SELinux policy: binaries that Android forbids
  /// the app domain to execute can still fail inside the native child.
  Future<NativePtyCommandResult> runCommand({
    required String command,
    required String shell,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final session = NativePtyAdapter();
    final output = StringBuffer();
    final token = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final markerPrefix = '__ZION_DONE_${token}_';
    final marker = RegExp('__ZION_DONE_${token}_(-?\\d+)__');
    final completed = Completer<int>();
    StreamSubscription<String>? outputSubscription;

    outputSubscription = session.output.listen((chunk) {
      output.write(chunk);
      if (!completed.isCompleted) {
        final match = marker.firstMatch(output.toString());
        if (match != null) {
          completed.complete(int.tryParse(match.group(1) ?? '') ?? 126);
        }
      }
    });

    try {
      final started = await session.start(rows: 24, cols: 100, shell: shell);
      if (!started) {
        return const NativePtyCommandResult(
          stdout: '',
          stderr: 'Native PTY could not start the requested shell.',
          exitCode: 126,
        );
      }

      final script =
          '${command}\n__zion_status=\$?; printf \'\\n${markerPrefix}%s__\\n\' "\$__zion_status"\n';
      await session.write(script);

      final exitCode = await completed.future.timeout(timeout);
      final raw = output.toString();
      final match = marker.firstMatch(raw);
      final cleanOutput = match == null
          ? raw
          : raw.substring(0, match.start);
      return NativePtyCommandResult(
        stdout: cleanOutput,
        stderr: '',
        exitCode: exitCode,
      );
    } on TimeoutException {
      return NativePtyCommandResult(
        stdout: output.toString(),
        stderr: 'Command timed out after ${timeout.inSeconds}s.',
        exitCode: 124,
      );
    } catch (error) {
      return NativePtyCommandResult(
        stdout: output.toString(),
        stderr: 'Native PTY command failed: $error',
        exitCode: 126,
      );
    } finally {
      await outputSubscription.cancel();
      await session.dispose();
    }
  }

  Future<void> write(String input) =>
      writeBytes(Uint8List.fromList(utf8.encode(input)));

  Future<void> writeBytes(Uint8List bytes) async {
    final handle = _handle;
    if (!_running || handle == null || bytes.isEmpty) return;
    try {
      final written = await _channel.invokeMethod<int>('write', <String, Object>{
        'handle': handle,
        'input': bytes,
      });
      if (written != bytes.length) {
        // Never resend a partial write: that could duplicate characters already
        // accepted by the PTY. Surface the exact count so Enter/input failures
        // are visible instead of silently dropping data.
        _output.add(
          '\r\n[PTY] Write incomplete: sent ${written ?? 0}/${bytes.length} bytes; '
          'input was not resent.\r\n',
        );
      }
    } on PlatformException catch (error) {
      _output.add('\r\n[PTY] Write failed: ${error.message ?? error.code}.\r\n');
      _running = false;
    } on MissingPluginException {
      _output.add('\r\n[PTY] Write failed: native PTY channel unavailable.\r\n');
      _running = false;
    }
  }

  Future<bool> resize({required int rows, required int cols}) async {
    final handle = _handle;
    if (!_running || handle == null) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'resize',
            <String, Object>{'handle': handle, 'rows': rows, 'cols': cols},
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> stop() async {
    final handle = _handle;
    _handle = null;
    _running = false;
    if (handle != null) {
      try {
        await _channel.invokeMethod<void>(
          'stop',
          <String, Object>{'handle': handle},
        );
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await stop();
    await _subscription?.cancel();
    _subscription = null;
    await _decoderSubscription?.cancel();
    _decoderSubscription = null;
    await _rawBytes.close();
    await _output.close();
  }
}
