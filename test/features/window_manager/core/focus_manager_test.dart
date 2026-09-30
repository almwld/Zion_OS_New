import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/core/focus_manager.dart';
import 'package:project_zion/features/window_manager/models/app_window.dart';
import 'package:project_zion/features/window_manager/models/window_id.dart';
import 'package:project_zion/features/window_manager/models/window_state.dart';
void main(){AppWindow w(String id,[WindowState s=WindowState.created])=>AppWindow(id:WindowId(id),title:id,content:const SizedBox(),state:s);test('closed/minimized cannot focus',(){final f=WindowFocusManager();expect(f.focus(w('c',WindowState.closed)),isFalse);expect(f.focus(w('m',WindowState.minimized)),isFalse);});test('visible window becomes active',(){final f=WindowFocusManager();final a=w('a');expect(f.focus(a),isTrue);expect(f.activeWindowId,const WindowId('a'));expect(a.state,WindowState.focused);});}