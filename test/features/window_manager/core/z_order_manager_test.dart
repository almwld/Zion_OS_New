import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/core/z_order_manager.dart';
import 'package:project_zion/features/window_manager/models/app_window.dart';
import 'package:project_zion/features/window_manager/models/window_id.dart';
void main(){test('raise establishes ordered z indices',(){final z=WindowZOrderManager();final a=AppWindow(id:const WindowId('a'),title:'a',content:const SizedBox());final b=AppWindow(id:const WindowId('b'),title:'b',content:const SizedBox());z.raise(a);z.raise(b);expect(z.sort([b,a]).map((w)=>w.id.value),['a','b']);});}