import 'package:flutter/widgets.dart';
import '../models/app_window.dart';
import '../models/window_constraints.dart';
import '../models/window_event.dart';
import '../models/window_geometry.dart';
import '../models/window_id.dart';
import '../models/window_state.dart';
import 'focus_manager.dart';
import 'lifecycle_manager.dart';
import 'state_machine.dart';
import 'window_registry.dart';
import 'z_order_manager.dart';

class WindowManager extends ChangeNotifier {
  WindowManager({WindowRegistry? registry,WindowFocusManager? focusManager,WindowZOrderManager? zOrderManager,WindowLifecycleManager? lifecycleManager})
      : registry=registry??WindowRegistry(),focusManager=focusManager??WindowFocusManager(),zOrderManager=zOrderManager??WindowZOrderManager(),lifecycleManager=lifecycleManager??WindowLifecycleManager(WindowStateMachine());
  final WindowRegistry registry;
  final WindowFocusManager focusManager;
  final WindowZOrderManager zOrderManager;
  final WindowLifecycleManager lifecycleManager;
  int _sequence=0;
  WindowId? get activeWindowId=>focusManager.activeWindowId;
  List<AppWindow> get windows=>zOrderManager.sort(registry.all.where((w)=>!w.isClosed));
  List<AppWindow> get visibleWindows=>windows.where((w)=>!w.isMinimized).toList(growable:false);
  List<AppWindow> get minimizedWindows=>windows.where((w)=>w.isMinimized).toList(growable:false);

  WindowId open({required String title,required Widget content,double width=600,double height=400,double x=50,double y=50,int workspace=0,String? appKey,WindowConstraints constraints=const WindowConstraints()}){
    final id=WindowId('zion-window-${DateTime.now().microsecondsSinceEpoch}-$_sequence');
    _sequence++;
    final w=AppWindow(id:id,title:title,content:content,geometry:WindowGeometry(x:x,y:y,width:width,height:height),constraints:constraints,workspace:workspace,appKey:appKey);
    registry.add(w);lifecycleManager.transition(w,WindowState.focused);zOrderManager.raise(w);focusManager.focus(w);notifyListeners();_emit(WindowEventType.opened,id);return id;
  }
  bool close(WindowId id){final w=registry.get(id);if(w==null||w.isClosed)return false;lifecycleManager.transition(w,WindowState.closed);focusManager.clearIf(id);_focusTop();notifyListeners();_emit(WindowEventType.closed,id);return true;}
  bool focus(WindowId id){final w=registry.get(id);if(w==null||w.isClosed||w.isMinimized)return false;focusManager.focus(w);zOrderManager.raise(w);notifyListeners();_emit(WindowEventType.focused,id);return true;}
  bool raise(WindowId id){final w=registry.get(id);if(w==null||w.isClosed)return false;zOrderManager.raise(w);if(!w.isMinimized)focusManager.focus(w);notifyListeners();_emit(WindowEventType.raised,id);return true;}
  bool minimize(WindowId id){final w=registry.get(id);if(w==null||w.isClosed)return false;if(!lifecycleManager.transition(w,WindowState.minimized))return false;focusManager.clearIf(id);_focusTop();notifyListeners();_emit(WindowEventType.minimized,id);return true;}
  bool maximize(WindowId id){final w=registry.get(id);if(w==null||w.isClosed)return false;if(!lifecycleManager.transition(w,WindowState.maximized))return false;focusManager.focus(w);zOrderManager.raise(w);notifyListeners();_emit(WindowEventType.maximized,id);return true;}
  bool restore(WindowId id){final w=registry.get(id);if(w==null||w.isClosed)return false;if(!lifecycleManager.transition(w,WindowState.focused))return false;focusManager.focus(w);zOrderManager.raise(w);notifyListeners();return true;}
  bool updateGeometry(WindowId id,WindowGeometry g){final w=registry.get(id);if(w==null||w.isClosed)return false;final c=w.constraints.normalized();w.geometry=g.copyWith(width:g.width.clamp(c.minWidth,c.maxWidth),height:g.height.clamp(c.minHeight,c.maxHeight));notifyListeners();return true;}
  AppWindow? find(WindowId id)=>registry.get(id);
  WindowId? findIdByAppKey(String appKey){for(final w in windows.reversed){if(w.appKey==appKey)return w.id;}return null;}
  void _focusTop(){final c=visibleWindows.isEmpty?null:visibleWindows.last;if(c==null){focusManager.clear();return;}focusManager.focus(c);zOrderManager.raise(c);}
  void _emit(WindowEventType type,WindowId id)=>onEvent?.call(WindowEvent(type,id));
  void Function(WindowEvent event)? onEvent;
}