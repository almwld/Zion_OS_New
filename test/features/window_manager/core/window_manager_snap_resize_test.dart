import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/core/window_manager.dart';
import 'package:project_zion/features/window_manager/models/window_geometry.dart';
import 'package:project_zion/features/window_manager/models/window_resize_edge.dart';
import 'package:project_zion/features/window_manager/models/window_snap.dart';

void main() {
  Widget content() => const SizedBox();
  test('resize respects minimum constraints', () {
    final wm=WindowManager();
    final id=wm.open(title:'Test',content:content(),width:300,height:240);
    expect(wm.resize(id,WindowResizeEdge.left,500,0),isTrue);
    expect(wm.geometryOf(id)!.width,greaterThanOrEqualTo(240));
  });
  test('resize from left keeps right edge stable', () {
    final wm=WindowManager();
    final id=wm.open(title:'Test',content:content(),x:20,y:30,width:400,height:300);
    expect(wm.resize(id,WindowResizeEdge.left,50,0),isTrue);
    final g=wm.geometryOf(id)!;
    expect(g.x,70);
    expect(g.width,350);
  });
  test('snap left and right use viewport halves', () {
    final wm=WindowManager();
    final id=wm.open(title:'Test',content:content());
    expect(wm.snap(id,WindowSnap.left,viewportWidth:1000,viewportHeight:800,topInset:40),isTrue);
    expect(wm.geometryOf(id),const WindowGeometry(x:0,y:40,width:500,height:760));
    expect(wm.snap(id,WindowSnap.right,viewportWidth:1000,viewportHeight:800,topInset:40),isTrue);
    expect(wm.geometryOf(id)!.x,500);
  });
  test('maximize changes lifecycle state', () {
    final wm=WindowManager();
    final id=wm.open(title:'Test',content:content());
    expect(wm.snap(id,WindowSnap.maximize,viewportWidth:1000,viewportHeight:800),isTrue);
    expect(wm.find(id)!.isMaximized,isTrue);
  });
}