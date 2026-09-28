import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/userland/zion_pkg.dart';
import '../../../lib/core/userland/zion_repository.dart';

ZionRepository _repo() => ZionRepository(
  assetLoader: (_) async => '{"format":"zion-repository-v1","packages":[{"name":"hello","version":"1.0","architecture":"arm64","path":"hello/hello_1.0_arm64.deb","sha256":"22861314d69bc0afd79a9c89625005022b5f95415b3324ee5d9d01381bfe57f1","size":816}]}',
);

void main() {
  test('repository index contains hello with SHA-256', () async {
    final info = await _repo().search('hello');
    expect(info, isNotNull);
    expect(info!.version, '1.0');
    expect(info.architecture, 'arm64');
    expect(info.sha256, hasLength(64));
  });

  test('invalid package names are rejected before repository access', () async {
    final result = await ZionPkg(repository: _repo()).installByName('../hello');
    expect(result.success, isFalse);
  });

  test('missing local deb is rejected', () async {
    final result = await ZionPkg().installFromFile(Directory.systemTemp.path + '/missing.deb');
    expect(result.success, isFalse);
  });

  test('tampered sidecar SHA is rejected before dpkg', () async {
    final file = File(Directory.systemTemp.path + '/zion-tampered.deb');
    await file.writeAsBytes(<int>[1, 2, 3, 4]);
    final sidecar = File(file.path + '.sha256');
    await sidecar.writeAsString('0000000000000000000000000000000000000000000000000000000000000000  zion-tampered.deb');
    final result = await ZionPkg().installFromFile(file.path);
    expect(result.success, isFalse);
    expect(result.error, 'SHA-256 mismatch');
    await file.delete();
    await sidecar.delete();
  });
}
