import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/window_manager/core/state_machine.dart';
import 'package:project_zion/features/window_manager/models/window_state.dart';
void main(){test('closed is terminal',(){final m=WindowStateMachine();expect(m.canTransition(WindowState.closed,WindowState.focused),isFalse);expect(m.canTransition(WindowState.focused,WindowState.closed),isTrue);});}