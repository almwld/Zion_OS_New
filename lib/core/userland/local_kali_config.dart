import 'dart:io';

class ZionLocalKaliConfig {
  const ZionLocalKaliConfig._();

  static const expectedFilename =
      'kali-nethunter-rootfs-minimal-arm64.tar.xz';
  static const expectedSha256 =
      'd6403a5da175df325611d23af4b92330856059c45454eced7f4cdf3ca6df2e4e';
  static const expectedSize = 137313840;
  static const rootfsName = 'kali-arm64';

  static const searchPaths = <String>[
    '/sdcard/Download',
    '/storage/emulated/0/Download',
    '/sdcard/Downloads',
    '/storage/emulated/0/Downloads',
  ];

  static Directory appRoot(Directory filesDir) =>
      Directory('${filesDir.path}/zion');
  static Directory downloads(Directory filesDir) =>
      Directory('${appRoot(filesDir).path}/downloads');
  static Directory userland(Directory filesDir) =>
      Directory('${appRoot(filesDir).path}/userland');
  static Directory rootfs(Directory filesDir) =>
      Directory('${filesDir.path}/home/.zion/dists/kali/rootfs');
  static Directory logs(Directory filesDir) =>
      Directory('${appRoot(filesDir).path}/logs');
  static File stateFile(Directory filesDir) =>
      File('${appRoot(filesDir).path}/state.json');
}
