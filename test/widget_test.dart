import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_zion/main.dart';
import 'package:project_zion/security/core/security_core.dart';

void main() {
  test('ZionOSApp is the active application entry point', () {
    expect(const ZionOSApp(securityCore: SecurityCore()), isA<Widget>());
  });
}
