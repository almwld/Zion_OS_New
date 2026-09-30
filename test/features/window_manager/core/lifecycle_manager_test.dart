import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/core/lifecycle_manager.dart';
import 'package:project_zion/features/window_manager/core/state_machine.dart';
import 'package:project_zion/features/window_manager/models/app_window.dart';
import 'package:project_zion/features/window_manager/models/window_id.dart';
import 'package:project_zion/features/window_manager/models/window_state.dart';
void main(){test('focused window can close',(){final w=AppWindow(id:const WindowId('a'),title:'a',content:const SizedBox(),state:WindowState.focused);expect(WindowLifecycleManager(WindowStateMachine()).transition(w,WindowState.closed),isTrue);});}