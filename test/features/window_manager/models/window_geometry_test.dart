import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/window_manager/models/window_geometry.dart';
void main(){test('copyWith preserves unspecified values',(){const g=WindowGeometry(x:10,y:20,width:300,height:200);expect(g.copyWith(width:400),const WindowGeometry(x:10,y:20,width:400,height:200));});}