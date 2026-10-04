import 'dart:io';
class BootstrapLoader { String get architecture=>Platform.version.contains('arm64')?'aarch64':'unknown'; Future<bool> available(String path)=>Directory(path).exists(); }