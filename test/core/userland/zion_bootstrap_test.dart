import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/userland/zion_bootstrap.dart';
void main(){test('rejects archive without manifest',()async{final a=Archive()..addFile(ArchiveFile('usr/bin/readme',4,[1,2,3,4]));final f=File(Directory.systemTemp.path+'/zion-invalid.zip');await f.writeAsBytes(ZipEncoder().encode(a)!);final r=await ZionBootstrap().installFromArchive(f.path);expect(r.success,isFalse);expect(r.error,contains('zion-manifest.json'));await f.delete();});test('isInstalled requires real marker and zion-pkg',()async{expect(await ZionBootstrap.isInstalled(),isFalse);});}
