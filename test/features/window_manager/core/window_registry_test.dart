import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/core/window_registry.dart';
import 'package:project_zion/features/window_manager/models/app_window.dart';
import 'package:project_zion/features/window_manager/models/window_id.dart';
void main(){AppWindow w(String id)=>AppWindow(id:WindowId(id),title:id,content:const SizedBox());test('registry rejects duplicate ids',(){final r=WindowRegistry();expect(r.add(w('a')),isTrue);expect(r.add(w('a')),isFalse);expect(r.length,1);});test('registry remove and clear',(){final r=WindowRegistry()..add(w('a'))..add(w('b'));expect(r.remove(const WindowId('a')),isNotNull);r.clear();expect(r.length,0);});}