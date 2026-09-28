import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/userland/zion_pkg.dart';
import 'package:project_zion/core/userland/zion_pkg_cli.dart';

class _FakePkg extends ZionPkg {
  _FakePkg() : super();
  @override Future<List<PackageInfo>> getInstalledPackages() async => [PackageInfo(name: 'demo', version: '1.0', installedAt: DateTime.utc(2026, 1, 1), source: 'test')];
  @override Future<PackageStatus> getStatus(String name) async => name == 'demo' ? PackageStatus.installed : PackageStatus.notInstalled;
  @override Future<PkgResult> update() async => const PkgResult.success('updated');
  @override Future<PkgResult> upgrade() async => const PkgResult.success('upgraded');
}

void main() {
  test('zion-pkg CLI exposes package operations', () async {
    final cli = ZionPkgCli(_FakePkg());
    expect(await cli.run(['list']), contains('demo 1.0'));
    expect(await cli.run(['status', 'demo']), 'installed');
    expect(await cli.run(['update']), 'updated');
    expect(await cli.run(['upgrade']), 'upgraded');
    expect(await cli.run(['remove']), contains('Usage'));
  });
  test('unknown command never reports success', () async {
    expect(await ZionPkgCli(_FakePkg()).run(['unknown']), contains('Unknown command'));
  });
}