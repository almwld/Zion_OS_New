import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/userland/zion_bootstrap_endpoint.dart';

void main() {
  test('parses a single endpoint manifest and validates asset metadata', () {
    final manifest = ZionBootstrapManifest.fromJson({
      'format': 'zion-bootstrap-endpoint-v1',
      'release': 'abc123',
      'assets': {
        'aarch64': {
          'url': 'https://example.com/zion-userland-aarch64.zip',
          'sha256': 'a' * 64,
          'size': 1024,
        },
      },
    });

    expect(manifest.release, 'abc123');
    expect(manifest.assets['aarch64']?.size, 1024);
    expect(manifest.assets['aarch64']?.sha256, 'a' * 64);
  });

  test('rejects malformed endpoint metadata', () {
    expect(
      () => ZionBootstrapManifest.fromJson({
        'format': 'zion-bootstrap-endpoint-v1',
        'release': 'abc123',
        'assets': {
          'aarch64': {
            'url': 'not-https',
            'sha256': 'bad',
            'size': 0,
          },
        },
      }),
      throwsFormatException,
    );
  });
}
