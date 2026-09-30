import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/core/window_manager.dart';
import 'package:project_zion/features/window_manager/operations/close_window.dart';
import 'package:project_zion/features/window_manager/operations/focus_window.dart';
import 'package:project_zion/features/window_manager/operations/open_window.dart';
import 'package:project_zion/features/window_manager/operations/raise_window.dart';
void main(){test('open/focus/raise/close compose',(){final m=WindowManager();final id=OpenWindow(m)(title:'A',content:const SizedBox());expect(m.windows,hasLength(1));expect(FocusWindow(m)(id),isTrue);expect(RaiseWindow(m)(id),isTrue);expect(CloseWindow(m)(id),isTrue);expect(m.windows,isEmpty);});}