import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/window_manager/models/window_constraints.dart';
void main(){test('constraints clamp minimums to maximums',(){const c=WindowConstraints(minWidth:500,maxWidth:300);expect(c.normalized().minWidth,300);});}