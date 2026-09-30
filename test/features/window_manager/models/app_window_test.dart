import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/models/app_window.dart';
import 'package:project_zion/features/window_manager/models/window_id.dart';
import 'package:project_zion/features/window_manager/models/window_state.dart';
void main(){test('AppWindow starts created',(){final w=AppWindow(id:const WindowId('1'),title:'Test',content:const SizedBox());expect(w.state,WindowState.created);expect(w.isClosed,isFalse);});}