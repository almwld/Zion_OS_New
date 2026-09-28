import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/magiczionos/installers/rootfs_downloader.dart';

void main() {
  test('rootfs catalog contains the four supported distros', () {
    expect(ZionRootfsDistro.values.map((e) => e.name), containsAll(['ubuntu', 'debian', 'alpine', 'kali']));
  });
}