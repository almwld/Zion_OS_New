import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_zion/main.dart';
import 'package:project_zion/security/core/security_core.dart';
import 'package:project_zion/services/preferences_service.dart';

void main() {
  test('ZionOSApp is the active application entry point', () {
    final securityCore = SecurityCore();
    final preferencesService = PreferencesService();
    expect(
      ZionOSApp(
        securityCore: securityCore,
        preferencesService: preferencesService,
      ),
      isA<Widget>(),
    );
  });
}
