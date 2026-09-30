import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/window_manager/models/window_id.dart';
void main(){test('WindowId uses value equality',(){expect(const WindowId('a'),const WindowId('a'));expect(const WindowId('a'),isNot(const WindowId('b')));});}