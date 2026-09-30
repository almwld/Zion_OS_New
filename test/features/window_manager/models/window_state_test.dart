import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/window_manager/models/window_state.dart';
void main(){test('lifecycle states are explicit',(){expect(WindowState.values,containsAll([WindowState.created,WindowState.focused,WindowState.minimized,WindowState.maximized,WindowState.closed]));});}