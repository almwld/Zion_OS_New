import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:project_zion/features/window_manager/core/window_manager.dart';
import 'package:project_zion/features/window_manager/core/alt_tab_manager.dart';

void main() {
  Widget content()=>const SizedBox();

  test('Alt+Tab cycles from active window through stable MRU order',(){
    final wm=WindowManager();
    final first=wm.open(title:'First',content:content());
    final second=wm.open(title:'Second',content:content());
    final third=wm.open(title:'Third',content:content());
    final altTab=AltTabManager(wm);
    altTab.begin();
    expect(altTab.selectedId,third);
    expect(altTab.cycle(),second);
    expect(altTab.cycle(),first);
    expect(altTab.cycle(),third);
  });

  test('Alt+Shift+Tab cycles backwards',(){
    final wm=WindowManager();
    final first=wm.open(title:'First',content:content());
    final second=wm.open(title:'Second',content:content());
    final third=wm.open(title:'Third',content:content());
    wm.focus(second);
    final altTab=AltTabManager(wm);
    altTab.begin();
    expect(altTab.selectedId,second);
    expect(altTab.cycle(reverse:true),first);
    expect(altTab.cycle(reverse:true),third);
  });

  test('minimized and closed windows are excluded',(){
    final wm=WindowManager();
    final first=wm.open(title:'First',content:content());
    final second=wm.open(title:'Second',content:content());
    final third=wm.open(title:'Third',content:content());
    wm.minimize(second);
    wm.close(third);
    wm.focus(first);
    final altTab=AltTabManager(wm);
    altTab.begin();
    expect(altTab.sessionIds,[first]);
    expect(altTab.isActive,isFalse);
  });
}