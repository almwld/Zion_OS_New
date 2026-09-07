import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_zion/main.dart';

void main() {
  test('ZionOSApp is the active application entry point', () {
    expect(const ZionOSApp(), isA<Widget>());
  });
}
