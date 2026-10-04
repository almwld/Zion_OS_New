import 'dart:io';
class BootstrapLoader {
  String get architecture {
    final a=Platform.environment['PROCESSOR_ARCHITECTURE']?.toLowerCase();
    if(a?.contains('aarch64')==true||a?.contains('arm64')==true)return 'aarch64';
    if(a?.contains('arm')==true)return 'arm';
    if(a?.contains('x86_64')==true||a?.contains('amd64')==true)return 'x86_64';
    if(a?.contains('x86')==true)return 'x86';
    return Platform.operatingSystem=='android'?'aarch64':'unknown';
  }
  Future<bool> available(String path) async=>await Directory(path).exists();
  Future<Directory> prepare(String root) async {final d=Directory(root);await d.create(recursive:true);return d;}
}
