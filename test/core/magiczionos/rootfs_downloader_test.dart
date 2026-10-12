import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/magiczionos/installers/rootfs_downloader.dart';

void main() {
  group('Rootfs checksum parsing', () {
    test('preserves full SHA-512 digests', () {
      final digest = 'b' * 128;
      expect(
        RootfsDownloader.parseChecksumLine(
          '$digest  debian-12-generic-arm64.tar.xz',
          'debian-12-generic-arm64.tar.xz',
        ),
        ('sha512', digest),
      );
    });

    test('recognizes SHA-256 digests', () {
      final digest = 'a' * 64;
      expect(
        RootfsDownloader.parseChecksumLine(
          '$digest *alpine-minirootfs.tar.gz',
          'alpine-minirootfs.tar.gz',
        ),
        ('sha256', digest),
      );
    });

    test('rejects a valid checksum for a different archive', () {
      final digest = 'a' * 64;
      expect(
        RootfsDownloader.parseChecksumLine(
          '$digest  unrelated.tar.gz',
          'requested.tar.gz',
        ),
        isNull,
      );
    });
  });
}
