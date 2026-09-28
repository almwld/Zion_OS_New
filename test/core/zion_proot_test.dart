import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/userland/zion_proot.dart';

void main() {
  const proot = ZionProot();
  test('supports the planned Zion distributions', () {
    expect(proot.validateDistro('ubuntu'), 'ubuntu');
    expect(proot.validateDistro('Debian'), 'debian');
    expect(proot.validateDistro('kali'), 'kali');
    expect(proot.validateDistro('arch'), 'arch');
    expect(proot.validateDistro('alpine'), 'alpine');
    expect(proot.validateDistro('fedora'), isNull);
  });
  test('rootfs paths stay inside the Zion distro root', () {
    expect(proot.rootfsPath(ZionDistro.ubuntu), '/data/data/com.zion.os/files/home/.zion/dists/ubuntu/rootfs');
  });
}